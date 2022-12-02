// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library ERC721ABAStorage {
    struct Layout {
        string CID;
        mapping(uint256 => bool) noncesUsed;
        mapping(uint256 => string) tokenURIs;
        string ipfsURI;
        string baseURI;
        bool isContractLocked;
        bool isMetadataLocked;
        uint128 maxSupply;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quantum.contracts.storage.erc721aba.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
//ERC721ABAStorage.Layout storage qs = ERC721ABAStorage.layout();