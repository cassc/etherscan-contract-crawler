// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../utils/RateLib.sol";

import "../../../interfaces/ICurve.sol";
import "../../../interfaces/IBooster.sol";
import "../../../interfaces/IBaseRewardPool.sol";

import "../../../interfaces/IStrategy.sol";
import "../../../interfaces/IJPEGIndexStaking.sol";

/// @title JPEG Index convex strategy
contract DAOStrategyConvex is AccessControl, IStrategy {
    using SafeERC20 for IERC20;
    using SafeERC20 for ICurve;
    using RateLib for RateLib.Rate;

    event Harvested(uint256 wantEarned);

    /// @param booster Convex Booster's address
    /// @param baseRewardPool Convex BaseRewardPool's address
    /// @param pid The Convex pool id for PETH/ETH LP tokens
    struct ConvexConfig {
        IBooster booster;
        IBaseRewardPool baseRewardPool;
        uint256 pid;
    }

    /// @param lp The curve LP token
    /// @param ethIndex The eth index in the curve LP pool
    struct CurveConfig {
        ICurve lp;
        uint256 ethIndex;
    }

    struct StrategyTokens {
        ICurve want;
        IERC20 cvx;
        IERC20 crv;
    }

    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    StrategyTokens public strategyTokens;

    address public feeRecipient;

    CurveConfig public cvxEth;
    CurveConfig public crvEth;

    ConvexConfig public convexConfig;
    /// @notice The JPEG Index staking contract
    IJPEGIndexStaking jpegIndexStaking;
    /// @notice The performance fee to be sent to the DAO/strategists
    RateLib.Rate public performanceFee;

    /// @notice lifetime strategy earnings denominated in `eth` tokens
    uint256 public earned;

    /// @param _strategyTokens tokens relevant to this strategy
    /// @param _feeAddress The fee recipient address
    /// @param _cvxEth See {CurveSwapConfig}
    /// @param _crvEth See {CurveSwapConfig}
    /// @param _convexConfig See {ConvexConfig} struct
    /// @param _jpegIndexStaking The JPEG Index staking contract
    /// @param _performanceFee The rate of ETH to be sent to the DAO/strategists
    constructor(
        StrategyTokens memory _strategyTokens,
        address _feeAddress,
        CurveConfig memory _cvxEth,
        CurveConfig memory _crvEth,
        ConvexConfig memory _convexConfig,
        IJPEGIndexStaking _jpegIndexStaking,
        RateLib.Rate memory _performanceFee
    ) {
        require(address(_strategyTokens.want) != address(0), "INVALID_WANT");

        require(address(_strategyTokens.cvx) != address(0), "INVALID_CVX");
        require(address(_strategyTokens.crv) != address(0), "INVALID_CRV");

        require(address(_cvxEth.lp) != address(0), "INVALID_CVXETH_LP");
        require(address(_crvEth.lp) != address(0), "INVALID_CRVETH_LP");
        require(_cvxEth.ethIndex < 2, "INVALID_ETH_INDEX");
        require(_crvEth.ethIndex < 2, "INVALID_ETH_INDEX");

        require(
            address(_convexConfig.booster) != address(0),
            "INVALID_CONVEX_BOOSTER"
        );
        require(
            address(_convexConfig.baseRewardPool) != address(0),
            "INVALID_CONVEX_BASE_REWARD_POOL"
        );
        require(
            address(_jpegIndexStaking) != address(0),
            "INVALID_INDEX_STAKING"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setFeeRecipient(_feeAddress);
        setPerformanceFee(_performanceFee);

        strategyTokens = _strategyTokens;

        feeRecipient = _feeAddress;

        cvxEth = _cvxEth;
        crvEth = _crvEth;

        convexConfig = _convexConfig;
        jpegIndexStaking = _jpegIndexStaking;

        _strategyTokens.want.safeApprove(
            address(_convexConfig.booster),
            type(uint256).max
        );
        _strategyTokens.cvx.safeApprove(address(_cvxEth.lp), type(uint256).max);
        _strategyTokens.crv.safeApprove(address(_crvEth.lp), type(uint256).max);
    }

    receive() external payable {}

    /// @notice Allows the DAO to set the performance fee
    /// @param _performanceFee The new performance fee
    function setPerformanceFee(
        RateLib.Rate memory _performanceFee
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_performanceFee.isValid() || !_performanceFee.isBelowOne())
            revert RateLib.InvalidRate();

        performanceFee = _performanceFee;
    }

    function setFeeRecipient(
        address _newRecipient
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newRecipient != address(0), "INVALID_FEE_RECIPIENT");

        feeRecipient = _newRecipient;
    }

    /// @return The amount of `want` tokens held by this contract
    function heldAssets() public view returns (uint256) {
        return strategyTokens.want.balanceOf(address(this));
    }

    /// @return The amount of `want` tokens deposited in the Convex pool by this contract
    function depositedAssets() public view returns (uint256) {
        return convexConfig.baseRewardPool.balanceOf(address(this));
    }

    /// @return The total amount of `want` tokens this contract manages (held + deposited)
    function totalAssets() external view override returns (uint256) {
        return heldAssets() + depositedAssets();
    }

    /// @notice Allows the admin to deposit all want tokens held by this contract on convex
    function deposit() public override onlyRole(DEFAULT_ADMIN_ROLE) {
        ConvexConfig memory convex = convexConfig;
        convex.booster.depositAll(convex.pid, true);
    }

    /// @notice Allows the admin to deposit want tokens on convex
    function deposit(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        strategyTokens.want.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        deposit();
    }

    /// @notice Strategist only function that allows to withdraw non-strategy tokens (e.g tokens sent accidentally).
    /// CVX and CRV can be withdrawn with this function.
    function withdraw(
        address _to,
        address _asset
    ) external override onlyRole(STRATEGIST_ROLE) {
        require(_to != address(0), "INVALID_ADDRESS");
        require(address(strategyTokens.want) != _asset, "want");

        uint256 balance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransfer(_to, balance);
    }

    /// @notice Allows the owner to withdraw `want` tokens.
    /// @param _to The address to send the tokens to
    /// @param _amount The amount of `want` tokens to withdraw
    function withdraw(
        address _to,
        uint256 _amount
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        ICurve _want = strategyTokens.want;

        uint256 balance = _want.balanceOf(address(this));
        //if the contract doesn't have enough want, withdraw from Convex
        if (balance < _amount) {
            unchecked {
                convexConfig.baseRewardPool.withdrawAndUnwrap(
                    _amount - balance,
                    false
                );
            }
        }

        _want.safeTransfer(_to, _amount);
    }

    /// @notice Allows the owner to withdraw all `want` tokens.
    function withdrawAll() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        ICurve _want = strategyTokens.want;

        convexConfig.baseRewardPool.withdrawAllAndUnwrap(true);

        uint256 balance = _want.balanceOf(address(this));
        _want.safeTransfer(msg.sender, balance);
    }

    /// @notice Allows members of the `STRATEGIST_ROLE` to claim convex rewards, sell them to ETH and distribute them to JPEG Index stakers.
    /// @param minOutETH The minimum amount of ETH to receive
    function harvest(uint256 minOutETH) external onlyRole(STRATEGIST_ROLE) {
        convexConfig.baseRewardPool.getReward(address(this), true);
        uint256 ethBalance;
        //Prevent `Stack too deep` errors
        {
            uint256 cvxBalance = strategyTokens.cvx.balanceOf(address(this));
            if (cvxBalance > 0) {
                CurveConfig memory _cvxEth = cvxEth;
                //minOut is not needed here, we already have it on the Curve deposit
                _cvxEth.lp.exchange(
                    1 - _cvxEth.ethIndex,
                    _cvxEth.ethIndex,
                    cvxBalance,
                    0,
                    true
                );
            }

            uint256 crvBalance = strategyTokens.crv.balanceOf(address(this));
            if (crvBalance > 0) {
                CurveConfig memory _crvEth = crvEth;
                //minOut is not needed here, we already have it on the Curve deposit
                _crvEth.lp.exchange(
                    1 - _crvEth.ethIndex,
                    _crvEth.ethIndex,
                    crvBalance,
                    0,
                    true
                );
            }

            ethBalance = address(this).balance;
            require(ethBalance > minOutETH, "INSUFFICIENT_OUT");
        }

        //take the performance fee
        uint256 fee = (ethBalance * performanceFee.numerator) /
            performanceFee.denominator;

        (bool success, bytes memory result) = feeRecipient.call{ value: fee }(
            ""
        );
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        unchecked {
            ethBalance -= fee;
        }

        jpegIndexStaking.notifyReward{ value: ethBalance }();

        earned += ethBalance;
        emit Harvested(ethBalance);
    }
}