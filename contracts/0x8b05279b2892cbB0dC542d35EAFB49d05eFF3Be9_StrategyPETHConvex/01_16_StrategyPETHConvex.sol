// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

    event Harvested(uint256 wantEarned);

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

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

    /// @param vault The strategy's vault
    /// @param ethVault The JPEG'd ETH vault address
    struct StrategyConfig {
        address vault;
        IPETHVaultForDAO ethVault;
    }

    struct StrategyTokens {
        ICurve want;
        IERC20 peth;
        IERC20 cvx;
        IERC20 crv;
    }

    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    StrategyTokens public strategyTokens;

    address public feeRecipient;

    CurveConfig public cvxEth;
    CurveConfig public crvEth;
    CurveConfig public pethEth;

    ConvexConfig public convexConfig;
    StrategyConfig public strategyConfig;

    /// @notice The performance fee to be sent to the DAO/strategists
    Rate public performanceFee;

    /// @notice lifetime strategy earnings denominated in `want` token
    uint256 public earned;

    /// @param _strategyTokens tokens relevant to this strategy
    /// @param _feeAddress The fee recipient address
    /// @param _cvxEth See {CurveSwapConfig}
    /// @param _crvEth See {CurveSwapConfig}
    /// @param _convexConfig See {ConvexConfig} struct
    /// @param _strategyConfig See {StrategyConfig} struct
    /// @param _performanceFee The rate of ETH to be sent to the DAO/strategists
    constructor(
        StrategyTokens memory _strategyTokens,
        address _feeAddress,
        CurveConfig memory _cvxEth,
        CurveConfig memory _crvEth,
        CurveConfig memory _pethEth,
        ConvexConfig memory _convexConfig,
        StrategyConfig memory _strategyConfig,
        Rate memory _performanceFee
    ) {
        require(address(_strategyTokens.want) != address(0), "INVALID_WANT");
        require(address(_strategyTokens.peth) != address(0), "INVALID_PETH");

        require(address(_strategyTokens.cvx) != address(0), "INVALID_CVX");
        require(address(_strategyTokens.crv) != address(0), "INVALID_CRV");

        require(address(_cvxEth.lp) != address(0), "INVALID_CVXETH_LP");
        require(address(_crvEth.lp) != address(0), "INVALID_CRVETH_LP");
        require(address(_pethEth.lp) != address(0), "INVALID_PETHETH_LP");
        require(_cvxEth.ethIndex < 2, "INVALID_ETH_INDEX");
        require(_crvEth.ethIndex < 2, "INVALID_ETH_INDEX");
        require(_pethEth.ethIndex < 2, "INVALID_ETH_INDEX");

        require(
            address(_convexConfig.booster) != address(0),
            "INVALID_CONVEX_BOOSTER"
        );
        require(
            address(_convexConfig.baseRewardPool) != address(0),
            "INVALID_CONVEX_BASE_REWARD_POOL"
        );
        require(address(_strategyConfig.vault) != address(0), "INVALID_VAULT");
        require(
            address(_strategyConfig.ethVault) != address(0),
            "INVALID_ETH_VAULT"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setFeeRecipient(_feeAddress);
        setPerformanceFee(_performanceFee);

        strategyTokens = _strategyTokens;

        feeRecipient = _feeAddress;

        cvxEth = _cvxEth;
        crvEth = _crvEth;
        pethEth = _pethEth;

        convexConfig = _convexConfig;
        strategyConfig = _strategyConfig;

        _strategyTokens.want.safeApprove(
            address(_convexConfig.booster),
            type(uint256).max
        );
        _strategyTokens.cvx.safeApprove(address(_cvxEth.lp), type(uint256).max);
        _strategyTokens.crv.safeApprove(address(_crvEth.lp), type(uint256).max);
        _strategyTokens.peth.safeApprove(
            address(_pethEth.lp),
            type(uint256).max
        );
    }

    modifier onlyVault() {
        require(msg.sender == address(strategyConfig.vault), "NOT_VAULT");
        _;
    }

    receive() external payable {
    }

    /// @notice Allows the DAO to set the performance fee
    /// @param _performanceFee The new performance fee
    function setPerformanceFee(Rate memory _performanceFee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _performanceFee.denominator != 0 &&
                _performanceFee.denominator >= _performanceFee.numerator,
            "INVALID_RATE"
        );
        performanceFee = _performanceFee;
    }

    /// @notice Allows the DAO to set the ETH vault
    /// @param _vault The new ETH vault
    function setETHVault(address _vault)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_vault != address(0), "INVALID_ETH_VAULT");
        strategyConfig.ethVault = IPETHVaultForDAO(_vault);
    }

    function setFeeRecipient(address _newRecipient)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
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

    /// @notice Allows anyone to deposit the total amount of `want` tokens in this contract into Convex
    function deposit() public override {
        ConvexConfig memory convex = convexConfig;
        convex.booster.depositAll(convex.pid, true);
    }

    /// @notice Controller only function that allows to withdraw non-strategy tokens (e.g tokens sent accidentally).
    /// CVX and CRV can be withdrawn with this function.
    function withdraw(address _to, address _asset)
        external
        override
        onlyRole(STRATEGIST_ROLE)
    {
        require(_to != address(0), "INVALID_ADDRESS");
        require(address(strategyTokens.want) != _asset, "want");
        require(address(strategyTokens.peth) != _asset, "peth");

        uint256 balance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransfer(_to, balance);
    }

    /// @notice Allows the controller to withdraw `want` tokens. Normally used with a vault withdrawal
    /// @param _to The address to send the tokens to
    /// @param _amount The amount of `want` tokens to withdraw
    function withdraw(address _to, uint256 _amount)
        external
        override
        onlyVault
    {
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

    /// @notice Allows the controller to withdraw all `want` tokens. Normally used when migrating strategies
    function withdrawAll() external override onlyVault {
        ICurve _want = strategyTokens.want;

        convexConfig.baseRewardPool.withdrawAllAndUnwrap(true);

        uint256 balance = _want.balanceOf(address(this));
        _want.safeTransfer(msg.sender, balance);
    }

    /// @notice Allows members of the `STRATEGIST_ROLE` to compound Convex rewards into Curve
    /// @param minOutCurve The minimum amount of `want` tokens to receive
    function harvest(uint256 minOutCurve) external onlyRole(STRATEGIST_ROLE) {
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
            require(ethBalance != 0, "NOOP");

        }

        StrategyConfig memory strategy = strategyConfig;

        //take the performance fee
        uint256 fee = (ethBalance * performanceFee.numerator) /
            performanceFee.denominator;

        (bool success, bytes memory result) = feeRecipient.call{value: fee}("");
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        
        unchecked {
            ethBalance -= fee;
        }

        ICurve _want = strategyTokens.want;
        CurveConfig memory _pethEth = pethEth;

        uint256 pethCurveBalance = _want.balances(1 - _pethEth.ethIndex);
        uint256 ethCurveBalance = _want.balances(_pethEth.ethIndex);

        //The curve pool has 2 tokens, we are doing a single asset deposit with either PETH or ETH
        uint256[2] memory liquidityAmounts = [uint256(0), 0];
        if (ethCurveBalance > pethCurveBalance) {
            //if there's more ETH than PETH in the pool, use ETH as collateral to mint PETH
            //and deposit it into the Curve pool
            strategy.ethVault.deposit{value: ethBalance}();

            strategy.ethVault.borrow(ethBalance);
            liquidityAmounts[1 - _pethEth.ethIndex] = ethBalance;
        } else {
            //if there's more PETH than ETH in the pool, deposit ETH
            liquidityAmounts[_pethEth.ethIndex] = ethBalance;
        }

        _pethEth.lp.add_liquidity{value: liquidityAmounts[_pethEth.ethIndex]}(liquidityAmounts, minOutCurve);

        uint256 wantBalance = heldAssets();

        deposit();

        earned += wantBalance;
        emit Harvested(wantBalance);
    }
}