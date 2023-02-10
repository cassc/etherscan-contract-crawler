// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721AMintClone.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * ERC721AMint clone factory contract.
 */
contract ERC721AMintCloner {
    /// ============= Storage =============

    address private immutable implementation;

    /// ========== Constructor ==========

    /**
     * @notice Initializes the contract and deploys the clone implementation.
     */
    constructor() {
        implementation = address(new ERC721AMintClone());
    }

    /// ============ Functions ============

    /**
     * @notice Deploy and initialize proxy clone.
     */
    function clone(
        address productsModuleAddress_,
        uint256 slicerId_,
        string memory name_,
        string memory symbol_,
        address royaltyReceiver_,
        uint256 royaltyFraction_,
        string memory baseURI__,
        string memory tokenURI__
    ) external returns (address contractAddress) {
        // Deploys proxy clone
        contractAddress = Clones.clone(implementation);

        // Initialize proxy
        ERC721AMintClone(contractAddress).initialize(
            productsModuleAddress_,
            slicerId_,
            name_,
            symbol_,
            royaltyReceiver_,
            royaltyFraction_,
            baseURI__,
            tokenURI__
        );
    }
}