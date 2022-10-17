// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../lib/StakingUtils.sol";
import "./BaseStaking.sol";

contract MintableSupplyStaking is BaseStaking {
    using SafeERC20 for IERC20;
    modifier updateReward(address account) virtual override {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function _stake(uint256 _amount) internal virtual override {
        _balances[msg.sender] += _amount;
        _totalSupply += _amount;

        IERC20(configuration.stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
        emit Stake(msg.sender, _amount);
    }

    function _compound(address account) internal virtual override {
        uint256 reward = rewards[account];
        rewards[account] = 0;

        _balances[account] += reward;
        _totalSupply += reward;

        ERC20PresetMinterPauser(address(configuration.rewardsToken)).mint(address(this), reward);
    }

    function _claim() internal virtual override {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        ERC20PresetMinterPauser(address(configuration.rewardsToken)).mint(msg.sender, reward);
        emit Claim(msg.sender, reward);
    }

    function setRewardRate(uint256 rate) external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;
        configuration.rewardRate = rate;
    }

    function getInfo() public view virtual override returns (uint256[7] memory) {
        return [
            _rewardSupply,
            _totalSupply,
            configuration.startTime,
            configuration.rewardRate,
            configuration.maxStake,
            configuration.minStake,
            0
        ];
    }

    function _canStake(address account, uint256) internal view virtual override {
        require(
            (configuration.maxStake == 0 || _balances[account] <= configuration.maxStake) &&
                _balances[account] >= configuration.minStake,
            "LIMIT EXCEEDED"
        );
    }

    function topUpRewards(uint256) public virtual override {}

    function blocksLeft() public view virtual override returns (uint256) {}

    function rewardPerToken() internal view virtual override returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.number - lastUpdateBlock) * configuration.rewardRate * 1e36) / _totalSupply);
    }

    uint256[50] private __gap;
}