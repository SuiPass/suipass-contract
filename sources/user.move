module suipass::user {
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};

    use std::vector;

    use sui::vec_map::{Self, VecMap};

    use suipass::approval::{Self, Approval};

    friend suipass::suipass;

    // Errors
    const EInsufficientBalance: u64 = 0;
    const ESameScore: u64 = 1;
    const ERequestRejected: u64 = 2;
    const EInvalidRequest: u64 = 3;

    struct User has key {
        id: UID,
        info: String,
        approvals: VecMap<ID, Approval>,
    }

    public entry fun new(info: vector<u8>, ctx: &mut TxContext) {
        let user = User {
            id: object::new(ctx),
            info: string::utf8(info),
            approvals: vec_map::empty()
        };
        transfer::transfer(user, tx_context::sender(ctx))
    }

    public entry fun update_info(
        user: &mut User, 
        info: vector<u8>,
    ) {
        user.info = string::utf8(info)
    }

    public entry fun merge(user: &mut User, approval: Approval) {
        vec_map::insert(&mut user.approvals, approval::provider_id(&approval), approval)
    }

    public fun get_providers(user: &User): vector<ID> {
        vec_map::keys(&user.approvals)
    }

    public fun levels(user: &User): VecMap<ID, u16> {
        let ids = vec_map::keys(&user.approvals);
        let len = vector::length(&ids) - 1;

        let result: VecMap<ID, u16> = vec_map::empty();
        loop {
            let id = vector::borrow(&ids, len);
            let approval = vec_map::get(&user.approvals, id);

            vec_map::insert(&mut result, *id, approval::level(approval));

            len = len - 1;
            if (len == 0) {
                break
            }
        };
        result
    }
}
