// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title WithMeta
/// @author dev by @dievardump
/// @notice This contract adds some base meta management like contractURI, metadataManager and baseURI
contract WithMeta {
    /// @notice contract URI
    string public contractURI;

    /// @notice metadata manager
    address public metadataManager;

    string private _collectionBaseURI;

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    /// @notice returns the current base uri used to build tokens tokenURI
    /// @return the current base uri
    function baseURI() public view virtual returns (string memory) {
        return _baseURI();
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    /// @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    /// token will be the concatenation of the `baseURI` and the `tokenId`.
    function _baseURI() internal view virtual returns (string memory) {
        return _collectionBaseURI;
    }

    /// @dev sets the value returned by {_baseURI}
    /// @param newBaseURI the new base uri
    function _setBaseURI(string memory newBaseURI) internal virtual {
        _collectionBaseURI = newBaseURI;
    }

    /// @dev returns the tokenURI for `tokenId`; it will first check on `metadataManager`
    ///      if there is an URI there, and if not will concat the `tokenId` with the result of {_baseURI}
    function _tokenURI(uint256 tokenId) internal view virtual returns (string memory uri) {
        address metadataManager_ = metadataManager;

        // tokenURI can be managed in another contract, allowing an easy update if the project evolves
        if (metadataManager_ != address(0)) {
            uri = IWithTokenURI(metadataManager_).tokenURI(tokenId);
        }

        if (bytes(uri).length == 0) {
            string memory baseURI_ = _baseURI();
            uri = bytes(baseURI_).length != 0 ? string.concat(baseURI_, Strings.toString(tokenId)) : "";
        }
    }
}

interface IWithTokenURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}