// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../utils/RateLib.sol";

import "../../../interfaces/ICurve.sol";
import "../../../interfaces/I3CRVZap.sol";
import "../../../interfaces/IBooster.sol";
import "../../../interfaces/IBaseRewardPool.sol";

import "../../../interfaces/IPETHVaultForDAO.sol";

import "../../../interfaces/IStrategy.sol";

/// @title JPEG'd PEWTH Convex autocompounding strategy
/// @notice This strategy autocompounds Convex rewards from the PETH/ETH Curve pool.
/// @dev The strategy deposits either ETH or PETH in the Curve pool depending on which one has lower liquidity.
/// The strategy sells reward tokens for ETH. If the pool has less PETH than ETH, this contract uses the
/// ETH to mint PETH
contract StrategyPETHConvex is AccessControl, IStrategy {
    using SafeERC20 for IERC20;
    using SafeERC20 for ICurve;
    using RateLib for RateLib.Rate;

    error ZeroAddress();

    event Harvested(uint256 wantEarned);

    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    ICurve public immutable WANT;

    IERC20 public immutable CVX;
    IERC20 public immutable CRV;

    ICurve public immutable CVX_ETH;
    ICurve public immutable CRV_ETH;

    IBooster public immutable CVX_BOOSTER;
    IBaseRewardPool public immutable REWARD_POOL;
    uint256 public immutable CVX_PETH_PID;

    address public feeRecipient;

    /// @notice The performance fee to be sent to the DAO/strategists
    RateLib.Rate public performanceFee;

    /// @notice lifetime strategy earnings denominated in `want` token
    uint256 public earned;

    constructor(
        address _want,
        address _cvx,
        address _crv,
        address _cvxETH,
        address _crvETH,
        address _booster,
        address _rewardPool,
        uint256 _pid,
        address _feeAddress,
        RateLib.Rate memory _performanceFee
    ) {
        if (
            _want == address(0) ||
            _cvx == address(0) ||
            _crv == address(0) ||
            _cvxETH == address(0) ||
            _crvETH == address(0) ||
            _booster == address(0) ||
            _rewardPool == address(0) ||
            _feeAddress == address(0)
        ) revert ZeroAddress();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setFeeRecipient(_feeAddress);
        setPerformanceFee(_performanceFee);

        WANT = ICurve(_want);

        CVX = IERC20(_cvx);
        CRV = IERC20(_crv);

        CVX_ETH = ICurve(_cvxETH);
        CRV_ETH = ICurve(_crvETH);

        CVX_BOOSTER = IBooster(_booster);
        REWARD_POOL = IBaseRewardPool(_rewardPool);
        CVX_PETH_PID = _pid;

        IERC20(_want).safeApprove(_booster, type(uint256).max);
        IERC20(_cvx).safeApprove(_cvxETH, type(uint256).max);
        IERC20(_crv).safeApprove(_crvETH, type(uint256).max);
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
        if (_newRecipient == address(0)) revert ZeroAddress();

        feeRecipient = _newRecipient;
    }

    /// @return The amount of `want` tokens held by this contract
    function heldAssets() public view returns (uint256) {
        return WANT.balanceOf(address(this));
    }

    /// @return The amount of `want` tokens deposited in the Convex pool by this contract
    function depositedAssets() public view returns (uint256) {
        return REWARD_POOL.balanceOf(address(this));
    }

    /// @return The total amount of `want` tokens this contract manages (held + deposited)
    function totalAssets() external view override returns (uint256) {
        return heldAssets() + depositedAssets();
    }

    /// @notice Allows anyone to deposit the total amount of `want` tokens in this contract into Convex
    function deposit() public override {
        CVX_BOOSTER.depositAll(CVX_PETH_PID, true);
    }

    /// @notice Controller only function that allows to withdraw non-strategy tokens (e.g tokens sent accidentally).
    /// CVX and CRV can be withdrawn with this function.
    function withdraw(
        address _to,
        address _asset
    ) external override onlyRole(STRATEGIST_ROLE) {
        if (_to == address(0)) revert ZeroAddress();

        if (_asset == address(WANT)) revert();

        uint256 _balance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransfer(_to, _balance);
    }

    /// @notice Allows the controller to withdraw `want` tokens. Normally used with a vault withdrawal
    /// @param _to The address to send the tokens to
    /// @param _amount The amount of `want` tokens to withdraw
    function withdraw(
        address _to,
        uint256 _amount
    ) external override onlyRole(VAULT_ROLE) {
        uint256 _balance = WANT.balanceOf(address(this));
        //if the contract doesn't have enough want, withdraw from Convex
        if (_balance < _amount) {
            unchecked {
                REWARD_POOL.withdrawAndUnwrap(_amount - _balance, false);
            }
        }

        WANT.safeTransfer(_to, _amount);
    }

    /// @notice Allows the controller to withdraw all `want` tokens. Normally used when migrating strategies
    function withdrawAll() external override onlyRole(VAULT_ROLE) {
        REWARD_POOL.withdrawAllAndUnwrap(true);

        uint256 _balance = WANT.balanceOf(address(this));
        WANT.safeTransfer(msg.sender, _balance);
    }

    /// @notice Allows members of the `STRATEGIST_ROLE` to compound Convex rewards into Curve
    /// @param _minOutCurve The minimum amount of `want` tokens to receive
    function harvest(uint256 _minOutCurve) external onlyRole(STRATEGIST_ROLE) {
        REWARD_POOL.getReward(address(this), true);

        //Prevent `Stack too deep` errors
        {
            uint256 _cvxBalance = CVX.balanceOf(address(this));
            if (_cvxBalance > 0)
                //minOut is not needed here, we already have it on the Curve deposit
                CVX_ETH.exchange(1, 0, _cvxBalance, 0, true);

            uint256 _crvBalance = CRV.balanceOf(address(this));
            if (_crvBalance > 0)
                //minOut is not needed here, we already have it on the Curve deposit
                CRV_ETH.exchange(1, 0, _crvBalance, 0, true);

            if (address(this).balance == 0) revert();
        }

        //take the performance fee
        uint256 _fee = (address(this).balance * performanceFee.numerator) /
            performanceFee.denominator;

        (bool _success, bytes memory _result) = feeRecipient.call{
            value: _fee
        }("");
        if (!_success) {
            assembly {
                revert(add(_result, 32), mload(_result))
            }
        }

        WANT.add_liquidity{ value: address(this).balance }(
            [address(this).balance, 0],
            _minOutCurve
        );

        uint256 _wantBalance = heldAssets();

        deposit();

        earned += _wantBalance;
        emit Harvested(_wantBalance);
    }
}