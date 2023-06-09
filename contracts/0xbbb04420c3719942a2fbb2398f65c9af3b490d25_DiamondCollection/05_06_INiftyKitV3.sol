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
     */
    function commission(
        address collection,
        uint256 amount
    ) external view returns (uint256, uint256);

    /**
     * @dev Get fees by amount (called from collection)
     */
    function getFees(uint256 amount) external view returns (uint256, uint256);
}