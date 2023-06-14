// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IMasterVault_V2.sol";

import "./interfaces/ILiquidAsset.sol";

// --- MasterVault_V2 (Variant 2) ---
// --- Vault with instances per Liquid Staked Underlying to generate yield via ratio change and strategies ---
contract MasterVault_V2 is IMasterVault_V2, ERC4626Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    // --- Wrappers ---
    using SafeERC20Upgradeable for ILiquidAsset;

    // --- Constants ---

    // --- Vars ---
    address public provider;          // DavosProvider
    address public yieldHeritor;      // Yield Recipient
    uint256 public yieldMargin;       // Percentage of Yield protocol gets, 10,000 = 100%
    uint256 public yieldBalance;      // Balance at which Yield for protocol was last claimed
    uint256 public underlyingBalance; // Total balance of underlying asset

    // --- Mods ---
    modifier onlyOwnerOrProvider() {
        require(msg.sender == owner() || msg.sender == provider, "MasterVault_V2/not-owner-or-provider");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(string memory _name, string memory _symbol, uint256 _yieldMargin, address _underlying) external initializer {

        __ERC4626_init(IERC20MetadataUpgradeable(_underlying));
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        yieldMargin = _yieldMargin;
        yieldBalance = 0;
    }

    // --- Provider ---
    function deposit(uint256 assets, address receiver) public override nonReentrant whenNotPaused onlyOwnerOrProvider returns (uint256) {

        address src = _msgSender();

        require(assets > 0, "MasterVault_V2/invalid-amount");
        require(receiver != address(0), "MasterVault_V2/0-address");
        require(assets <= maxDeposit(src), "MasterVault_V2/deposit-more-than-max");

        _claimYield();
        uint256 shares = previewDeposit(assets);
        _deposit(src, src, assets, shares);

        underlyingBalance += assets;
        yieldBalance = getBalance();

        return shares;
    }
    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant whenNotPaused onlyOwnerOrProvider returns (uint256) {

        address src = _msgSender();

        require(shares <= maxRedeem(owner), "MasterVault_V2/withdraw-more-than-max");
        require(receiver != address(0), "MasterVault_V2/0-address");

        uint256 assets = previewRedeem(shares);
        _claimYield();

        underlyingBalance -= assets;
        yieldBalance = getBalance();
        _withdraw(owner, receiver, owner, assets, shares);

        return assets;
    }

    function claimYield() public returns (uint256) {
        uint256 yield = _claimYield();
        yieldBalance = getBalance();
        return yield;
    }

    function _claimYield() internal returns (uint256) {
        uint256 availableYields = getVaultYield();
        if (availableYields <= 0) return 0;

        ILiquidAsset _asset = ILiquidAsset(asset());
        _asset.safeTransfer(yieldHeritor, availableYields);
        underlyingBalance -= availableYields;

        emit Claim(address(this), yieldHeritor, availableYields);
        return availableYields;
    }
    
    // --- Admin ---
    function changeProvider(address _provider) external onlyOwnerOrProvider {

        require(_provider != address(0), "MasterVault_V2/0-address");
        provider = _provider;

        emit Provider(provider, _provider);
    }
    function changeYieldHeritor(address _yieldHeritor) external onlyOwnerOrProvider {

        require(_yieldHeritor != address(0), "MasterVault_V2/0-address");
        yieldHeritor = _yieldHeritor;

        emit YieldHeritor(yieldHeritor, _yieldHeritor);
    }
    function changeYieldMargin(uint256 _yieldMargin) external onlyOwnerOrProvider {

        require(_yieldMargin <= 1e4, "MasterVault_V2/should-be-less-than-max");
        yieldMargin = _yieldMargin;

        emit YieldMargin(yieldMargin, _yieldMargin);
    }
    
    // --- Views ---
    function getVaultYield() public view returns (uint256) {
        uint256 totalBalance = getBalance();
        if (totalBalance <= yieldBalance) return 0;

        uint256 diffBalance = totalBalance - yieldBalance;

        uint256 yield = diffBalance * yieldMargin / 1e4;

        return ILiquidAsset(asset()).getWstETHByStETH(yield);
    }

    function totalAssets() public view virtual override returns (uint256) {
        return underlyingBalance - getVaultYield();
    }

    function getBalance() public view returns (uint256) {
        return ILiquidAsset(asset()).getStETHByWstETH(underlyingBalance);
    }

    // ---------------
    // --- ERC4626 ---
    /** Kept only for the sake of ERC4626 standard
      */
    function mint(uint256 shares, address receiver) public override returns (uint256) { revert(); }
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) { revert(); }
}