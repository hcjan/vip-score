// this module is used to help deployer to interact with vip_score module
// note that `score_helper.move` should be deployed under the same account with `example_with_scoring.move`
module score::score_helper {
    use std::error;
    use std::signer;

    use minitia_std::object::{Self, ExtendRef};
    use minitia_std::vip_score;

    const EUNAUTHORIZED: u64 = 1;
    const EINVALID_SCORE: u64 = 2;
    const EALREADY_REGISTERED: u64 = 3;

    friend score::score_distribute;

    // ScoreStore is needed to score functions triggered by user
    struct ScoreStore has key {
        extend_ref: ExtendRef,
        stage: u64
    }

    public entry fun register_vip_score(deployer: &signer) {
        assert!(!exists<ScoreStore>(@score), error::invalid_argument(EALREADY_REGISTERED)); 
        let constructor_ref = object::create_named_object(deployer, b"seed", false);
        let extend_ref = object::generate_extend_ref(&constructor_ref);
        move_to(deployer, ScoreStore { extend_ref, stage: 0 })
    }

    // prepare stage info for scoring
    public entry fun prepare_stage_script(deployer: &signer, stage: u64) acquires ScoreStore {
        assert!(signer::address_of(deployer) == @score,
            error::permission_denied(EUNAUTHORIZED));
        
        let score_store = borrow_global_mut<ScoreStore>(@score);
        let deployer = &object::generate_signer_for_extending(&score_store.extend_ref);
        vip_score::prepare_stage(deployer, stage);
        score_store.stage = stage;
    }

    public entry fun finalize_stage_script(deployer: &signer, stage: u64) acquires ScoreStore {
        assert!(signer::address_of(deployer) == @score,
            error::permission_denied(EUNAUTHORIZED));
        
        let score_store = borrow_global_mut<ScoreStore>(@score);
        let deployer = &object::generate_signer_for_extending(&score_store.extend_ref);
        vip_score::finalize_script(deployer, stage);
    }

    // interface to update user score to specific value
    public(friend) fun update_score(addr: address, score: u64) acquires ScoreStore {
        let score_store = borrow_global<ScoreStore>(@score);
        let deployer = &object::generate_signer_for_extending(&score_store.extend_ref);
        vip_score::update_score(deployer, addr, score_store.stage, score);
    }
    
    // interface to increase user score
    public(friend) fun increase_score(addr: address, score: u64) acquires ScoreStore {
        let score_store = borrow_global<ScoreStore>(@score);
        let deployer = &object::generate_signer_for_extending(&score_store.extend_ref);
        vip_score::increase_score(deployer, addr, score_store.stage, score);
    }

    // interface to decrease user score. note that score cannot be decreased to < 0
    public(friend) fun decrease_score(addr: address, score: u64) acquires ScoreStore {
        let score_store = borrow_global<ScoreStore>(@score);
        let deployer = &object::generate_signer_for_extending(&score_store.extend_ref);
        let user_score = vip_score::get_score(addr, score_store.stage);
        assert!(user_score >= score, error::invalid_argument(EINVALID_SCORE));
        vip_score::decrease_score(deployer, addr, score_store.stage, score);
    }

    #[view]
    public fun get_deployer_object_address(): address acquires ScoreStore {
        let score_store = borrow_global<ScoreStore>(@score);
        object::address_from_extend_ref(&score_store.extend_ref)
    }
}
