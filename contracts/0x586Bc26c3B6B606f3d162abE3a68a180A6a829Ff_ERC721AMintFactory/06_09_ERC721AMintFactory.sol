// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721AMintImmutable.sol";

/**
 * ERC721AMint factory contract.
 */
contract ERC721AMintFactory {
    event ContractCreated(address contractAddress);

    /**
     * @notice Deploy and initialize contract.
     */
    function deploy(
        address productsModuleAddress_,
        uint256 slicerId_,
        string memory name_,
        string memory symbol_,
        address royaltyReceiver_,
        uint256 royaltyFraction_,
        string memory baseURI__,
        string memory tokenURI__
    ) external returns (address contractAddress) {
        contractAddress = address(
            new ERC721AMintImmutable(
                productsModuleAddress_,
                slicerId_,
                name_,
                symbol_,
                royaltyReceiver_,
                royaltyFraction_,
                baseURI__,
                tokenURI__
            )
        );

        emit ContractCreated(contractAddress);
    }
}