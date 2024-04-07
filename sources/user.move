module suipass::user {
    use std::vector;
    use std::string::{Self, String};

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self, VecMap};

    use suipass::approval::{Self, Approval};

    friend suipass::suipass;

    #[test_only]
    use sui::test_scenario;
    #[test_only]
    use sui::test_utils::assert_eq;

    // Errors

    //======================================================================
    // Module Structs
    //======================================================================

    struct User has key {
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
        let len = vector::length(&ids);
        std::debug::print(&ids);

        let result: VecMap<ID, u16> = vec_map::empty();
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

    #[test]
    public fun test_create_user_success_create_user() {
        let shop_owner = @0xa;

        let scenario_val = test_scenario::begin(shop_owner);
        let scenario = &mut scenario_val;

        {
            new(b"name: test", test_scenario::ctx(scenario));
        };
        let tx = test_scenario::next_tx(scenario, shop_owner);

        {
            let user = test_scenario::take_from_sender<User>(scenario);

            assert_eq(user.info, string::utf8(b"name: test"));

            test_scenario::return_to_sender(scenario, user);
        };
        let tx = test_scenario::end(scenario_val);
    }

    #[test]
    public fun test_get_levels_success() {
        let shop_owner = @0xa;

        let scenario_val = test_scenario::begin(shop_owner);
        let scenario = &mut scenario_val;

        {
            new(b"name: test", test_scenario::ctx(scenario));
        };
        let tx = test_scenario::next_tx(scenario, shop_owner);

        {
            let user = test_scenario::take_from_sender<User>(scenario);

            assert_eq(user.info, string::utf8(b"name: test"));

            let levels = levels(&user);

            std::debug::print(&levels);

            test_scenario::return_to_sender(scenario, user);

        };

        let tx = test_scenario::end(scenario_val);
    }

    // #[test]
    // public fun test_get_levels_success_with_some_approvals() {
    //     let shop_owner = @0xa;
    //
    //     let scenario_val = test_scenario::begin(shop_owner);
    //     let scenario = &mut scenario_val;
    //
    //     {
    //         new(b"name: test", test_scenario::ctx(scenario));
    //     };
    //     let tx = test_scenario::next_tx(scenario, shop_owner);
    //
    //     {
    //         let user = test_scenario::take_from_sender<User>(scenario);
    //
    //         assert_eq(user.info, string::utf8(b"name: test"));
    //
    //         let levels = levels(&user);
    //
    //         test_scenario::return_to_sender(scenario, user);
    //     };
    //
    //     let tx = test_scenario::next_tx(scenario, shop_owner);
    //
    //     {
    //         let user = test_scenario::take_from_sender<User>(scenario);
    //
    //         let approval = approval::new(object::uid_to_inner(&user.id), 2, b"hello evidence", 1000, test_scenario::ctx(scenario));
    //
    //         merge(&mut user, approval);
    //
    //         std::debug::print(&user);
    //
    //         let levels = levels(&user);
    //
    //         std::debug::print(&levels);
    //
    //         test_scenario::return_to_sender(scenario, user);
    //     };
    //
    //     let tx = test_scenario::end(scenario_val);
    // }
}
