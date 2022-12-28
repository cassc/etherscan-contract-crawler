// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Curve/ICurveGauge.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TestDummyGauge is ERC20("test", "TST"), ERC20Permit("test"), ICurveGauge
{
    ICurveStableSwap public lp_token;
    address public claimRewardsAddress;

    constructor(ICurveStableSwap _pool)
    {
        lp_token = _pool;
    }

    function deposit(uint256 amount, address receiver, bool _claim_rewards) external 
    {
        lp_token.transferFrom(msg.sender, address(this), amount);
        _mint(receiver, amount);
        if (_claim_rewards) { claim_rewards(msg.sender); }
    }
    function withdraw(uint256 amount, bool _claim_rewards) external
    {
        if (_claim_rewards) { claim_rewards(msg.sender); }
        _burn(msg.sender, amount);
        lp_token.transfer(msg.sender, amount);
    }
    function claim_rewards(address addr) public { claimRewardsAddress = addr; }
    function working_supply() external view returns (uint256) {}
    function working_balances(address _user) external view returns (uint256) {}
    function claimable_tokens(address _user) external view returns (uint256) {}
    function claimed_reward(address _user, address _token) external view returns (uint256) {}
    function claimable_reward(address _user, address _token) external view returns (uint256) {}
    function reward_tokens(uint256 index) external view returns (address) {}
    function deposit_reward_token(address _token, uint256 amount) external
    {
        IERC20Full(_token).transferFrom(msg.sender, address(this), amount);
    }
    function reward_count() external view returns (uint256) {}
    function reward_data(address token) external view returns (Reward memory) {}
    function add_reward(address _reward_token, address _distributor) external {}
    function set_reward_distributor(address _reward_token, address _distributor) external {}

    function version() external view returns (string memory) {}
}