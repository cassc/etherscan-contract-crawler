// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import { IEuler, IEulerMarkets, IEulerEToken, IEulerDToken, IBaseIRM } from "../../../../interfaces/external/euler/IEuler.sol";
import "../../../../external/ComputePower.sol";
import "./../GenericLenderBaseUpgradeable.sol";

/// @title GenericEuler
/// @author Angle Core Team
/// @notice Simple supplier to Euler markets
contract GenericEuler is GenericLenderBaseUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @notice Base used for interest rate / power computation
    // solhint-disable-next-line
    uint256 private constant BASE_INTEREST = 10**27;

    /// @notice Euler address holding assets
    // solhint-disable-next-line
    IEuler private constant _euler = IEuler(0x27182842E098f60e3D576794A5bFFb0777E025d3);
    /// @notice Euler address with data on all eTokens, debt tokens and interest rates
    // solhint-disable-next-line
    IEulerMarkets private constant _eulerMarkets = IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);
    // solhint-disable-next-line
    uint256 internal constant _SECONDS_IN_YEAR = 365 days;
    // solhint-disable-next-line
    uint256 private constant RESERVE_FEE_SCALE = 4_000_000_000;

    // ========================== REFERENCES TO CONTRACTS ==========================

    /// @notice Euler interest rate model for the desired token
    // solhint-disable-next-line
    IBaseIRM private irm;
    /// @notice Euler debt token
    // solhint-disable-next-line
    IEulerDToken private dToken;
    /// @notice Token given to lenders on Euler
    IEulerEToken public eToken;
    /// @notice Reserve fee on the token on Euler
    uint32 public reserveFee;

    // ================================ CONSTRUCTOR ================================

    /// @notice Initializer of the `GenericEuler`
    /// @param _strategy Reference to the strategy using this lender
    /// @param governorList List of addresses with governor privilege
    /// @param keeperList List of addresses with keeper privilege
    /// @param guardian Address of the guardian
    function initializeEuler(
        address _strategy,
        string memory _name,
        address[] memory governorList,
        address guardian,
        address[] memory keeperList,
        address oneInch_
    ) public {
        _initialize(_strategy, _name, governorList, guardian, keeperList, oneInch_);

        eToken = IEulerEToken(_eulerMarkets.underlyingToEToken(address(want)));
        dToken = IEulerDToken(_eulerMarkets.underlyingToDToken(address(want)));

        _setEulerPoolVariables();

        want.safeApprove(address(_euler), type(uint256).max);
    }

    // ===================== EXTERNAL PERMISSIONLESS FUNCTIONS =====================

    /// @notice Retrieves Euler variables `reserveFee` and the `irm` - rates curve -  used for the underlying token
    /// @dev No access control is needed here because values are fetched from Euler directly
    /// @dev We expect the values concerned not to be modified often
    function setEulerPoolVariables() external {
        _setEulerPoolVariables();
    }

    // ======================== EXTERNAL STRATEGY FUNCTIONS ========================

    /// @inheritdoc IGenericLender
    function deposit() external override onlyRole(STRATEGY_ROLE) {
        uint256 balance = want.balanceOf(address(this));
        eToken.deposit(0, balance);
        // We don't stake balance but the whole eToken balance
        // if some dust has been kept idle
        _stakeAll();
    }

    /// @inheritdoc IGenericLender
    function withdraw(uint256 amount) external override onlyRole(STRATEGY_ROLE) returns (uint256) {
        return _withdraw(amount);
    }

    /// @inheritdoc IGenericLender
    function withdrawAll() external override onlyRole(STRATEGY_ROLE) returns (bool) {
        uint256 invested = _nav();
        uint256 returned = _withdraw(invested);
        return returned >= invested;
    }

    // ========================== EXTERNAL VIEW FUNCTIONS ==========================

    /// @inheritdoc GenericLenderBaseUpgradeable
    function underlyingBalanceStored() public view override returns (uint256) {
        uint256 stakeAmount = _stakedBalance();
        return eToken.balanceOfUnderlying(address(this)) + stakeAmount;
    }

    /// @inheritdoc IGenericLender
    function aprAfterDeposit(int256 amount) external view override returns (uint256) {
        return _aprAfterDeposit(amount);
    }

    // ================================= GOVERNANCE ================================

    /// @inheritdoc IGenericLender
    function emergencyWithdraw(uint256 amount) external override onlyRole(GUARDIAN_ROLE) {
        _unstake(amount);
        eToken.withdraw(0, amount);
        want.safeTransfer(address(poolManager), want.balanceOf(address(this)));
    }

    // ============================= INTERNAL FUNCTIONS ============================

    /// @inheritdoc GenericLenderBaseUpgradeable
    function _apr() internal view override returns (uint256) {
        return _aprAfterDeposit(0);
    }

    /// @notice Internal version of the `aprAfterDeposit` function
    function _aprAfterDeposit(int256 amount) internal view returns (uint256) {
        uint256 totalBorrows = dToken.totalSupply();
        // Total supply is current supply + added liquidity

        uint256 totalSupply = eToken.totalSupplyUnderlying();
        if (amount >= 0) totalSupply += uint256(amount);
        else totalSupply -= uint256(-amount);

        uint256 supplyAPY;
        if (totalSupply != 0) {
            uint32 futureUtilisationRate = uint32(
                (totalBorrows * (uint256(type(uint32).max) * 1e18)) / totalSupply / 1e18
            );
            uint256 interestRate = uint256(uint96(irm.computeInterestRate(address(want), futureUtilisationRate)));
            supplyAPY = _computeAPYs(interestRate, totalBorrows, totalSupply, reserveFee);
        }

        // Adding the yield from EUL
        return supplyAPY + _stakingApr(amount);
    }

    /// @notice Computes APYs based on the interest rate, reserve fee, borrow
    /// @param borrowSPY Interest rate paid per second by borrowers
    /// @param totalBorrows Total amount borrowed on Euler of the underlying token
    /// @param totalSupplyUnderlying Total amount supplied on Euler of the underlying token
    /// @param _reserveFee Reserve fee set by governance for the underlying token
    /// @return supplyAPY The annual percentage yield received as a supplier with current settings
    function _computeAPYs(
        uint256 borrowSPY,
        uint256 totalBorrows,
        uint256 totalSupplyUnderlying,
        uint32 _reserveFee
    ) internal pure returns (uint256 supplyAPY) {
        // Not useful for the moment
        // uint256 borrowAPY = (ComputePower.computePower(borrowSPY, _SECONDS_IN_YEAR) - ComputePower.BASE_INTEREST) / 1e9;
        uint256 supplySPY = (borrowSPY * totalBorrows) / totalSupplyUnderlying;
        supplySPY = (supplySPY * (RESERVE_FEE_SCALE - _reserveFee)) / RESERVE_FEE_SCALE;
        // All rates are in base 18 on Angle strategies
        supplyAPY = (ComputePower.computePower(supplySPY, _SECONDS_IN_YEAR, BASE_INTEREST) - BASE_INTEREST) / 1e9;
    }

    /// @notice See `withdraw`
    function _withdraw(uint256 amount) internal returns (uint256) {
        uint256 stakedBalance = _stakedBalance();
        uint256 balanceUnderlying = eToken.balanceOfUnderlying(address(this));
        uint256 looseBalance = want.balanceOf(address(this));
        uint256 total = stakedBalance + balanceUnderlying + looseBalance;

        if (amount > total) {
            // Can't withdraw more than we own
            amount = total;
        }

        if (looseBalance >= amount) {
            want.safeTransfer(address(strategy), amount);
            return amount;
        }

        // Not state changing but still cheap because of previous call
        uint256 availableLiquidity = want.balanceOf(address(_euler));

        if (availableLiquidity > 1) {
            uint256 toWithdraw = amount - looseBalance;
            uint256 toUnstake;
            // We can take all
            if (toWithdraw <= availableLiquidity)
                toUnstake = toWithdraw > balanceUnderlying ? toWithdraw - balanceUnderlying : 0;
            else {
                // Take all we can
                toUnstake = availableLiquidity > balanceUnderlying ? availableLiquidity - balanceUnderlying : 0;
                toWithdraw = availableLiquidity;
            }
            if (toUnstake != 0) _unstake(toUnstake);
            eToken.withdraw(0, toWithdraw);
        }

        looseBalance = want.balanceOf(address(this));
        want.safeTransfer(address(strategy), looseBalance);
        return looseBalance;
    }

    /// @notice Internal version of the `setEulerPoolVariables`
    function _setEulerPoolVariables() internal {
        uint256 interestRateModel = _eulerMarkets.interestRateModel(address(want));
        address moduleImpl = _euler.moduleIdToImplementation(interestRateModel);
        irm = IBaseIRM(moduleImpl);
        reserveFee = _eulerMarkets.reserveFee(address(want));
    }

    /// @inheritdoc GenericLenderBaseUpgradeable
    function _protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(want);
        protected[1] = address(eToken);
        return protected;
    }

    // ============================= VIRTUAL FUNCTIONS =============================

    /// @notice Allows the lender to stake its eTokens in an external staking contract
    function _stakeAll() internal virtual {}

    /// @notice Allows the lender to unstake its eTokens from an external staking contract
    /// @return Amount of eTokens actually unstaked
    function _unstake(uint256) internal virtual returns (uint256) {
        return 0;
    }

    /// @notice Gets the value of the eTokens currently staked
    function _stakedBalance() internal view virtual returns (uint256) {
        return (0);
    }

    /// @notice Calculates APR from Liquidity Mining Program
    /// @dev amountToAdd Amount to add to the currently supplied liquidity (for the `aprAfterDeposit` function)
    function _stakingApr(int256) internal view virtual returns (uint256) {
        return 0;
    }
}