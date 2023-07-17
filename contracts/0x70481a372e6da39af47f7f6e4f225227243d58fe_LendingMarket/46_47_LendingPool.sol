// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IAddressProvider} from "../../interfaces/IAddressProvider.sol";
import {IInterestRate} from "../../interfaces/IInterestRate.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ConfigTypes} from "../../libraries/types/ConfigTypes.sol";
import {ILendingMarket} from "../../interfaces/ILendingMarket.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title LendingPool contract
/// @author leNFT
/// @notice Vault used to store lending liquidity and handle deposits and withdrawals
/// @dev The LendingPool contract uses the ERC4626 contract to track the shares in a liquidity pool held by users
contract LendingPool is ERC165, ILendingPool, ERC4626, Ownable {
    uint256 private constant MININUM_DEPOSIT_EMPTY_VAULT = 1e10;
    IAddressProvider private immutable _addressProvider;
    uint256 private _debt;
    uint256 private _borrowRate;
    uint256 private _cumulativeDebtBorrowRate;
    bool private _paused;
    ConfigTypes.LendingPoolConfig private _lendingPoolConfig;

    using SafeERC20 for IERC20;

    modifier onlyMarket() {
        _requireOnlyMarket();
        _;
    }

    modifier poolNotPaused() {
        _requirePoolNotPaused();
        _;
    }

    /// @notice Constructor to initialize the lending pool contract
    /// @param addressProvider the address provider contract
    /// @param owner the owner of the contract
    /// @param asset the underlying asset of the lending pool
    /// @param name the name of the ERC20 token
    /// @param symbol the symbol of the ERC20 token
    /// @param lendingPoolConfig the configuration parameters for the lending pool
    constructor(
        IAddressProvider addressProvider,
        address owner,
        address asset,
        string memory name,
        string memory symbol,
        ConfigTypes.LendingPoolConfig memory lendingPoolConfig
    ) ERC20(name, symbol) ERC4626(IERC20(asset)) {
        require(
            msg.sender == addressProvider.getLendingMarket(),
            "LP:C:ONLY_MARKET"
        );
        _addressProvider = addressProvider;
        _lendingPoolConfig = lendingPoolConfig;
        _updateBorrowRate();
        _transferOwnership(owner);
    }

    /// @notice Get the number of decimals for the underlying asset
    /// @return the number of decimals
    function decimals() public view override(ERC4626) returns (uint8) {
        return ERC4626.decimals();
    }

    /// @notice Get the balance of the underlying asset held in the contract
    /// @return the balance of the underlying asset
    function getUnderlyingBalance() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    /// @notice Get the total assets of the lending pool
    /** @dev See {IERC4626-totalAssets}. */
    /// @return the total assets of the contract (debt + underlying balance)
    function totalAssets() public view override returns (uint256) {
        return _debt + getUnderlyingBalance();
    }

    /// @notice Deposit underlying asset to the contract and mint ERC20 tokens
    /// @param caller the caller of the function
    /// @param receiver the recipient of the ERC20 tokens
    /// @param assets the amount of underlying asset to deposit
    /// @param shares the amount of ERC20 tokens to mint
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override poolNotPaused {
        // Check deposit amount. Minimum deposit is 1e10 if the vault is empty to avoid inflation attacks
        if (totalSupply() == 0) {
            require(assets >= MININUM_DEPOSIT_EMPTY_VAULT, "VL:VD:MIN_DEPOSIT");
        } else {
            require(assets > 0, "VL:VD:AMOUNT_0");
        }

        // Check if pool will exceed maximum permitted amount
        require(
            assets + totalAssets() <
                ILendingMarket(_addressProvider.getLendingMarket())
                    .getTVLSafeguard(),
            "VL:VD:SAFEGUARD_EXCEEDED"
        );

        ERC4626._deposit(caller, receiver, assets, shares);

        _updateBorrowRate();
    }

    /// @notice Withdraw underlying asset from the contract and burn ERC20 tokens
    /// @param caller the caller of the function
    /// @param receiver the recipient of the underlying asset
    /// @param owner the owner of the ERC20 tokens
    /// @param assets the amount of underlying asset to withdraw
    /// @param shares the amount of ERC20 tokens to burn
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        // Check if withdrawal amount is bigger than 0
        require(assets > 0, "VL:VW:AMOUNT_0");

        // Check if the utilization rate doesn't go above maximum
        require(
            IInterestRate(_addressProvider.getInterestRate())
                .calculateUtilizationRate(
                    asset(),
                    IERC20(asset()).balanceOf(address(this)) - assets,
                    _debt
                ) <= _lendingPoolConfig.maxUtilizationRate,
            "VL:VW:MAX_UTILIZATION_RATE"
        );

        ERC4626._withdraw(caller, receiver, owner, assets, shares);

        _updateBorrowRate();
    }

    /// @notice Transfer the underlying asset to a recipient
    /// @param to the recipient of the underlying asset
    /// @param amount the amount of underlying asset to transfer
    /// @param borrowRate the borrow rate at the time of transfer
    function transferUnderlying(
        address to,
        uint256 amount,
        uint256 borrowRate
    ) external override onlyMarket poolNotPaused {
        // Send the underlying to user
        IERC20(asset()).safeTransfer(to, amount);

        // Update the cummulative borrow rate
        _updateCumulativeDebtBorrowRate(true, amount, borrowRate);

        // Update the debt
        _debt += amount;

        // Update the borrow rate
        _updateBorrowRate();
    }

    /// @notice Transfers `amount` of underlying asset and `interest` from `from` to the pool, updates the cumulative debt borrow rate, and updates the borrow rate.
    /// @param from The address from which the underlying asset and interest will be transferred.
    /// @param amount The amount of underlying asset to transfer.
    /// @param borrowRate The current borrow rate.
    /// @param interest The amount of interest to transfer.
    function receiveUnderlying(
        address from,
        uint256 amount,
        uint256 borrowRate,
        uint256 interest
    ) external override onlyMarket poolNotPaused {
        IERC20(asset()).safeTransferFrom(
            from,
            address(this),
            amount + interest
        );
        _updateCumulativeDebtBorrowRate(false, amount, borrowRate);
        _debt -= amount;
        _updateBorrowRate();
    }

    /// @notice Transfers `amount` of underlying asset from `from` to the pool, updates the cumulative debt borrow rate, and updates the borrow rate. The debt is decreased by `defaultedDebt`.
    /// @param from The address from which the underlying asset will be transferred.
    /// @param amount The amount of underlying asset to transfer.
    /// @param borrowRate The current borrow rate.
    /// @param defaultedDebt The defaulted debt to subtract from the debt.

    function receiveUnderlyingDefaulted(
        address from,
        uint256 amount,
        uint256 borrowRate,
        uint256 defaultedDebt
    ) external override onlyMarket poolNotPaused {
        IERC20(asset()).safeTransferFrom(from, address(this), amount);
        _updateCumulativeDebtBorrowRate(false, defaultedDebt, borrowRate);
        _debt -= defaultedDebt;
        _updateBorrowRate();
    }

    /// @notice Returns the current borrow rate.
    /// @return The current borrow rate.
    function getBorrowRate() external view override returns (uint256) {
        return _borrowRate;
    }

    /// @notice Updates the current borrow rate.
    function _updateBorrowRate() internal {
        _borrowRate = IInterestRate(
            IAddressProvider(_addressProvider).getInterestRate()
        ).calculateBorrowRate(asset(), getUnderlyingBalance(), _debt);

        emit UpdatedBorrowRate(_borrowRate);
    }

    /// @notice Updates the cumulative debt borrow rate by adding or subtracting `amount` at `borrowRate`, depending on `increaseDebt`. If the debt reaches zero, the cumulative debt borrow rate is set to zero.
    /// @param increaseDebt Whether to increase or decrease the debt.
    /// @param amount The amount of debt to add or subtract.
    /// @param borrowRate The current borrow rate.
    function _updateCumulativeDebtBorrowRate(
        bool increaseDebt,
        uint256 amount,
        uint256 borrowRate
    ) internal {
        if (increaseDebt) {
            _cumulativeDebtBorrowRate =
                ((_debt * _cumulativeDebtBorrowRate) + (amount * borrowRate)) /
                (_debt + amount);
        } else {
            if ((_debt - amount) == 0) {
                _cumulativeDebtBorrowRate = 0;
            } else {
                _cumulativeDebtBorrowRate =
                    ((_debt * _cumulativeDebtBorrowRate) -
                        (amount * borrowRate)) /
                    (_debt - amount);
            }
        }
    }

    /// @notice Returns the current supply rate.
    /// @return supplyRate The current supply rate.
    function getSupplyRate()
        external
        view
        override
        returns (uint256 supplyRate)
    {
        if (totalAssets() > 0) {
            supplyRate = (_cumulativeDebtBorrowRate * _debt) / totalAssets();
        }
    }

    /// @notice Returns the current debt.
    /// @return The current debt.
    function getDebt() external view override returns (uint256) {
        return _debt;
    }

    /// @notice Returns the current utilization rate.
    /// @return The current utilization rate.
    function getUtilizationRate() external view override returns (uint256) {
        return
            IInterestRate(_addressProvider.getInterestRate())
                .calculateUtilizationRate(
                    asset(),
                    getUnderlyingBalance(),
                    _debt
                );
    }

    /// @notice Sets the pool configuration.
    /// @param poolConfig The pool configuration to set
    function setPoolConfig(
        ConfigTypes.LendingPoolConfig memory poolConfig
    ) external onlyOwner {
        _lendingPoolConfig = poolConfig;
    }

    /// @notice Returns the current pool configuration.
    /// @return The current pool configuration.
    function getPoolConfig()
        external
        view
        returns (ConfigTypes.LendingPoolConfig memory)
    {
        return _lendingPoolConfig;
    }

    /// @notice Sets the pause state of the pool.
    /// @param paused Whether to pause the pool or not.
    function setPause(bool paused) external onlyOwner {
        _paused = paused;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC165) returns (bool) {
        return
            type(ILendingPool).interfaceId == interfaceId ||
            type(IERC4626).interfaceId == interfaceId ||
            ERC165.supportsInterface(interfaceId);
    }

    function _requirePoolNotPaused() internal view {
        require(!_paused, "LP:POOL_PAUSED");
    }

    function _requireOnlyMarket() internal view {
        require(
            msg.sender == _addressProvider.getLendingMarket(),
            "LP:NOT_MARKET"
        );
    }
}