// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

abstract contract UniStakingTokensStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _rewardPool;
    uint256 private _rewardSupply;
    uint256 private _totalSupply;
    IERC20 private _rewardsToken;
    IERC20 private _stakingToken;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _claimed;
    mapping(address => uint256) private _rewards;

    function rewardPool() public view returns (uint256) {
        return _rewardPool;
    }

    function rewardSupply() public view returns (uint256) {
        return _rewardSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function rewardsToken() public view returns (IERC20) {
        return _rewardsToken;
    }

    function stakingToken() public view returns (IERC20) {
        return _stakingToken;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function claimedOf(address account) public view returns (uint256) {
        return _claimed[account];
    }

    function rewardOf(address account) public view returns (uint256) {
        return _rewards[account];
    }

    constructor(IERC20 rewardsToken_, IERC20 stakingToken_) public {
        _rewardsToken = rewardsToken_;
        _stakingToken = stakingToken_;
    }

    function _onMint(address account, uint256 amount) internal virtual {}
    function _onBurn(address account, uint256 amount) internal virtual {}

    function _stake(address account, uint256 amount) internal {
        _stakingToken.safeTransferFrom(account, address(this), amount);
        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        _onMint(account, amount);
    }

    function _unstake(address account, uint256 amount) internal {
        _stakingToken.safeTransfer(account, amount);
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        _onBurn(account, amount);
    }

    function _increaseRewardPool(address owner, uint256 amount) internal {
        _rewardsToken.safeTransferFrom(owner, address(this), amount);
        _rewardSupply = _rewardSupply.add(amount);
        _rewardPool = _rewardPool.add(amount);
    }

    function _reduceRewardPool(address owner, uint256 amount) internal {
        _rewardsToken.safeTransfer(owner, amount);
        _rewardSupply = _rewardSupply.sub(amount);
        _rewardPool = _rewardPool.sub(amount);
    }

    function _addReward(address account, uint256 amount) internal {
        _rewards[account] = _rewards[account].add(amount);
        _rewardPool = _rewardPool.sub(amount);
    }

    function _withdraw(address account, uint256 amount) internal {
        _rewardsToken.safeTransfer(account, amount);
        _claimed[account] = _claimed[account].sub(amount);
    }

    function _claim(address account, uint256 amount) internal {
        _rewards[account] = _rewards[account].sub(amount);
        _rewardSupply = _rewardSupply.sub(amount);
        _claimed[account] = _claimed[account].add(amount);
    }

    function _transferBalance(
        address from,
        address to,
        uint256 amount
    ) internal {
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
    }
}