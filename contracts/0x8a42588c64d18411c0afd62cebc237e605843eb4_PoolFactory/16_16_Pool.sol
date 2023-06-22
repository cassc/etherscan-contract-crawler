/*
Pool

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IPool.sol";
import "./interfaces/IConfiguration.sol";
import "./interfaces/IStakingModule.sol";
import "./interfaces/IRewardModule.sol";
import "./interfaces/IEvents.sol";
import "./OwnerController.sol";

/**
 * @title Pool
 *
 * @notice this implements the GYSR core Pool contract. It supports generalized
 * incentive mechanisms through a modular architecture, where
 * staking and reward logic is contained in child contracts.
 */
contract Pool is IPool, IEvents, ReentrancyGuard, OwnerController {
    using SafeERC20 for IERC20;

    // modules
    IStakingModule private immutable _staking;
    IRewardModule private immutable _reward;

    // gysr fields
    IERC20 private immutable _gysr;
    IConfiguration private immutable _config;
    uint256 private _gysrVested;

    /**
     * @param staking_ the staking module address
     * @param reward_ the reward module address
     * @param gysr_ address for GYSR token
     * @param config_ address for configuration contract
     */
    constructor(
        address staking_,
        address reward_,
        address gysr_,
        address config_
    ) {
        _staking = IStakingModule(staking_);
        _reward = IRewardModule(reward_);
        _gysr = IERC20(gysr_);
        _config = IConfiguration(config_);
    }

    // -- IPool --------------------------------------------------------------

    /**
     * @inheritdoc IPool
     */
    function stakingTokens() external view override returns (address[] memory) {
        return _staking.tokens();
    }

    /**
     * @inheritdoc IPool
     */
    function rewardTokens() external view override returns (address[] memory) {
        return _reward.tokens();
    }

    /**
     * @inheritdoc IPool
     */
    function stakingBalances(
        address user
    ) external view override returns (uint256[] memory) {
        return _staking.balances(user);
    }

    /**
     * @inheritdoc IPool
     */
    function stakingTotals() external view override returns (uint256[] memory) {
        return _staking.totals();
    }

    /**
     * @inheritdoc IPool
     */
    function rewardBalances()
        external
        view
        override
        returns (uint256[] memory)
    {
        return _reward.balances();
    }

    /**
     * @inheritdoc IPool
     */
    function usage() external view override returns (uint256) {
        return _reward.usage();
    }

    /**
     * @inheritdoc IPool
     */
    function stakingModule() external view override returns (address) {
        return address(_staking);
    }

    /**
     * @inheritdoc IPool
     */
    function rewardModule() external view override returns (address) {
        return address(_reward);
    }

    /**
     * @inheritdoc IPool
     */
    function stake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override nonReentrant {
        (bytes32 account, uint256 shares) = _staking.stake(
            msg.sender,
            amount,
            stakingdata
        );
        (uint256 spent, uint256 vested) = _reward.stake(
            account,
            msg.sender,
            shares,
            rewarddata
        );
        _processGysr(spent, vested);
    }

    /**
     * @inheritdoc IPool
     */
    function unstake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override nonReentrant {
        (bytes32 account, address receiver, uint256 shares) = _staking.unstake(
            msg.sender,
            amount,
            stakingdata
        );
        (uint256 spent, uint256 vested) = _reward.unstake(
            account,
            msg.sender,
            receiver,
            shares,
            rewarddata
        );
        _processGysr(spent, vested);
    }

    /**
     * @inheritdoc IPool
     */
    function claim(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override nonReentrant {
        (bytes32 account, address receiver, uint256 shares) = _staking.claim(
            msg.sender,
            amount,
            stakingdata
        );
        (uint256 spent, uint256 vested) = _reward.claim(
            account,
            msg.sender,
            receiver,
            shares,
            rewarddata
        );
        _processGysr(spent, vested);
    }

    /**
     * @inheritdoc IPool
     */
    function update(
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override nonReentrant {
        bytes32 account = _staking.update(msg.sender, stakingdata);
        _reward.update(account, msg.sender, rewarddata);
    }

    /**
     * @inheritdoc IPool
     */
    function clean(
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external override nonReentrant {
        requireController();
        _staking.clean(stakingdata);
        _reward.clean(rewarddata);
    }

    /**
     * @inheritdoc IPool
     */
    function gysrBalance() external view override returns (uint256) {
        return _gysrVested;
    }

    /**
     * @inheritdoc IPool
     */
    function withdraw(uint256 amount) external override {
        requireController();
        require(amount > 0, "p1");
        require(amount <= _gysrVested, "p2");

        // do transfer
        _gysr.safeTransfer(msg.sender, amount);

        _gysrVested = _gysrVested - amount;

        emit GysrWithdrawn(amount);
    }

    /**
     * @inheritdoc IPool
     */
    function transferControlStakingModule(
        address newController
    ) external override {
        requireOwner();
        _staking.transferControl(newController);
    }

    /**
     * @inheritdoc IPool
     */
    function transferControlRewardModule(
        address newController
    ) external override {
        requireOwner();
        _reward.transferControl(newController);
    }

    /**
     * @inheritdoc IPool
     */
    function multicall(
        bytes[] calldata data
    ) external override returns (bytes[] memory results) {
        // h/t https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol
        results = new bytes[](data.length);
        for (uint256 i; i < data.length; ++i) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            if (!success) {
                // h/t https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            results[i] = result;
        }
    }

    // -- Pool internal -----------------------------------------------------

    /**
     * @dev private method to process GYSR spending and vesting
     * @param spent number of tokens spent by user
     * @param vested number of tokens vested
     */
    function _processGysr(uint256 spent, uint256 vested) private {
        // spending
        if (spent > 0) {
            _gysr.safeTransferFrom(msg.sender, address(this), spent);
        }

        // vesting
        if (vested > 0) {
            (address receiver, uint256 rate) = _config.getAddressUint96(
                keccak256("gysr.core.pool.spend.fee")
            );

            // fallback to zero fee on bad configuration
            uint256 fee;
            if (rate > 0 && rate <= 1e18 && receiver != address(0)) {
                fee = (vested * rate) / 1e18;
                _gysr.safeTransfer(receiver, fee);
                emit Fee(receiver, address(_gysr), fee);
            }
            _gysrVested = _gysrVested + vested - fee;
        }
    }
}