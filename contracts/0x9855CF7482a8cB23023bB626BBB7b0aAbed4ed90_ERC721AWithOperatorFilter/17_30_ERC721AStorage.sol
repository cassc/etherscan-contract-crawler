// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library ERC721AStorage {
    struct Layout {
        string CID;
        mapping(uint256 => bool) noncesUsed;
        mapping(uint256 => string) tokenURIs;
        string ipfsURI;
        string baseURI;
        bool isContractLocked;
        bool isMetadataLocked;
        uint128 maxSupply;
        uint16[] royaltySplits; // totaling 10000 (in BPS)
        address payable[] royaltyRecipients;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quantum.contracts.storage.erc721a.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
//ERC721AStorage.Layout storage qs = ERC721AStorage.layout();