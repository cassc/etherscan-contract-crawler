// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

library ERC1155Storage {
    using EnumerableSet for EnumerableSet.UintSet;

    struct TokenStructure {
        uint256 maxSupply;
        uint256 price;
        address creator;
        string tokenUri; // Optional, baseUri is set in ERC1155MetadataStorage (https://sample.com/{id}.json) would be valid)
        bool allowListEnabled;
        // bool onChainMetadata;
    }

    struct Layout {
        uint256 currentTokenId;
        bool airdrop;
        string name;
        string symbol;
        string contractURI;
        mapping(uint256 => uint256) maxSupply;
        mapping(uint256 => uint256) price;
        mapping(uint256 => EnumerableSet.AddressSet) creator;
        mapping(uint256 => string) tokenUri;
        mapping(uint256 => bool) allowListEnabled;
        mapping(uint256 => TokenStructure) tokenData; // Map Token ID to it's data, maybe take out?
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("lively.contracts.storage.ERC1155");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function tokenData(
        uint256 _tokenId
    ) internal view returns (TokenStructure storage) {
        return layout().tokenData[_tokenId];
    }
}