// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Gated.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * Deploy clones of purchase hook with single ERC20 Gate.
 */
contract ERC721GatedCloner {
    /// ============= Storage =============

    address private immutable implementation;

    /// ========== Constructor ==========

    /**
     * @notice Initializes the contract and deploys the clone implementation.
     */
    constructor() {
        implementation = address(new ERC721Gated());
    }

    /// ============ Functions ============

    /**
     * @notice Deploy and initialize proxy clone.
     */
    function clone(
        address productsModuleAddress_,
        uint256 slicerId_,
        IERC721 erc721_
    ) external returns (address contractAddress) {
        // Deploys proxy clone
        contractAddress = Clones.clone(implementation);

        // Initialize proxy
        ERC721Gated(contractAddress).initialize(productsModuleAddress_, slicerId_, erc721_);
    }
}