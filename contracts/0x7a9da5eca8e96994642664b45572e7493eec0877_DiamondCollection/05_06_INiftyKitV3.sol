// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface INiftyKitV3 {
    struct DiamondArgs {
        address owner;
        address admin;
        address treasury;
        address royalty;
        address trustedForwarder;
        uint16 royaltyBps;
        string name;
        string symbol;
        string baseURI;
        bytes32[] apps;
    }

    /**
     * @dev Returns app registry address.
     */
    function appRegistry() external returns (address);

    /**
     * @dev Returns the commission amount (sellerFee, buyerFee).
     * @dev Deprecated: use commissionByQuantity instead.
     */
    function commission(
        address collection,
        uint256 amount
    ) external view returns (uint256, uint256);

    /**
     * @dev Returns the commission amount (mintFee, ownerPerks).
     */
    function commissionByQuantity(
        address collection,
        uint256 quantity
    ) external view returns (uint256, uint256);

    /**
     * @dev Get fees by amount (called from collection)
     * @dev Deprecated: use getFeesByQuantity instead.
     */
    function getFees(uint256 amount) external view returns (uint256, uint256);

    /**
     * @dev Get fees by quantity (called from collection)
     */
    function getFeesByQuantity(
        uint256 quantity
    ) external view returns (uint256, uint256);

    /**
     * @dev Returns the perks rate for a given owner.
     */
    function getOwnerPerksRate(address owner) external view returns (uint96);
}