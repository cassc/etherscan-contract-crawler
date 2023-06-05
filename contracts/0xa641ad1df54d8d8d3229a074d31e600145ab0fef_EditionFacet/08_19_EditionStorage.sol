// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library EditionStorage {
    struct Edition {
        string tokenURI;
        bytes32 merkleRoot;
        uint256 price;
        uint256 quantity;
        uint256 maxQuantity;
        uint256 maxPerWallet;
        uint256 maxPerMint;
        uint256 nonce;
        address signer;
        bool active;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("niftykit.apps.edition.storage");

    struct Layout {
        uint256 _count;
        mapping(uint256 => Edition) _editions;
        mapping(uint256 => mapping(address => uint256)) _mintCount;
        uint256 _editionRevenue;
    }

    function layout() internal pure returns (Layout storage ds) {
        bytes32 position = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}