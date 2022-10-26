// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @title: Manifold Marketplace Contract Created for Christie's

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControlUpgradeable.sol";
import "./MarketplaceCore.sol";

contract MarketplaceUpgradeable is AdminControlUpgradeable, MarketplaceCore, ReentrancyGuardUpgradeable {

    /**
     * Initializer
     */
    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _setEnabled(true);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControlUpgradeable) returns (bool) {
        return interfaceId == type(IMarketplaceCore).interfaceId
            || AdminControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IMarketplace-setFees}.
     */
    function setFees(uint16 marketplaceFeeBPS, uint16 marketplaceReferrerBPS) external virtual override onlyOwner {
        _setFees(marketplaceFeeBPS, marketplaceReferrerBPS);
    }
    
    /**
     * @dev See {IMarketplace-setEnabled}.
     */
    function setEnabled(bool enabled) external virtual override onlyOwner {
        _setEnabled(enabled);
    }

    /**
     * @dev See {IMarketplaceCore-createListing}.
     */
    function createListing(address payable seller, MarketplaceLib.ListingDetails calldata listingDetails, MarketplaceLib.TokenDetails calldata tokenDetails, MarketplaceLib.ListingReceiver[] calldata listingReceivers, bool enableReferrer) external virtual override adminRequired returns (uint40) {
        return _createListing(seller, listingDetails, tokenDetails, listingReceivers, enableReferrer);
    }

    /**
     * @dev See {IMarketplaceCore-modifyListing}.
     */
    function modifyListing(uint40 listingId, uint256 initialAmount, uint48 startTime, uint48 endTime) external virtual override adminRequired {
        _modifyListing(listingId, initialAmount, startTime, endTime);
    }

    /**
     * @dev See {IMarketplaceCore-completeListing}.
     */
    function completeListing(uint40 listingId, MarketplaceLib.DeliveryFees calldata fees) external virtual override adminRequired {
        _completeListing(listingId, fees);
    }

    /**
     * @dev See {IMarketplace-cancelListing}.
     */
    function cancelListing(uint40 listingId, uint16 holdbackBPS) external virtual override adminRequired nonReentrant {
        _cancelListing(listingId, holdbackBPS);
    }

    /**
     * @dev See {IMarketplace-withdraw}.
     */
    function withdraw(uint256 amount, address payable receiver) external virtual override onlyOwner nonReentrant {
        _withdraw(address(0), amount, receiver);
    }

    /**
     * @dev See {IMarketplace-withdraw}.
     */
    function withdraw(address erc20, uint256 amount, address payable receiver) external virtual override onlyOwner nonReentrant {
        _withdraw(erc20, amount, receiver);
    }

    /**
     * @dev See {IMarketplace-withdrawEscrow}.
     */
    function withdrawEscrow(uint256 amount) external virtual override nonReentrant {
        _withdrawEscrow(address(0), amount);
    }

    /**
     * @dev See {IMarketplace-withdrawEscrow}.
     */
    function withdrawEscrow(address erc20, uint256 amount) external virtual override nonReentrant {
        _withdrawEscrow(erc20, amount);
    }

    uint256[50] private __gap;

}