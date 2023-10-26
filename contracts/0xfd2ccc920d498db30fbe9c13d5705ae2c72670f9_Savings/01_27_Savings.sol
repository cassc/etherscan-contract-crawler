// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "./BaseSavings.sol";

/// @title Savings
/// @author Angle Labs, Inc.
/// @notice In this implementation, assets in the contract increase in value following a `rate` chosen by governance
contract Savings is BaseSavings {
    using SafeERC20 for IERC20;
    using MathUpgradeable for uint256;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                PARAMETERS / REFERENCES                                             
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Inflation rate (per second) in BASE_27
    uint208 public rate;

    /// @notice Last time rewards were accrued
    uint40 public lastUpdate;

    /// @notice Whether the contract is paused or not
    uint8 public paused;

    /// @notice Maximum inflation rate
    /// @dev Note that `rate` can still be greater than `maxRate` if this `maxRate` is reduced by governance
    /// to a level inferior to the current rate
    uint256 public maxRate;

    uint256[49] private __gap;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                        EVENTS                                                      
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    event Accrued(uint256 interest);
    event MaxRateUpdated(uint256 newMaxRate);
    event ToggledPause(uint128 pauseStatus);
    event RateUpdated(uint256 newRate);

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    INITIALIZATION                                                  
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Initializes the contract
    /// @param _accessControlManager Reference to the `AccessControlManager` contract
    /// @param name_ Name of the savings contract
    /// @param symbol_ Symbol of the savings contract
    /// @param divizer Quantifies the first initial deposit (should be typically 1 for tokens like agEUR)
    /// @dev A first deposit is done at initialization to protect for the classical issue of ERC4626 contracts
    /// where the the first user of the contract tries to steal everyone else's tokens
    function initialize(
        IAccessControlManager _accessControlManager,
        IERC20MetadataUpgradeable asset_,
        string memory name_,
        string memory symbol_,
        uint256 divizer
    ) public initializer {
        if (address(_accessControlManager) == address(0)) revert ZeroAddress();
        __ERC4626_init(asset_);
        __ERC20_init(name_, symbol_);
        accessControlManager = _accessControlManager;
        _deposit(msg.sender, address(this), 10 ** (asset_.decimals()) / divizer, BASE_18 / divizer);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                       MODIFIERS                                                    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether the whole contract is paused or not
    modifier whenNotPaused() {
        if (paused > 0) revert Paused();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    CONTRACT LOGIC                                                  
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Accrues interest to this contract by minting agTokens
    function _accrue() internal returns (uint256 newTotalAssets) {
        uint256 currentBalance = super.totalAssets();
        newTotalAssets = _computeUpdatedAssets(currentBalance, block.timestamp - lastUpdate);
        lastUpdate = uint40(block.timestamp);
        uint256 earned = newTotalAssets - currentBalance;
        if (earned > 0) {
            IAgToken(asset()).mint(address(this), earned);
            emit Accrued(earned);
        }
    }

    /// @notice Computes how much `currentBalance` held in the contract would be after `exp` time following
    /// the `rate` of increase
    function _computeUpdatedAssets(uint256 currentBalance, uint256 exp) internal view returns (uint256) {
        uint256 ratePerSecond = rate;
        if (exp == 0 || ratePerSecond == 0) return currentBalance;
        uint256 expMinusOne = exp - 1;
        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;
        uint256 basePowerTwo = (ratePerSecond * ratePerSecond + HALF_BASE_27) / BASE_27;
        uint256 basePowerThree = (basePowerTwo * ratePerSecond + HALF_BASE_27) / BASE_27;
        uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
        uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6;
        return (currentBalance * (BASE_27 + ratePerSecond * exp + secondTerm + thirdTerm)) / BASE_27;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                ERC4626 VIEW FUNCTIONS                                              
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC4626Upgradeable
    function totalAssets() public view override returns (uint256) {
        return _computeUpdatedAssets(super.totalAssets(), block.timestamp - lastUpdate);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                             ERC4626 INTERACTION FUNCTIONS                                          
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC4626Upgradeable
    function deposit(uint256 assets, address receiver) public override whenNotPaused returns (uint256 shares) {
        uint256 newTotalAssets = _accrue();
        shares = _convertToShares(assets, newTotalAssets, MathUpgradeable.Rounding.Down);
        _deposit(_msgSender(), receiver, assets, shares);
    }

    /// @inheritdoc ERC4626Upgradeable
    function mint(uint256 shares, address receiver) public override whenNotPaused returns (uint256 assets) {
        uint256 newTotalAssets = _accrue();
        assets = _convertToAssets(shares, newTotalAssets, MathUpgradeable.Rounding.Up);
        _deposit(_msgSender(), receiver, assets, shares);
    }

    /// @inheritdoc ERC4626Upgradeable
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override whenNotPaused returns (uint256 shares) {
        uint256 newTotalAssets = _accrue();
        shares = _convertToShares(assets, newTotalAssets, MathUpgradeable.Rounding.Up);
        _withdraw(_msgSender(), receiver, owner, assets, shares);
    }

    /// @inheritdoc ERC4626Upgradeable
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override whenNotPaused returns (uint256 assets) {
        uint256 newTotalAssets = _accrue();
        assets = _convertToAssets(shares, newTotalAssets, MathUpgradeable.Rounding.Down);
        _withdraw(_msgSender(), receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                   INTERNAL HELPERS                                                 
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC4626Upgradeable
    function _convertToShares(
        uint256 assets,
        MathUpgradeable.Rounding rounding
    ) internal view override returns (uint256 shares) {
        return _convertToShares(assets, totalAssets(), rounding);
    }

    /// @notice Same as the function above except that the `totalAssets` value does not have to be recomputed here
    function _convertToShares(
        uint256 assets,
        uint256 newTotalAssets,
        MathUpgradeable.Rounding rounding
    ) internal view returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? assets.mulDiv(BASE_18, 10 ** (IERC20MetadataUpgradeable(asset()).decimals()), rounding)
                : assets.mulDiv(supply, newTotalAssets, rounding);
    }

    /// @inheritdoc ERC4626Upgradeable
    function _convertToAssets(
        uint256 shares,
        MathUpgradeable.Rounding rounding
    ) internal view override returns (uint256 assets) {
        return _convertToAssets(shares, totalAssets(), rounding);
    }

    /// @notice Same as the function above except that the `totalAssets` value does not have to be recomputed here
    function _convertToAssets(
        uint256 shares,
        uint256 newTotalAssets,
        MathUpgradeable.Rounding rounding
    ) internal view returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0)
                ? shares.mulDiv(10 ** (IERC20MetadataUpgradeable(asset()).decimals()), BASE_18, rounding)
                : shares.mulDiv(newTotalAssets, supply, rounding);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                        HELPERS                                                     
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Provides an estimated Annual Percentage Rate for base depositors on this contract
    function estimatedAPR() external view returns (uint256 apr) {
        // 365 days = 31536000 seconds
        return _computeUpdatedAssets(BASE_18, 31536000) - BASE_18;
    }

    /// @notice Wrapper on top of the `computeUpdatedAssets` function
    function computeUpdatedAssets(uint256 _totalAssets, uint256 exp) external view returns (uint256) {
        return _computeUpdatedAssets(_totalAssets, exp);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                      GOVERNANCE                                                    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Pauses the contract
    function togglePause() external onlyGuardian {
        uint8 pauseStatus = 1 - paused;
        paused = pauseStatus;
        emit ToggledPause(pauseStatus);
    }

    /// @notice Updates the inflation rate for depositing `asset` in this contract
    /// @dev Any `rate` can be set by the guardian provided that it is inferior to the `maxRate` settable
    /// by a governor address
    function setRate(uint208 newRate) external onlyGuardian {
        if (newRate > maxRate) revert InvalidRate();
        _accrue();
        rate = newRate;
        emit RateUpdated(newRate);
    }

    /// @notice Updates the maximum rate settable
    function setMaxRate(uint256 newMaxRate) external onlyGovernor {
        maxRate = newMaxRate;
        emit MaxRateUpdated(newMaxRate);
    }
}