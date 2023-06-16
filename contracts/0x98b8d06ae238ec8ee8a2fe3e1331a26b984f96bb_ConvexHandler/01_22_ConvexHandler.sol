// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IConvexHandler.sol";
import "../interfaces/pools/ILpToken.sol";
import "../interfaces/vendor/IRewardStaking.sol";
import "../interfaces/vendor/IBooster.sol";
import "../interfaces/vendor/IBaseRewardPool.sol";
import "../interfaces/ICurveRegistryCache.sol";
import "../interfaces/IController.sol";

contract ConvexHandler is IConvexHandler {
    using SafeERC20 for IERC20;

    uint256 internal constant _CLIFF_COUNT = 1000;
    uint256 internal constant _CLIFF_SIZE = 100_000e18;
    uint256 internal constant _MAX_CVX_SUPPLY = 100_000_000e18;
    address internal constant _CVX_TOKEN = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

    IController public immutable controller;

    constructor(address _controller) {
        controller = IController(_controller);
    }

    /// @notice Deposits a Curve LP token on Convex and stakes the Convex
    /// Curve LP token in the respective CRV rewards contract on Convex.
    /// @param _curvePool Curve Pool for which LP tokens should be deposited
    /// @param _amount Amount of Curve LP tokens to deposit
    function deposit(address _curvePool, uint256 _amount) external {
        uint256 pid = controller.curveRegistryCache().getPid(_curvePool);
        IBooster(controller.convexBooster()).deposit(pid, _amount, true);
    }

    /// @notice Withdraws Curve LP tokens from Convex.
    /// @dev Curve LP tokens get unstaked from the Convex CRV rewards contract.
    /// @param _curvePool Curve pool for which LP tokens should be withdrawn.
    /// @param _amount Amount of Curve LP tokens to withdraw.
    function withdraw(address _curvePool, uint256 _amount) external {
        address rewardPool = controller.curveRegistryCache().getRewardPool(_curvePool);
        IBaseRewardPool(rewardPool).withdrawAndUnwrap(_amount, true);
    }

    /// @notice Claims CRV, CVX and extra rewards from Convex on behalf of a Root pool.
    /// @param _curvePool Curve pool from which LP tokens have been deposited on Convex.
    /// @param _rootPool Root pool for which rewards will be claimed.
    function claimEarnings(address _curvePool, address _rootPool) external {
        _claimConvexReward(_curvePool, _rootPool);
    }

    /// @notice Claims CRV, CVX and extra rewards from Convex for multiple Curve LP tokens staked.
    /// @param _curvePools List of Curve pools from which LP tokens have been deposited
    /// @param _rootPool Root pool for which rewards will be claimed.
    function claimBatchEarnings(address[] memory _curvePools, address _rootPool) external {
        for (uint256 i; i < _curvePools.length; i++) {
            address pool = _curvePools[i];
            _claimConvexReward(pool, _rootPool);
        }
    }

    function getRewardPool(address _curvePool) public view returns (address) {
        return controller.curveRegistryCache().getRewardPool(_curvePool);
    }

    function _claimConvexReward(address _curvePool, address _rootPool) internal {
        address rewardPool = controller.curveRegistryCache().getRewardPool(_curvePool);
        IBaseRewardPool(rewardPool).getReward(_rootPool, true);
    }

    /// @notice Gets total amount of CRV earned by an account from staking an amount of
    /// Curve LP tokens via Convex for a single Curve pool.
    /// @param _account Account which staked an amount of Curve LP tokens.
    /// @param _curvePool Curve pool for which earned CRV should be computed.
    /// @return Total amount of CRV earned.
    function getCrvEarned(address _account, address _curvePool) public view returns (uint256) {
        address rewardPool = controller.curveRegistryCache().getRewardPool(_curvePool);
        return IBaseRewardPool(rewardPool).earned(_account);
    }

    /// @notice Gets total amount of CRV earned by an account from staking multiple Curve
    /// LP tokens via Convex.
    /// @param _account Account which staked Curve LP tokens.
    /// @param _curvePools List of Curve pools for which earned CRV should be computed.
    /// @return Total amount of CRV earned.
    function getCrvEarnedBatch(address _account, address[] memory _curvePools)
        external
        view
        returns (uint256)
    {
        uint256 totalCrvEarned;
        for (uint256 i; i < _curvePools.length; i++) {
            address pool = _curvePools[i];
            totalCrvEarned += getCrvEarned(_account, pool);
        }
        return totalCrvEarned;
    }

    /// @notice Computes how much CVX can be claimed for an amount of CRV earned
    /// @dev Not easily computable from the CVX token contract
    /// @param crvAmount Amount of CRV for which CVX will be minted pro rata.
    /// @return CVX amount that would be minted.
    function computeClaimableConvex(uint256 crvAmount) external view returns (uint256) {
        uint256 cvxTotalSupply = IERC20(_CVX_TOKEN).totalSupply();
        uint256 cliff = cvxTotalSupply / _CLIFF_SIZE;
        if (cliff >= _CLIFF_COUNT) {
            return 0;
        }
        uint256 remaining = _CLIFF_COUNT - cliff;
        uint256 cvxEarned = (crvAmount * remaining) / _CLIFF_COUNT;
        uint256 amountTillMax = _MAX_CVX_SUPPLY - cvxTotalSupply;
        if (cvxEarned > amountTillMax) {
            cvxEarned = amountTillMax;
        }
        return cvxEarned;
    }
}