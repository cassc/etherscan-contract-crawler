// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DiamondCloneLib} from "../DiamondClone/DiamondCloneLib.sol";
import {Strings} from "../ERC721A/ERC721ALib.sol";
import {DiamondSaw} from "../../DiamondSaw.sol";

error MetaDataLocked();

library URIStorageLib {
    using Strings for uint256;

    struct URIStorage {
        mapping(uint256 => string) _tokenURIs;
        string folderStorageBaseURI;
        string tokenStorageBaseURI;
        bytes4 tokenURIOverrideSelector;
        bool metadataLocked;
    }

    function uriStorage() internal pure returns (URIStorage storage s) {
        bytes32 position = keccak256("uri.storage.facet.storage");
        assembly {
            s.slot := position
        }
    }

    function setFolderStorageBaseURI(string memory _baseURI) internal {
        URIStorage storage s = uriStorage();
        if (s.metadataLocked) revert MetaDataLocked();
        s.folderStorageBaseURI = _baseURI;
    }

    function setTokenStorageBaseURI(string memory _baseURI) internal {
        URIStorage storage s = uriStorage();
        if (s.metadataLocked) revert MetaDataLocked();
        s.tokenStorageBaseURI = _baseURI;
    }

    function tokenURIFromStorage(uint256 tokenId)
        internal
        view
        returns (string storage)
    {
        return uriStorage()._tokenURIs[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        URIStorage storage s = uriStorage();
        if (s.metadataLocked) revert MetaDataLocked();
        s._tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal {
        URIStorage storage s = uriStorage();
        if (bytes(s._tokenURIs[tokenId]).length != 0) {
            delete s._tokenURIs[tokenId];
        }
    }

    function setTokenURIOverrideSelector(bytes4 selector) internal {
        URIStorage storage s = uriStorage();
        if (s.metadataLocked) revert MetaDataLocked();

        address sawAddress = DiamondCloneLib
            .diamondCloneStorage()
            .diamondSawAddress;
        bool isApproved = DiamondSaw(sawAddress).isTokenURISelectorApproved(
            selector
        );
        require(isApproved, "selector not approved");
        s.tokenURIOverrideSelector = selector;
    }

    function removeTokenURIOverrideSelector() internal {
        URIStorage storage s = uriStorage();
        if (s.metadataLocked) revert MetaDataLocked();
        s.tokenURIOverrideSelector = bytes4(0);
    }

    // Check for
    // 1. tokenURIOverride (approved override function)
    // 2. if individual token uri is set
    // 3. folder storage
    function tokenURI(uint256 tokenId) internal view returns (string memory) {
        URIStorage storage s = uriStorage();

        // the override is set, use that
        if (s.tokenURIOverrideSelector != bytes4(0)) {
            (bool success, bytes memory result) = address(this).staticcall(
                abi.encodeWithSelector(s.tokenURIOverrideSelector, tokenId)
            );
            require(success, "Token URI Override Failed");

            string memory uri = abi.decode(result, (string));
            return uri;
        }

        // fall back on "normal" token storage
        string storage individualTokenURI = tokenURIFromStorage(tokenId);
        string storage folderStorageBaseURI = s.folderStorageBaseURI;
        string storage tokenStorageBaseURI = s.tokenStorageBaseURI;

        return
            bytes(individualTokenURI).length != 0
                ? string(
                    abi.encodePacked(tokenStorageBaseURI, individualTokenURI)
                )
                : string(
                    abi.encodePacked(folderStorageBaseURI, tokenId.toString())
                );
    }

    function lockMetadata() internal {
        uriStorage().metadataLocked = true;
    }
}