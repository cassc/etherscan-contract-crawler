// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Lightweight version of OpenZeppelin's ERC721URIStorage.sol
 */
abstract contract ERC721URIStorageLite is ERC721 {
    using Strings for uint256;
    string private baseURI_;
    string private contractURI_;

    /**
     * @dev Retrieves tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
    }

    /**
     * @dev The contractURI method returns a URL for the storefront-level metadata 
     * of a  contract. For more info: https://docs.opensea.io/docs/contract-level-metadata
     * @return string memory: The contractURI of the contract.
     */
    function contractURI() external view virtual returns (string memory) {
        return _contractURI();
    }

    /**
     * @dev Retrieve `contractURI_`
     * @return string memory: The contractURI of the contract.
     */
    function _contractURI() internal view virtual returns (string memory) {
        return contractURI_;
    }

    /**
     * @dev Set `contractURI_`
     *
     */
    function _setContractURI(string memory newContractURI) internal virtual {
        contractURI_ = newContractURI;
    }

    /**
     * @dev External function that retrieves the baseURI of this ERC721 token. Useful for confirming the baseURI is correct
     * and/or unit testing.
     * @return string memory: The baseURI of the contract.
     */
    function baseURI() external view virtual returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Retrieve `baseURI_`
     * @return string memory: The baseURI of the contract.
     */
    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURI_;
    }

    /**
     * @dev Set `baseURI_`
     *
     */
    function _setBaseURI(string memory newBaseURI) internal virtual {
        baseURI_ = newBaseURI;
    }
}