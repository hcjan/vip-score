// this is an example of how to use scoring in the contract.
// policy for scoring is defined in the function body.
module score::score_distribute {
    use std::signer;
    use std::block::{get_block_info}; 
    use std::simple_map::{Self, SimpleMap, borrow, borrow_mut, contains_key};
    use minitia_std::vip_score;
    use score::score_helper;
    

    const ESpotSigner: u64 = 1;
    const EPerpSigner: u64 = 2;
    const EUNAUTHORIZED: u64 = 3;

    struct SpotDexInfo has key{
        add_liquidity_score: u64,
        swap_score: u64,
        // day => updated
        add_liquidity_updated: SimpleMap<address, SimpleMap<u64, bool>>,
        swap_update_times: SimpleMap<address, SimpleMap<u64, u64>>,
    }

    struct Auth has key{
        spot_signer_address: address,
        perp_signer_address: address,
    }

    struct PerpInfo has key{
        add_liquidity_score: u64,
        trade_score: u64,
        add_liquidity_updated:  SimpleMap<address, SimpleMap<u64, bool>>,
        trade_update_times: SimpleMap<address, SimpleMap<u64, u64>>,
    }

    fun init_module(deployer: &signer) {

        move_to(deployer, SpotDexInfo {
            add_liquidity_score: 20, // Example score, adjust as needed
            swap_score: 10, // Example score, adjust as needed
            add_liquidity_updated: simple_map::create(),
            swap_update_times: simple_map::create(),
        });

        move_to(deployer, Auth {
            spot_signer_address: @score, // Set to deployer address initially
            perp_signer_address: @score, // Set to deployer address initially
        });

        move_to(deployer, PerpInfo {
            add_liquidity_score: 20, // Example score, adjust as needed
            trade_score: 10, // Example score, adjust as needed
            add_liquidity_updated: simple_map::create(),
            trade_update_times: simple_map::create(),
        });
                
   }

    #[view]
    public fun get_day():u64 {
             let (_, timestamp) = get_block_info();
             let day = timestamp / 86400;
             return day
    }

    public entry fun set_spot_signer(deployer: &signer, new_signer: address) acquires Auth {
        assert!(signer::address_of(deployer) == @score, EUNAUTHORIZED);
        let auth = borrow_global_mut<Auth>(@score);
        auth.spot_signer_address = new_signer;
    }

    public entry fun set_perp_signer(deployer: &signer, new_signer: address) acquires Auth {
        assert!(signer::address_of(deployer) == @score, EUNAUTHORIZED);
        let auth = borrow_global_mut<Auth>(@score);
        auth.perp_signer_address = new_signer;
    }


    public entry fun spot_dex_add_liquidity(spot_signer: &signer, account: address) acquires Auth, SpotDexInfo{
        let auth = borrow_global<Auth>(@score);
        assert!(signer::address_of(spot_signer) == auth.spot_signer_address, ESpotSigner);
        let spot_dex_info = borrow_global_mut<SpotDexInfo>(@score);
        let current_day = get_day();

        if (!simple_map::contains_key(&spot_dex_info.add_liquidity_updated, &account)) {
            simple_map::add(&mut spot_dex_info.add_liquidity_updated, account, simple_map::create());
        };

        let user_updates = simple_map::borrow_mut(&mut spot_dex_info.add_liquidity_updated, &account);

        if (!simple_map::contains_key(user_updates, &current_day)) {
            simple_map::add(user_updates, current_day, true);
            score_helper::increase_score(account, spot_dex_info.add_liquidity_score);
        };

    }

    public entry fun spot_dex_swap(spot_signer: &signer, account: address)acquires Auth, SpotDexInfo {
        let auth = borrow_global<Auth>(@score);
        assert!(signer::address_of(spot_signer) == auth.spot_signer_address, ESpotSigner);  
         
        let spot_dex_info = borrow_global_mut<SpotDexInfo>(@score);
        let current_day = get_day();

        if (!contains_key(&spot_dex_info.swap_update_times, &account)) {
            simple_map::add(&mut spot_dex_info.swap_update_times, account, simple_map::create());
        };

         let user_updates = simple_map::borrow_mut(&mut spot_dex_info.swap_update_times, &account);

        if (!simple_map::contains_key(user_updates, &current_day)) {
            simple_map::add(user_updates, current_day, 1);
            score_helper::increase_score(account, spot_dex_info.swap_score);
        } else {
            let update_times = simple_map::borrow_mut(user_updates, &current_day);
            if (*update_times < 3) {
                *update_times = *update_times + 1;
                score_helper::increase_score(account, spot_dex_info.swap_score);
            };
        };
        }
    

    

    public entry fun perp_add_liquidity(perp_signer: &signer, account: address) acquires Auth, PerpInfo {
        let auth = borrow_global<Auth>(@score);
        assert!(signer::address_of(perp_signer) == auth.perp_signer_address, EPerpSigner);  
        let perp_info = borrow_global_mut<PerpInfo>(@score);
        let current_day = get_day();

        if (!simple_map::contains_key(&perp_info.add_liquidity_updated, &account)) {
            simple_map::add(&mut perp_info.add_liquidity_updated, account, simple_map::create());
        };

        let user_updates = simple_map::borrow_mut(&mut perp_info.add_liquidity_updated, &account);

        if (!simple_map::contains_key(user_updates, &current_day)) {
            simple_map::add(user_updates, current_day, true);
            score_helper::increase_score(account, perp_info.add_liquidity_score);
        };
        }
    
     public entry fun perp_trade(perp_signer: &signer, account: address)acquires Auth, PerpInfo {
        let auth = borrow_global<Auth>(@score);
        assert!(signer::address_of(perp_signer) == auth.perp_signer_address, EPerpSigner);  
        let perp_info = borrow_global_mut<PerpInfo>(@score);
        let current_day = get_day();

        if (!simple_map::contains_key(&perp_info.trade_update_times, &account)) {
            simple_map::add(&mut perp_info.trade_update_times, account, simple_map::create());
        };

        let user_updates = simple_map::borrow_mut(&mut perp_info.trade_update_times, &account);

        if (!simple_map::contains_key(user_updates, &current_day)) {
            simple_map::add(user_updates, current_day, 1);
            score_helper::increase_score(account, perp_info.trade_score);
        } else {
            let update_times = simple_map::borrow_mut(user_updates, &current_day);
            if (*update_times < 3) {
                *update_times = *update_times + 1;
                score_helper::increase_score(account, perp_info.trade_score);
            };
        };
    }
    
}
