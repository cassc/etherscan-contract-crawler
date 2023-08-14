// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";

import "./interfaces/IDavosProvider.sol";

import "./interfaces/ICertToken.sol";
import "./interfaces/IInteraction.sol";
import "./interfaces/IWrapped.sol";

// --- Wrapping adaptor with instances per Underlying for MasterVault ---
contract DavosProvider is IDavosProvider, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    // --- Wrapper --- 'PLACEHOLDER_' slot unused
    using SafeERC20Upgradeable for IWrapped;

    // --- Vars ---
    IERC20Upgradeable public collateral;     // ceToken in MasterVault
    ICertToken public collateralDerivative;
    IERC4626Upgradeable public masterVault;
    IInteraction public interaction;
    address public PLACEHOLDER_1;
    IWrapped public underlying;              // isNative then Wrapped, else ERC20
    bool public isNative;

    // --- Mods ---
    modifier onlyOwnerOrInteraction() {

        require(msg.sender == owner() || msg.sender == address(interaction), "DavosProvider/not-interaction-or-owner");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }
    
    // --- Init ---
    function initialize(address _underlying, address _collateralDerivative, address _masterVault, address _interaction, bool _isNative) external initializer {

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        underlying = IWrapped(_underlying);
        collateral = IERC20Upgradeable(_masterVault);
        collateralDerivative = ICertToken(_collateralDerivative);
        masterVault = IERC4626Upgradeable(_masterVault);
        interaction = IInteraction(_interaction);
        isNative = _isNative;

        IERC20Upgradeable(underlying).approve(_masterVault, type(uint256).max);
        IERC20Upgradeable(collateral).approve(_interaction, type(uint256).max);
    }
    
    // --- User ---
    function provide(uint256 _amount) external payable override whenNotPaused nonReentrant returns (uint256 value) {

        if(isNative) {
            require(_amount == 0, "DavosProvider/erc20-not-accepted");
            uint256 native = msg.value;
            IWrapped(underlying).deposit{value: native}();
            value = masterVault.deposit(native, msg.sender);
        } else {
            require(msg.value == 0, "DavosProvider/native-not-accepted");
            underlying.safeTransferFrom(msg.sender, address(this), _amount);
            value = masterVault.deposit(_amount, msg.sender);
        }

        value = _provideCollateral(msg.sender, value);
        emit Deposit(msg.sender, value);
        return value;
    }
    function release(address _recipient, uint256 _amount) external override whenNotPaused nonReentrant returns (uint256 realAmount) {

        require(_recipient != address(0));
        realAmount = _withdrawCollateral(msg.sender, _amount);
        realAmount = masterVault.redeem(realAmount, _recipient, address(this));

        emit Withdrawal(msg.sender, _recipient, realAmount);
        return realAmount;
    }
    
    // --- Interaction ---
    function liquidation(address _recipient, uint256 _amount) external override onlyOwnerOrInteraction nonReentrant {

        require(_recipient != address(0));
        masterVault.redeem(_amount, _recipient, address(this));
    }
    function daoBurn(address _account, uint256 _amount) external override onlyOwnerOrInteraction nonReentrant {

        require(_account != address(0));
        collateralDerivative.burn(_account, _amount);
    }
    function daoMint(address _account, uint256 _amount) external override onlyOwnerOrInteraction nonReentrant {

        require(_account != address(0));
        collateralDerivative.mint(_account, _amount);
    }
    function _provideCollateral(address _account, uint256 _amount) internal returns (uint256 deposited) {

        deposited = interaction.deposit(_account, address(collateral), _amount);
        collateralDerivative.mint(_account, deposited);
    }
    function _withdrawCollateral(address _account, uint256 _amount) internal returns (uint256 withdrawn) {
        
        withdrawn = interaction.withdraw(_account, address(collateral), _amount);
        collateralDerivative.burn(_account, withdrawn);
    }

    // --- Admin ---
    function pause() external onlyOwner {

        _pause();
    }
    function unPause() external onlyOwner {

        _unpause();
    }
    function changeCollateral(address _collateral) external onlyOwner {

        if(address(collateral) != address(0)) 
            IERC20Upgradeable(collateral).approve(address(interaction), 0);
        collateral = IERC20Upgradeable(_collateral);
        IERC20Upgradeable(_collateral).approve(address(interaction), type(uint256).max);
        emit CollateralChanged(_collateral);
    }
    function changeCollateralDerivative(address _collateralDerivative) external onlyOwner {

        collateralDerivative = ICertToken(_collateralDerivative);
        emit CollateralDerivativeChanged(_collateralDerivative);
    }
    function changeMasterVault(address _masterVault) external onlyOwner {

        if(address(underlying) != address(0)) 
            IERC20Upgradeable(underlying).approve(address(masterVault), 0);
        masterVault = IERC4626Upgradeable(_masterVault);
        IERC20Upgradeable(underlying).approve(address(_masterVault), type(uint256).max);
        emit MasterVaultChanged(_masterVault);
    }
    function changeInteraction(address _interaction) external onlyOwner {
        
        if(address(collateral) != address(0)) 
            IERC20Upgradeable(collateral).approve(address(interaction), 0);
        interaction = IInteraction(_interaction);
        IERC20Upgradeable(collateral).approve(address(_interaction), type(uint256).max);
        emit InteractionChanged(_interaction);
    }
    function changeUnderlying(address _underlying) external onlyOwner {

        if(address(underlying) != address(0)) 
            IERC20Upgradeable(underlying).approve(address(masterVault), 0);
        underlying = IWrapped(_underlying);
        IERC20Upgradeable(_underlying).approve(address(masterVault), type(uint256).max);
        emit UnderlyingChanged(_underlying);
    }
    function changeNativeStatus(bool _isNative) external onlyOwner {

        isNative = _isNative;
        emit NativeStatusChanged(_isNative);
    }
}