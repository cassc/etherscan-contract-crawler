pragma solidity ^0.5.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./VestingPlan.sol";
import "./SeedAccountInit.sol";
import "./TeamAccountInit.sol";

contract DADTokenVesting is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using Address for address;

    VestingPlan.AccountPlans private seed_plans;
    VestingPlan.AccountPlans private team_plans;
    enum releaseTargetType {TEAM, SEED}

    event TokensReleased(IERC20 token, uint256 amount, address account, releaseTargetType target_type);
    event TokensRevoked(IERC20 token, address to, uint256 amount);

    IERC20 private _dad_token;

    constructor(IERC20 dad_token) public{
        require(address(dad_token) != address(0), "TokenVesting: dad token is the zero address");
        _dad_token = dad_token;
        
        // 2020-04-30 2020-10-31 2021-4-30 2021-10-31
        uint256[4] memory seed_paln_timestamps = [uint256(1588204800),1604102400, 1619712000, 1635638400];
        // seed init data
        SeedAccountInit.AccountInitPlan[] memory seed_accounts_plans = new SeedAccountInit.AccountInitPlan[](3);
        seed_accounts_plans[0] = SeedAccountInit.AccountInitPlan(
                            {account:address(0xe9cCb1a22D7aEF37964f70C0F051DD8E6F6d43fC),
                             amounts:[uint256(9_375_000_000_000_000),uint256(9_375_000_000_000_000),uint256(9_375_000_000_000_000),uint256(9_375_000_000_000_000)],
                             timestamps:seed_paln_timestamps});
        seed_accounts_plans[1] = SeedAccountInit.AccountInitPlan(
                            {account:address(0x3AEE5cf9Fe5B8E788C32815C19B4acF88D653B51),
                             amounts:[uint256(18_750_000_000_000_000),uint256(1_875_0000_000_000_000),uint256(1_875_0000_000_000_000),uint256(1_875_0000_000_000_000)],
                             timestamps:seed_paln_timestamps});
        seed_accounts_plans[2] = SeedAccountInit.AccountInitPlan(
                            {account:address(0x8e1D52B707cb808DE04e49a8cd99124cDBC18Aa0),
                             amounts:[uint256(9_375_000_000_000_000),uint256(9_375_000_000_000_000),uint256(9_375_000_000_000_000),uint256(9_375_000_000_000_000)],
                             timestamps:seed_paln_timestamps});
                     
        _init_seed_plan_detail(seed_plans,seed_accounts_plans);
        
        
        // 2020-5-31, 2020-11-30, 2021-5-31, 2021-11-30, 2022-5-31, 2022-11-30, 2023-5-31,2023-11-30
        uint256[8] memory team_paln_timestamps = [uint256(1590854400),1606694400,1622390400,1638230400,1653926400,1669766400,1685462400,1701302400];
        
        uint256 team_coin_count_per_time = 18750000_000_000_000;
        TeamAccountInit.AccountInitPlan[] memory team_accounts_plans = new TeamAccountInit.AccountInitPlan[](1);
        team_accounts_plans[0] = TeamAccountInit.AccountInitPlan(
                            {account:address(0x7f372E2a4E69f92b4D70Cb3D637BB1FEbF118062),
                             amounts:[team_coin_count_per_time,team_coin_count_per_time,team_coin_count_per_time,team_coin_count_per_time,team_coin_count_per_time,team_coin_count_per_time,team_coin_count_per_time,team_coin_count_per_time],
                             timestamps:team_paln_timestamps});
        _init_team_plan_detail(team_plans,team_accounts_plans);

    }


    ///////////plan functions///////
    function _init_seed_plan_detail(VestingPlan.AccountPlans storage plans_init, 
                                SeedAccountInit.AccountInitPlan[] memory accounts_plans) internal{
        
        for(uint a = 0; a < accounts_plans.length; a++){
            SeedAccountInit.AccountInitPlan memory plans = accounts_plans[a];
            // account must be unique
            assert(plans_init._account_plans[plans.account].length == 0);
            // add account key
            plans_init._accounts.push(plans.account);
            // setup account values
            for(uint t = 0; t < plans.timestamps.length; t++){
                plans_init._account_plans[plans.account].push(VestingPlan.AccountTimePlan(
                    {amount:plans.amounts[t], timestamp:plans.timestamps[t]}
                    ));
            }
        }
    }

    ///////////plan functions///////
    function _init_team_plan_detail(VestingPlan.AccountPlans storage plans_init, 
                                TeamAccountInit.AccountInitPlan[] memory accounts_plans) internal{
        
        for(uint a = 0; a < accounts_plans.length; a++){
            TeamAccountInit.AccountInitPlan memory plans = accounts_plans[a];
            // account must be unique
            assert(plans_init._account_plans[plans.account].length == 0);
            // add account key
            plans_init._accounts.push(plans.account);
            // setup account values
            for(uint t = 0; t < plans.timestamps.length; t++){
                plans_init._account_plans[plans.account].push(VestingPlan.AccountTimePlan(
                    {amount:plans.amounts[t], timestamp:plans.timestamps[t]}
                    ));
            }
        }
    }

    function _get_vested_account_amount(VestingPlan.AccountPlans storage accounts_plans, 
    uint256 timestamp, address account) internal view returns(uint256){
        uint256 release_amount = 0;
         VestingPlan.AccountTimePlan[] storage plans = accounts_plans._account_plans[account];
         for (uint i = 0; i < plans.length; i++) {
            if(plans[i].timestamp < timestamp){
                release_amount += plans[i].amount;
            }
        }
        return release_amount;
    }
    
    // send token and record the released amount
    function _do_record_release_token(VestingPlan.AccountPlans storage accounts_plans, 
    address target, uint256 amount) internal {
        accounts_plans._account_released[target] = accounts_plans._account_released[target].add(amount);
    }
    
    // get the amount that already vested but hasn't been released yet.
    function _releasable_account_amount(VestingPlan.AccountPlans storage accounts_plans, 
    address account) internal view returns(uint256) {
        return _get_vested_account_amount(accounts_plans, block.timestamp, account).sub(accounts_plans._account_released[account]);
    }

    function _get_account_released(VestingPlan.AccountPlans storage accounts_plans, 
    address account) internal view returns(uint256){
        return accounts_plans._account_released[account];
    }

    // send token and record the released amount
    function _do_release_token(IERC20 token, address target, uint256 amount, releaseTargetType targetType, 
                            VestingPlan.AccountPlans storage plans) private{
        _do_record_release_token(plans, target, amount);
        token.safeTransfer(target, amount);
        emit TokensReleased(_dad_token, amount, target, targetType);
    }

    /////////////seed part api///////////
    function seed_plan_amount(address account) public view returns (uint256){
       return _get_vested_account_amount(seed_plans, block.timestamp, account);
    }


    function get_seed_account_released(address account) public view returns(uint256){
        return _get_account_released(seed_plans, account);
    }
    
    function seed_plan_amount_time(uint256 timestamp, address account) public view returns (uint256){
       return _get_vested_account_amount(seed_plans, timestamp, account);
    }
    
    // release the token for seed account
    function seed_account_release(address account) public onlyOwner{

        uint256 unreleased = _releasable_account_amount(seed_plans, account);

        require(unreleased > 0, "TokenVesting: no tokens are due");

        _do_release_token(_dad_token, account, unreleased, 
                            releaseTargetType.SEED, seed_plans);
    }
    
    // release seed all accounts
    function seed_release_all_accounts() public onlyOwner{
        for(uint a = 0; a < seed_plans._accounts.length; a++){
            uint256 unreleased = _releasable_account_amount(seed_plans, seed_plans._accounts[a]);
            if(unreleased == 0){
                continue;
            }
            _do_release_token(_dad_token, seed_plans._accounts[a], unreleased, 
                                releaseTargetType.SEED, seed_plans);
        }
    }
    
    /////////////team part api///////////
    function team_plan_amount(address account) public view returns (uint256){
       return _get_vested_account_amount(team_plans, block.timestamp, account);
    }


    function get_team_account_released(address account) public view returns(uint256){
        return _get_account_released(team_plans, account);
    }
    
    function team_plan_amount_time(uint256 timestamp, address account) public view returns (uint256){
       return _get_vested_account_amount(team_plans, timestamp, account);
    }
    
    // release the token for team account
    function team_account_release(address account) public onlyOwner{

        uint256 unreleased = _releasable_account_amount(team_plans, account);

        require(unreleased > 0, "TokenVesting: no tokens are due");

        _do_release_token(_dad_token, account, unreleased, 
                            releaseTargetType.TEAM, team_plans);
    }
    
    // release team all accounts
    function team_release_all_accounts() public onlyOwner{
        for(uint a = 0; a < team_plans._accounts.length; a++){
            uint256 unreleased = _releasable_account_amount(team_plans, team_plans._accounts[a]);
            if(unreleased == 0){
                continue;
            }
            _do_release_token(_dad_token, team_plans._accounts[a], unreleased, 
                                releaseTargetType.TEAM, team_plans);
        }
    }

    //////////manage part api//////////////
    function dad_token_balance() public view returns(uint256){
        return _dad_token.balanceOf(address(this));
    }

    function dad_token_address() public view returns(IERC20){
        return _dad_token;
    }

    //回收
    function revoke(address to, uint256 amount) public onlyOwner {
        uint256 balance = _dad_token.balanceOf(address(this));
        require(balance >= amount, "balance is not enough for amount");
        _dad_token.safeTransfer(to, amount);
        emit TokensRevoked(_dad_token, to, amount);
    }
    
    function set_dad_token_address(IERC20 dad_token) public onlyOwner {
        require(address(dad_token) != address(0), "TokenVesting: dad token is the zero address");
       _dad_token = dad_token;
    }
}
