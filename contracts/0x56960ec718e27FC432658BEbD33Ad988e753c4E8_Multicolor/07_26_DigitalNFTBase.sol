// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Developed by DigitalNFT.it (https://digitalnft.it/)
abstract contract DigitalNFTBase is Ownable {
    
    // ============================== Fields ============================= //

    string internal _contractUri;


    // ============================ Functions ============================ //

    // ======================== //
    // === Public Functions === //
    // ======================== //

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for the storefront-level metadata of the contract.
     */
    function contractURI() external view returns (string memory) {
        return _contractUri;
    }
}