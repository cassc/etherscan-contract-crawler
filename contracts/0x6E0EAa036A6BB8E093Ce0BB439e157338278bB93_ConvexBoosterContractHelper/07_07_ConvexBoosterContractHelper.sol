// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IStrategyContractHelper.sol";

import "../../external/interfaces/convex/IBooster.sol";
import "../../external/interfaces/convex/IBaseRewardPool.sol";

/**
 * @notice Convex booster contract helper
 */
contract ConvexBoosterContractHelper is IStrategyContractHelper {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice Spool contract
    address public immutable spool;
    /// @notice Booster contract
    IBooster public immutable booster;
    /// @notice Booster pool id
    uint256 public immutable pid;
    /// @notice Reward pool contract
    IBaseRewardPool public immutable crvRewards;
    /// @notice LP Token contract
    IERC20 public immutable lpToken;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Set initial values
     * @param _spool Spool contract
     * @param _booster Booster contract
     * @param _boosterPoolId Booster pool id
     */
    constructor(
        address _spool,
        IBooster _booster,
        uint256 _boosterPoolId
    ) {
        require(_spool != address(0), "ConvexBoosterContractHelper::constructor: Spool address cannot be 0");
        require(address(_booster) != address(0), "ConvexBoosterContractHelper::constructor: Booster address cannot be 0");
        
        spool = _spool;
        booster = _booster;
        pid = _boosterPoolId;

        IBooster.PoolInfo memory cvxPool = _booster.poolInfo(_boosterPoolId);        
        crvRewards = IBaseRewardPool(cvxPool.crvRewards);
        lpToken = IERC20(cvxPool.lptoken);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Claim rewards
     * @param rewardTokens Reward tokens to claim
     * @param executeClaim true to swap rewards to underlying
     * @return rewardTokenAmounts claimed token amount
     * @return didClaimNewRewards flag if new rewards were claimed
     */
    function claimRewards(
        address[] memory rewardTokens,
        bool executeClaim
    )
        external
        override
        onlySpool
    returns(
        uint256[] memory rewardTokenAmounts,
        bool didClaimNewRewards
    )
    {
        if (executeClaim) {
            crvRewards.getReward();
        }

        rewardTokenAmounts = new uint256[](rewardTokens.length);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            rewardTokenAmounts[i] = IERC20(rewardTokens[i]).balanceOf(address(this));

            if (rewardTokenAmounts[i] > 0) {
                IERC20(rewardTokens[i]).safeTransfer(msg.sender, rewardTokenAmounts[i]);
                didClaimNewRewards = true;
            }
        }
    }

    /**
     * @notice Deposit
     * Requirements:
     *  - Caller must be main spool contract
     * @param lp Amount of lp tokens to deposit
     */
    function deposit(uint256 lp) external override onlySpool {
        lpToken.safeApprove(address(booster), lp);
        booster.deposit(pid, lp, true);

        if (lpToken.allowance(address(this), address(booster)) > 0) {
            lpToken.safeApprove(address(booster), 0);
        }
    }

    /**
     * @notice Withdraw
     * Requirements:
     *  - Caller must be main spool contract
     * @param lp Amount of LP tokens to withdraw
     */
    function withdraw(uint256 lp) external override onlySpool {
        crvRewards.withdrawAndUnwrap(lp, false);
        lpToken.safeTransfer(msg.sender, lp);
    }

    /**
     * @notice Withdraw all
     * Requirements:
     *  - Caller must be main spool contract
     */
    function withdrawAll() external override onlySpool {
        crvRewards.withdrawAllAndUnwrap(false);
        lpToken.safeTransfer(msg.sender, lpToken.balanceOf(address(this)));
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Throws if caller is not main spool contract
     */
    function _onlySpool() private view {
        require(msg.sender == spool, "ConvexBoosterContractHelper::_onlySpool: Caller is not the Spool contract");
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Throws if caller is not main spool contract
     */
    modifier onlySpool() {
        _onlySpool();
        _;
    }
}