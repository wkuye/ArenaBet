// sources/arena_escrow.move
module arena_escrow::arena_escrow {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};

    const ENotPlayer: u64 = 0;
    const EAlreadyDeposited: u64 = 1;
    const ENotActive: u64 = 2;
    const ENotAdmin: u64 = 3;
    const EExpired: u64 = 4;
    const ENotExpired: u64 = 5;
    const EWrongAmount: u64 = 6;

    const STATUS_PENDING: u8 = 0;
    const STATUS_ACTIVE: u8 = 1;
    const STATUS_RESOLVED: u8 = 2;
    const STATUS_CANCELLED: u8 = 3;

    public struct Bet has key {
        id: UID,
        room_id: vector<u8>,         // your Firestore roomId
        player1: address,
        player2: address,
        admin: address,              // your backend wallet
        amount: u64,                 // per player in MIST
        player1_coin: Option<Coin<SUI>>,
        player2_coin: Option<Coin<SUI>>,
        status: u8,
        expires_at: u64,
        platform_fee_bps: u64,       // 200 = 2%
    }

    // ── Create ──
    // your backend calls this when room is created
    public fun create_bet(
        room_id: vector<u8>,
        player1: address,
        player2: address,
        admin: address,
        amount: u64,
        expires_at: u64,
        platform_fee_bps: u64,
        ctx: &mut TxContext,
    ) {
        let bet = Bet {
            id: object::new(ctx),
            room_id,
            player1,
            player2,
            admin,
            amount,
            player1_coin: option::none(),
            player2_coin: option::none(),
            status: STATUS_PENDING,
            expires_at,
            platform_fee_bps,
        };
        transfer::share_object(bet);
    }

    // ── Deposit ──
    // each player calls this to lock their SUI
    public fun deposit(
        bet: &mut Bet,
        coin: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        let now = clock::timestamp_ms(clock);

        assert!(now < bet.expires_at, EExpired);
        assert!(bet.status != STATUS_RESOLVED, ENotActive);
        assert!(coin::value(&coin) == bet.amount, EWrongAmount);

        if (sender == bet.player1) {
            assert!(option::is_none(&bet.player1_coin), EAlreadyDeposited);
            option::fill(&mut bet.player1_coin, coin);
        } else if (sender == bet.player2) {
            assert!(option::is_none(&bet.player2_coin), EAlreadyDeposited);
            option::fill(&mut bet.player2_coin, coin);
        } else {
            abort ENotPlayer
        };

        if (option::is_some(&bet.player1_coin) && option::is_some(&bet.player2_coin)) {
            bet.status = STATUS_ACTIVE;
        };
    }

    // ── Resolve ──
    // your backend calls this after checkWinner
    public fun resolve(
        bet: &mut Bet,
        winner: address,
        fee_recipient: address,
        ctx: &mut TxContext,
    ) {
        assert!(tx_context::sender(ctx) == bet.admin, ENotAdmin);
        assert!(bet.status == STATUS_ACTIVE, ENotActive);

        bet.status = STATUS_RESOLVED;

        let p1_coin = option::extract(&mut bet.player1_coin);
        let p2_coin = option::extract(&mut bet.player2_coin);

        coin::join(&mut p1_coin, p2_coin);
        let total = coin::value(&p1_coin);

        let fee = (total * bet.platform_fee_bps) / 10000;
        let winnings = total - fee;

        let fee_coin = coin::split(&mut p1_coin, fee, ctx);
        transfer::public_transfer(fee_coin, fee_recipient);

        let win_coin = coin::split(&mut p1_coin, winnings, ctx);
        transfer::public_transfer(win_coin, winner);

        coin::destroy_zero(p1_coin);
    }

    // ── Cancel ──
    // if bet expires before both deposit
    public fun cancel(
        bet: &mut Bet,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let now = clock::timestamp_ms(clock);
        assert!(now >= bet.expires_at, ENotExpired);
        assert!(bet.status != STATUS_RESOLVED, ENotActive);

        bet.status = STATUS_CANCELLED;

        if (option::is_some(&bet.player1_coin)) {
            let coin = option::extract(&mut bet.player1_coin);
            transfer::public_transfer(coin, bet.player1);
        };

        if (option::is_some(&bet.player2_coin)) {
            let coin = option::extract(&mut bet.player2_coin);
            transfer::public_transfer(coin, bet.player2);
        };
    }
}