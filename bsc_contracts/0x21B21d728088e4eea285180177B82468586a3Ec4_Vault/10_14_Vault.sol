// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./strategies/StrategyConnector.sol";
import "./interfaces/IUSDL.sol";
import "./interfaces/IVault.sol";

contract Vault is IVault, OwnableUpgradeable, StrategyConnector {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // STORAGE

    IUSDL public usdl;

    address public messenger;

    struct CollateralData {
        address strategy;
        uint256 buffer;
        uint256 price;
        uint256 balance;
    }

    mapping(address => CollateralData) public collaterals;

    // ERRORS

    error UnsupportedCollateral(address collateral);

    error CollateralAlreadyExists(address collateral);

    error InvalidPrice(address collateral, uint256 price);

    error SenderIsNotMessenger(address sender, address messenger);

    error NotEnoughCollateralBalance(address collateral);

    error ZeroAmount();

    // EVENTS

    event Mint(address collateral, uint256 amount);

    event Burn(address collateral, uint256 amount);

    event Invested(address collateral, address strategy, uint256 amount);

    event CollateralAdded(address collateral);

    // CONSTRUCTOR

    function initialize(IUSDL usdl_, address messenger_) external initializer {
        __Ownable_init();

        usdl = usdl_;
        messenger = messenger_;
    }

    // PUBLIC FUNCTIONS

    function mint(address collateral, uint256 amount) external {
        // Check collateral
        uint256 price = collaterals[collateral].price;
        if (price == 0) revert UnsupportedCollateral(collateral);

        // Transfer collateral and account for balance
        IERC20Upgradeable(collateral).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
        collaterals[collateral].balance += amount;

        // Mint USDL
        uint256 mintAmount = (amount * price) / 1 ether;
        if (mintAmount == 0) revert ZeroAmount();
        usdl.mint(_msgSender(), mintAmount);

        // Emit event
        emit Mint(collateral, amount);
    }

    function burn(address collateral, uint256 amount) external {
        // Check that collateral is active
        CollateralData memory data = collaterals[collateral];
        if (data.price == 0) revert UnsupportedCollateral(collateral);

        // Burn USDL
        usdl.burn(_msgSender(), amount);

        // Withdraw collateral
        uint256 collateralAmount = (amount * 1 ether) / data.price;
        if (collateralAmount == 0) revert ZeroAmount();
        collaterals[collateral].balance -= collateralAmount;
        _withdraw(collateral, _msgSender(), collateralAmount);

        // Emit event
        emit Burn(collateral, amount);
    }

    // RESTRICTED PUBLIC FUNCTIONS

    function invest(address collateral) external onlyOwner {
        // Check that collateral is active
        if (collaterals[collateral].price == 0)
            revert UnsupportedCollateral(collateral);

        // Deposit
        _invest(collateral);
    }

    function collectYield(address collateral, bytes memory extraData)
        external
        onlyOwner
    {
        // Check that collateral is active
        CollateralData memory data = collaterals[collateral];
        if (data.price == 0) revert UnsupportedCollateral(collateral);

        // Transfer excess balance
        uint256 vaultBalance = IERC20Upgradeable(collateral).balanceOf(
            address(this)
        );
        vaultBalance += _strategyBalance(data.strategy, collateral);
        if (vaultBalance > data.balance) {
            _withdraw(collateral, _msgSender(), vaultBalance - data.balance);
        }

        // Collect extra
        _strategyCollectExtra(
            data.strategy,
            collateral,
            _msgSender(),
            extraData
        );
    }

    function addCollateral(
        address collateral,
        CollateralData memory data,
        bytes memory strategyInitData
    ) external onlyOwner {
        // Checks
        if (collaterals[collateral].price != 0)
            revert CollateralAlreadyExists(collateral);
        if (data.price == 0) revert InvalidPrice(collateral, data.price);

        // Set collateral
        data.balance = 0;
        collaterals[collateral] = data;

        // Initialize strategy
        if (data.strategy != address(0)) {
            _strategyInitialize(data.strategy, collateral, strategyInitData);
        }

        // Emit event
        emit CollateralAdded(collateral);
    }

    function useCollateral(address collateral, uint256 amount) external {
        // Check that sender is messenger
        if (_msgSender() != messenger)
            revert SenderIsNotMessenger(_msgSender(), messenger);

        // Check that amount is available and reduce balance
        if (amount > collaterals[collateral].balance)
            revert NotEnoughCollateralBalance(collateral);
        unchecked {
            collaterals[collateral].balance -= amount;
        }

        // Transfer collateral
        _withdraw(collateral, _msgSender(), amount);
    }

    // PUBLIC VIEW FUNCTIONS

    function getBalanceWithYield(address collateral)
        external
        returns (uint256)
    {
        address strategy = collaterals[collateral].strategy;
        return
            IERC20Upgradeable(collateral).balanceOf(address(this)) +
            _strategyBalance(strategy, collateral);
    }

    // INTERNAL FUNCTIONS

    function _invest(address collateral) internal {
        // Check if should deposit
        uint256 vaultBalance = IERC20Upgradeable(collateral).balanceOf(
            address(this)
        );
        CollateralData memory data = collaterals[collateral];
        if (vaultBalance <= data.buffer || data.strategy == address(0)) {
            return;
        }

        // Deposit to strategy
        uint256 depositAmount = vaultBalance - data.buffer;
        _strategyDeposit(data.strategy, collateral, depositAmount);

        // Emit event
        emit Invested(collateral, data.strategy, depositAmount);
    }

    function _withdraw(
        address collateral,
        address to,
        uint256 amount
    ) internal {
        // Withdraw from strategy if needed
        uint256 vaultBalance = IERC20Upgradeable(collateral).balanceOf(
            address(this)
        );
        if (amount > vaultBalance) {
            _strategyWithdraw(
                collaterals[collateral].strategy,
                collateral,
                amount - vaultBalance
            );
        }

        // Transfer collateral
        IERC20Upgradeable(collateral).safeTransfer(to, amount);
    }
}