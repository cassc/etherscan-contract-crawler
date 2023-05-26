// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* External Imports */
import {ERC721} from "ERC721.sol";
import {Strings} from "Strings.sol";

/* Internal Imports */
import {BaseErrorCodes} from "ErrorCodes.sol";

//=====================================================================================================================
/// 😎 Free Internet Money 😎
//=====================================================================================================================

/**
 * @dev Lightweight version of OpenZeppelin's ERC721URIStorage.sol
 */

abstract contract ERC721Metadata is BaseErrorCodes, ERC721 {
    using Strings for uint256;

    //=================================================================================================================
    /// State Variables
    //=================================================================================================================

    /* Private */
    string private baseURI_;

    /**
     * @dev Retrieves tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), kErrTokenDoesNotExist);
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
    }

    /**
     * @dev External function that retrieves the baseURI of this ERC721 token. Useful for 
     confirming the baseURI is correct and/or unit testing.
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