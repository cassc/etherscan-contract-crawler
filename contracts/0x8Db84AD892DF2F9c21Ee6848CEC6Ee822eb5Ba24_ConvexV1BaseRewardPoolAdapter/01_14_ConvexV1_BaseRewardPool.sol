// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { AbstractAdapter } from "@gearbox-protocol/core-v2/contracts/adapters/AbstractAdapter.sol";

import { IBooster } from "../../integrations/convex/IBooster.sol";
import { IBaseRewardPool } from "../../integrations/convex/IBaseRewardPool.sol";
import { IRewards } from "../../integrations/convex/Interfaces.sol";
import { AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { IConvexV1BaseRewardPoolAdapter } from "../../interfaces/convex/IConvexV1BaseRewardPoolAdapter.sol";

// EXCEPTIONS
import { NotImplementedException } from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

/// @title ConvexV1BaseRewardPoolAdapter adapter
/// @dev Implements logic for interacting with the Convex BaseRewardPool contract
contract ConvexV1BaseRewardPoolAdapter is
    AbstractAdapter,
    IBaseRewardPool,
    IConvexV1BaseRewardPoolAdapter,
    ReentrancyGuard
{
    // @dev The underlying Curve pool LP token
    address public immutable override curveLPtoken;

    // @dev A non-transferable ERC20 that reports the amount of Convex LP staked in the pool
    address public immutable override stakedPhantomToken;

    // @dev The first token received as an extra reward for staking
    address public immutable override extraReward1;

    // @dev The second token received as an extra reward for staking
    address public immutable override extraReward2;

    // @dev The CVX token, received as a reward for staking
    address public immutable override cvx;

    // @dev The pid of baseRewardPool
    uint256 public immutable override pid;

    /// @dev Returns the token that is paid as a reward to stakers
    /// @notice This is always CRV
    IERC20 public immutable override rewardToken;

    /// @dev Returns the token that is staked in the pool
    IERC20 public immutable override stakingToken;

    /// @dev Returns a duration of a single round of rewards
    /// @dev A round of rewards is a period during which rewardPerToken is unlikely to change
    uint256 public immutable override duration;

    /// @dev Returns the operator of the pool
    /// @notice This is always the Booster contract
    address public immutable override operator;

    /// @dev Returns the reward manager of the pool
    /// @notice This is an address authorized to add extra rewards
    address public immutable override rewardManager;

    AdapterType public constant _gearboxAdapterType =
        AdapterType.CONVEX_V1_BASE_REWARD_POOL;
    uint16 public constant _gearboxAdapterVersion = 1;

    /// @dev Constructor
    /// @param _creditManager Address of the Credit Manager
    /// @param _baseRewardPool Address of the target BaseRewardPool contract
    constructor(
        address _creditManager,
        address _baseRewardPool,
        address _stakedPhantomToken
    ) AbstractAdapter(_creditManager, _baseRewardPool) {
        stakingToken = IERC20(IBaseRewardPool(_baseRewardPool).stakingToken()); // F: [ACVX1_P_01]

        pid = IBaseRewardPool(_baseRewardPool).pid(); // F: [ACVX1_P_13]

        rewardToken = IBaseRewardPool(_baseRewardPool).rewardToken(); // F: [ACVX1_P_13]
        duration = IBaseRewardPool(_baseRewardPool).duration(); // F: [ACVX1_P_13]
        operator = IBaseRewardPool(_baseRewardPool).operator(); // F: [ACVX1_P_13]
        rewardManager = IBaseRewardPool(_baseRewardPool).rewardManager(); // F: [ACVX1_P_13]

        stakedPhantomToken = _stakedPhantomToken;

        address _extraReward1;
        address _extraReward2;

        uint256 extraRewardLength = IBaseRewardPool(_baseRewardPool)
            .extraRewardsLength();

        if (extraRewardLength >= 1) {
            _extraReward1 = IRewards(
                IBaseRewardPool(_baseRewardPool).extraRewards(0)
            ).rewardToken();

            if (extraRewardLength >= 2) {
                _extraReward2 = IRewards(
                    IBaseRewardPool(_baseRewardPool).extraRewards(1)
                ).rewardToken();
            }
        }

        extraReward1 = _extraReward1; // F: [ACVX1_P_01]
        extraReward2 = _extraReward2; // F: [ACVX1_P_01]

        address booster = IBaseRewardPool(_baseRewardPool).operator();

        cvx = IBooster(booster).minter(); // F: [ACVX1_P_01]
        IBooster.PoolInfo memory poolInfo = IBooster(booster).poolInfo(
            IBaseRewardPool(_baseRewardPool).pid()
        );

        curveLPtoken = poolInfo.lptoken; // F: [ACVX1_P_01]

        if (creditManager.tokenMasksMap(address(rewardToken)) == 0)
            revert TokenIsNotAddedToCreditManagerException(
                address(rewardToken)
            ); // F: [ACVX1_P_02]

        if (creditManager.tokenMasksMap(cvx) == 0)
            revert TokenIsNotAddedToCreditManagerException(cvx); // F: [ACVX1_P_02]

        if (creditManager.tokenMasksMap(curveLPtoken) == 0)
            revert TokenIsNotAddedToCreditManagerException(curveLPtoken); // F: [ACVX1_P_02]

        if (
            _extraReward1 != address(0) &&
            creditManager.tokenMasksMap(_extraReward1) == 0
        ) revert TokenIsNotAddedToCreditManagerException(_extraReward1); // F: [ACVX1_P_02]

        if (
            _extraReward2 != address(0) &&
            creditManager.tokenMasksMap(_extraReward2) == 0
        ) revert TokenIsNotAddedToCreditManagerException(_extraReward2); // F: [ACVX1_P_02]
    }

    /// @dev Sends an order to stake Convex LP tokens in the BaseRewardPool
    /// @notice 'amount' is ignored since the calldata is routed directly to the target
    /// @notice Fast check parameters:
    /// Input token: Convex LP Token
    /// Output token: Phantom token (representing staked balance in the pool)
    /// Input token is allowed, since the target does a transferFrom for the Convex LP token
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance generally
    function stake(uint256) external override returns (bool) {
        _safeExecuteFastCheck(
            address(stakingToken),
            stakedPhantomToken,
            msg.data,
            true,
            false
        ); // F: [ACVX1_P_03]
        return true;
    }

    /// @dev Sends an order to stake all available Convex LP tokens in the BaseRewardPool
    /// @notice Fast check parameters:
    /// Input token: Convex LP Token
    /// Output token: Phantom token (representing staked balance in the pool)
    /// Input token is allowed, since the target does a transferFrom for the Convex LP token
    /// The input token does need to be disabled, because this spends the entire balance
    function stakeAll() external override returns (bool) {
        _safeExecuteFastCheck(
            address(stakingToken),
            stakedPhantomToken,
            msg.data,
            true,
            true
        ); // F: [ACVX1_P_04]
        return true;
    }

    /// @dev Sends an order to stake tokens for another account
    /// @notice Not implemented since sending assets to others from a CA is not allowed
    function stakeFor(address, uint256) external pure override returns (bool) {
        revert NotImplementedException(); // F: [ACVX1_P_05]
    }

    /// @dev Sends an order to withdraw Convex LP tokens from the BaseRewardPool
    /// @param claim Whether to claim rewards while withdrawing
    /// @notice 'amount' is ignored since the unchanged calldata is routed directly to the target
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance generally
    function withdraw(uint256, bool claim) external override returns (bool) {
        return _withdraw(msg.data, claim, false); // F: [ACVX1_P_09]
    }

    /// @dev Sends an order to withdraw all Convex LP tokens from the BaseRewardPool
    /// @param claim Whether to claim rewards while withdrawing
    /// The input token does need to be disabled, because this spends the entire balance
    function withdrawAll(bool claim) external override {
        _withdraw(msg.data, claim, true); // F: [ACVX1_P_10]
    }

    /// @dev Internal implementation for withdrawal functions
    /// - Invokes a safe allowance fast check call to target, with passed calldata
    /// - Enables reward tokens if rewards were claimed
    /// @param callData Data that the target contract will be called with
    /// @param claim Whether to claim rewards while withdrawing
    /// @notice Fast check parameters:
    /// Input token: Phantom token (representing staked balance in the pool)
    /// Output token: Convex LP Token
    /// Input token is not allowed, since the target does not need to transferFrom
    function _withdraw(
        bytes memory callData,
        bool claim,
        bool disableTokenIn
    ) internal returns (bool) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        _safeExecuteFastCheck(
            creditAccount,
            stakedPhantomToken,
            address(stakingToken),
            callData,
            false,
            disableTokenIn
        );

        if (claim) {
            _enableRewardTokens(creditAccount, true);
        }

        return true;
    }

    /// @dev Sends an order to withdraw Convex LP tokens from the BaseRewardPool
    /// and immediately unwrap them into Curve LP tokens
    /// @param claim Whether to claim rewards while withdrawing
    /// @notice 'amount' is ignored since the unchanged calldata is routed directly to the target
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance generally
    function withdrawAndUnwrap(uint256, bool claim)
        external
        override
        returns (bool)
    {
        _withdrawAndUnwrap(msg.data, claim, false); // F: [ACVX1_P_11]
        return true;
    }

    /// @dev Sends an order to withdraw all Convex LP tokens from the BaseRewardPool
    /// and immediately unwrap them into Curve LP tokens
    /// @param claim Whether to claim rewards while withdrawing
    /// The input token does need to be disabled, because this spends the entire balance
    function withdrawAllAndUnwrap(bool claim) external override {
        _withdrawAndUnwrap(msg.data, claim, true); // F: [ACVX1_P_12]
    }

    /// @dev Internal implementation for 'withdrawAndUnwrap' functions
    /// - Invokes a safe allowance fast check call to target, with passed calldata
    /// - Enables reward tokens if rewards were claimed
    /// @param callData Data that the target contract will be called with
    /// @param claim Whether to claim rewards while withdrawing
    /// @notice Fast check parameters:
    /// Input token: Phantom token (representing staked balance in the pool)
    /// Output token: Curve LP Token
    /// Input token is not allowed, since the target does not need to transferFrom
    function _withdrawAndUnwrap(
        bytes memory callData,
        bool claim,
        bool disableTokenIn
    ) internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        _safeExecuteFastCheck(
            creditAccount,
            stakedPhantomToken,
            curveLPtoken,
            callData,
            false,
            disableTokenIn
        );

        if (claim) {
            _enableRewardTokens(creditAccount, true);
        }
    }

    /// @dev Directly calls the corresponding target contract function with passed parameters
    /// @param _account Account to harvest rewards for
    /// @param _claimExtras Whether to claim extra rewards, or only CRV/CVX
    /// @notice Since the target function does not depend on msg.sender,
    /// it is called directly for efficiency
    function getReward(address _account, bool _claimExtras)
        external
        override
        returns (bool)
    {
        IBaseRewardPool(targetContract).getReward(_account, _claimExtras); // F: [ACVX1_P_06-07]
        _enableRewardTokens(_account, _claimExtras);

        if (_account == creditManager.creditAccounts(msg.sender)) {
            _checkAndOptimizeEnabledTokens(_account);
        } else {
            creditManager.checkAndOptimizeEnabledTokens(_account);
        }

        return true;
    }

    /// @dev Sends an order to harvest rewards on the current position
    /// - Routes calldata to the target contract
    /// - Enables the reward tokens that are harvested
    function getReward() external override returns (bool) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        creditManager.executeOrder(
            msg.sender,
            address(targetContract),
            msg.data
        ); // F: [ACVX1_P_08]

        _enableRewardTokens(creditAccount, true);
        _checkAndOptimizeEnabledTokens(creditAccount);

        return true;
    }

    function donate(uint256) external pure override returns (bool) {
        revert NotImplementedException();
    }

    /// @dev Enables reward tokens for a credit account after a claim operation
    /// @param creditAccount The credit account on which reward tokens are enabled
    /// @param claimExtras Whether the extra reward tokens have been claimed and
    /// have to be enabled as a result
    function _enableRewardTokens(address creditAccount, bool claimExtras)
        internal
    {
        // F: [ACVX1_P_03-12]
        creditManager.checkAndEnableToken(creditAccount, address(rewardToken));
        creditManager.checkAndEnableToken(creditAccount, cvx);

        if ((extraReward1 != address(0)) && claimExtras) {
            // F: [ACVX1_P_06-07]
            creditManager.checkAndEnableToken(creditAccount, extraReward1);

            if (extraReward2 != address(0)) {
                creditManager.checkAndEnableToken(creditAccount, extraReward2);
            }
        }
    }

    //
    // GETTERS
    //

    /// @dev Returns the amount of unclaimed CRV rewards earned by an account
    /// @param account The account for which the unclaimed amount is computed
    function earned(address account) public view override returns (uint256) {
        return IBaseRewardPool(targetContract).earned(account); // F: [ACVX1_P_13]
    }

    /// @dev Computes the latest timestamp in which stakers are entitled to rewards
    /// @notice Usually this is block.timestamp, but may sometimes be less when
    /// there are no new rewards for a long time
    function lastTimeRewardApplicable()
        external
        view
        override
        returns (uint256)
    {
        return IBaseRewardPool(targetContract).lastTimeRewardApplicable(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the cumulative amount of CRV rewards per single staked token
    function rewardPerToken() external view override returns (uint256) {
        return IBaseRewardPool(targetContract).rewardPerToken(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the total amount of Convex LP tokens staked in the pool
    function totalSupply() external view override returns (uint256) {
        return IBaseRewardPool(targetContract).totalSupply(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the amount of Convex LP tokens an account has in the pool
    /// @param account The account for which the calculation is performed
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return IBaseRewardPool(targetContract).balanceOf(account); // F: [ACVX1_P_13]
    }

    /// @dev Returns the number of extra reward tokens paid to stakers in the pool
    function extraRewardsLength() external view override returns (uint256) {
        return IBaseRewardPool(targetContract).extraRewardsLength(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the timestamp at which current rewards will be exhausted
    function periodFinish() external view override returns (uint256) {
        return IBaseRewardPool(targetContract).periodFinish(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the reward per token per second
    function rewardRate() external view override returns (uint256) {
        return IBaseRewardPool(targetContract).rewardRate(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the last timestamp at which the pool was updated
    function lastUpdateTime() external view override returns (uint256) {
        return IBaseRewardPool(targetContract).lastUpdateTime(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the saved cumulative rewards amount
    function rewardPerTokenStored() external view override returns (uint256) {
        return IBaseRewardPool(targetContract).rewardPerTokenStored(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the rewards that have been added to the pool
    /// but are not yet being distributed
    function queuedRewards() external view override returns (uint256) {
        return IBaseRewardPool(targetContract).queuedRewards(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the amount of rewards that will be dsitributed before periodFinish
    function currentRewards() external view override returns (uint256) {
        return IBaseRewardPool(targetContract).currentRewards(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the total amount of rewards distributed through the pool
    function historicalRewards() external view override returns (uint256) {
        return IBaseRewardPool(targetContract).historicalRewards(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the ratio of current to queued rewards at which
    /// queued rewards will enter the distribution
    function newRewardRatio() external view override returns (uint256) {
        return IBaseRewardPool(targetContract).newRewardRatio(); // F: [ACVX1_P_13]
    }

    /// @dev Returns the last saved cumulative rewards for a particular user
    /// @param account The account for which the computation is performed
    function userRewardPerTokenPaid(address account)
        external
        view
        override
        returns (uint256)
    {
        return IBaseRewardPool(targetContract).userRewardPerTokenPaid(account); // F: [ACVX1_P_13]
    }

    /// @dev Returns the last saved amount of rewards a user is entitled to
    /// @param account The account for which the computation is performed
    function rewards(address account) external view override returns (uint256) {
        return IBaseRewardPool(targetContract).rewards(account); // F: [ACVX1_P_13]
    }

    /// @dev Returns the address of a specific extra reward pool
    /// @param i The index of the extra reward pool
    function extraRewards(uint256 i) external view override returns (address) {
        return IBaseRewardPool(targetContract).extraRewards(i); // F: [ACVX1_P_13]
    }
}