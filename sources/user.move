module suipass::user {
    use std::vector;
    use std::string::{Self, String};

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self, VecMap};

    use suipass::approval::{Self, Approval};

    // friend suipass::suipass;

    #[test_only]
    use sui::test_scenario;
    #[test_only]
    use sui::test_utils::assert_eq;

    // Errors

    //======================================================================
    // Module Structs
    //======================================================================

    public struct User has key {
        id: UID,
        info: String,
        approvals: VecMap<ID, Approval>,
    }

    //======================================================================
    // Event Structs
    //======================================================================

    // struct UserRegistered has copy, drop {
    //     user_id: ID,
    // }

    //======================================================================
    // Functions
    //======================================================================

    public fun new(info: vector<u8>, ctx: &mut TxContext) {
        let user = User {
            id: object::new(ctx),
            info: string::utf8(info),
            approvals: vec_map::empty()
        };
        transfer::transfer(user, tx_context::sender(ctx))
    }

    public fun update_info(
        user: &mut User, 
        info: vector<u8>,
    ) {
        user.info = string::utf8(info)
    }

    public fun merge(user: &mut User, approval: Approval) {
        vec_map::insert(&mut user.approvals, approval::provider_id(&approval), approval)
    }

    //======================================================================
    // Accessors
    //======================================================================

    public fun levels(user: &User): VecMap<ID, u16> {
        let ids = vec_map::keys(&user.approvals);
        let mut len = vector::length(&ids);
        std::debug::print(&ids);

        let mut result: VecMap<ID, u16> = vec_map::empty();
        loop {
            if (len == 0) break;
            len = len - 1;

            let id = vector::borrow(&ids, len);
            let approval = vec_map::get(&user.approvals, id);

            vec_map::insert(&mut result, *id, approval::level(approval));
        };
        result
    }

    //======================================================================
    // Tests
    //======================================================================

    #[test_only]
    public fun get_user_info(user: &User): String {
        user.info
    }
}
