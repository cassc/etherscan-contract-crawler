// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract P2PVault is ERC4626Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address _manager;
    mapping(address => bool) _shareholders;

    uint256 _assetsInUse;

    modifier onlyManager() {
        require(_msgSender() == _manager, "P2PVault: Only allowed for manager");
        _;
    }

    event WhitelistShareholder(address indexed newShareholder);
    event RevokeShareholder(address indexed newShareholder);

    event ChangeManager(address indexed newManager, address indexed oldManager);

    event UseAssets(address indexed receiver, uint256 amount);
    event ReturnAssets(address indexed sender, uint256 amount);
    event Gains(uint256 amount);
    event Loss(uint256 amount);
    event Fees(uint256 amount);

    function initialize(
        address manager_,
        address asset_,
        string memory name_,
        string memory symbol_
    ) public initializer {
        _manager = manager_;
        __ERC20_init(name_, symbol_);
        __ERC4626_init(IERC20Upgradeable(asset_));
    }

    function manager() public view returns (address) {
        return _manager;
    }

    function setManager(address newManager_) public onlyManager {
        require(newManager_ != address(0), "P2PVault: Manager cannot be null");
        require(!isShareholder(newManager_), "P2PVault: Shareholder cannot be manager");
        emit ChangeManager(newManager_, _manager);
        _manager = newManager_;
    }

    function isShareholder(address address_) public view returns (bool) {
        return _shareholders[address_];
    }

    function whitelistShareholder(address address_) public onlyManager {
        require(address_ != address(0), "P2PVault: Shareholder cannot be null");
        require(address_ != _manager, "P2PVault: Manager cannot be shareholder");
        _shareholders[address_] = true;
        emit WhitelistShareholder(address_);
    }

    function revokeShareholder(address address_) public onlyManager {
        emit RevokeShareholder(address_);
        _shareholders[address_] = false;
    }

    function useAssets(address receiver_, uint256 amount_) public onlyManager {
        IERC20Upgradeable(asset()).safeTransfer(receiver_, amount_);
        _assetsInUse += amount_;
        emit UseAssets(receiver_, amount_);
    }

    function returnAssets(address sender_, uint256 amount_) public onlyManager {
        IERC20Upgradeable(asset()).safeTransferFrom(sender_, address(this), amount_);
        _assetsInUse = amount_ > _assetsInUse ? 0 : (_assetsInUse - amount_);
        emit ReturnAssets(sender_, amount_);
    }

    function gains(uint256 amount_) public onlyManager {
        _assetsInUse += amount_;
        emit Gains(amount_);
    }

    function loss(uint256 amount_) public onlyManager {
        require(amount_ <= _assetsInUse, "P2PVault: Loss cannot be higher than assets in use");
        _assetsInUse -= amount_;
        emit Loss(amount_);
    }

    function fees(uint256 amount_) public onlyManager {
        require(amount_ <= _assetsInUse, "P2PVault: Fees cannot be higher than assets in use");
        _assetsInUse -= amount_;
        emit Fees(amount_);
    }

    function setTotalAssets(uint256 amount_) public onlyManager {
        uint256 assetBalance = IERC20Upgradeable(asset()).balanceOf(address(this));
        require(amount_ >= assetBalance, "P2PVault: Assets in use cannot be less than vault balance");
        setAssetsInUse(amount_ - assetBalance);
    }

    function setAssetsInUse(uint256 amount_) public onlyManager {
        uint256 aiu = assetsInUse();
        if (amount_ >= aiu) gains(amount_ - aiu);
        else loss(aiu - amount_);
    }

    function assetsInUse() public view virtual returns (uint256) {
        return _assetsInUse;
    }

    function totalAssets() public view virtual override returns (uint256) {
        return IERC20Upgradeable(asset()).balanceOf(address(this)) + _assetsInUse;
    }

    function maxWithdraw(address address_) public view virtual override returns (uint256) {
        uint256 shares = balanceOf(address_);
        uint256 assets = _convertToAssets(shares, MathUpgradeable.Rounding.Down);
        uint256 vaultBalance = IERC20Upgradeable(asset()).balanceOf(address(this));
        return MathUpgradeable.min(assets, vaultBalance);
    }

    function maxRedeem(address owner_) public view virtual override returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner_);
        return _convertToShares(maxAssets, MathUpgradeable.Rounding.Down);
    }

    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(isShareholder(receiver), "P2PVault: Receiver is not a whitelisted shareholder");
        return ERC4626Upgradeable.mint(shares, receiver);
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(isShareholder(receiver), "P2PVault: Receiver is not a whitelisted shareholder");
        return ERC4626Upgradeable.deposit(assets, receiver);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        return ERC4626Upgradeable.redeem(shares, receiver, owner);
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
        return ERC4626Upgradeable.withdraw(assets, receiver, owner);
    }
}