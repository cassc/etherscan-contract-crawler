// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControlUpgradeable.sol";
import "./MarketplaceCore.sol";

contract MarketplaceUpgradeable is AdminControlUpgradeable, MarketplaceCore {

    /**
     * Initializer
     */
    function initialize() public initializer {
        __Ownable_init();
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
     * @dev See {IMarketplace-setMarketplaceFeeBPS}.
     */
    function setMarketplaceFeeBPS(uint16 marketplaceFeeBPS) external virtual override adminRequired {
        _setMarketplaceFeeBPS(marketplaceFeeBPS);
    }

    /**
     * @dev See {IMarketplace-setEnabled}.
     */
    function setEnabled(bool enabled) external virtual override adminRequired {
        _setEnabled(enabled);
    }

    /**
     * @dev See {IMarketplace-setSellerRegistry}.
     */
    function setSellerRegistry(address registry) external virtual override adminRequired {
        _setSellerRegistry(registry);
    }

    /**
     * @dev See {IMarketplace-setTokenReceiver}.
     */
    function setTokenReceiver(address tokenReceiver) external virtual override adminRequired {
        _setTokenReceiver(tokenReceiver);
    }

    /**
     * @dev See {IMarketplace-cancel}.
     */
    function cancel(uint256 listingId, uint16 holdbackBPS) external virtual override adminRequired {
        _cancel(listingId, holdbackBPS);
    }

    /**
     * @dev See {IMarketplace-withdraw}.
     */
    function withdraw(uint256 amount, address payable receiver) external virtual override adminRequired {
        _withdraw(address(0), amount, receiver);
    }

    /**
     * @dev See {IMarketplace-withdraw}.
     */
    function withdraw(address erc20, uint256 amount, address payable receiver) external virtual override adminRequired {
        _withdraw(erc20, amount, receiver);
    }

    /**
     * @dev See {IMarketplace-withdrawEscrow}.
     */
    function withdrawEscrow(uint256 amount) external virtual override {
        _withdrawEscrow(address(0), amount);
    }

    /**
     * @dev See {IMarketplace-withdrawEscrow}.
     */
    function withdrawEscrow(address erc20, uint256 amount) external virtual override {
        _withdrawEscrow(erc20, amount);
    }

}