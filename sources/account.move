module suipass::account {
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};

    use std::vector;

    use sui::vec_map::{Self, VecMap};

    friend suipass::suipass;

    // Errors
    const EInsufficientBalance: u64 = 0;
    const ESameScore: u64 = 1;
    const ERequestRejected: u64 = 2;
    const EInvalidRequest: u64 = 3;

    struct Account has key {
        id: UID,
        info: String,
        approvals: VecMap<ID, Approval>,
    }

    struct Approval has key, store {
        id: UID,
        provider: ID,
        level: u16,
        issued_date: u64,
        expiration_date: u64,
    }

    public entry fun new(info: vector<u8>, ctx: &mut TxContext) {
        let account = Account {
            id: object::new(ctx),
            info: string::utf8(info),
            approvals: vec_map::empty()
        };
        transfer::transfer(account, tx_context::sender(ctx))
    }

    public fun update_info(
        account: &mut Account, 
        info: vector<u8>,
    ) {
        account.info = string::utf8(info)
    }
}
