
#[test_only]
module suipass::user_test {
    use sui::test_scenario::{Self as test, Scenario, next_tx, ctx, end, TransactionEffects};
    use sui::test_scenario;
    use suipass::suipass::{Self, init_for_testing};
    use suipass::user::{User, new, get_user_info};
    use std::string::{Self, String};
    use sui::test_utils::assert_eq;

    #[test]
    public fun test_create_user_success_create_user() {
        let shop_owner = @0xa;

        let mut scenario = test_scenario::begin(shop_owner);

        {
            new(b"name: test", test_scenario::ctx(&mut scenario));
        };
        let tx = test_scenario::next_tx(&mut scenario, shop_owner);

        {
            let user = test_scenario::take_from_sender<User>(&scenario);
            let user_info = get_user_info(&user);
            assert_eq(user_info, string::utf8(b"name: test"));

            test_scenario::return_to_sender(&scenario, user);
        };
        let tx = test_scenario::end(scenario);
    }
}