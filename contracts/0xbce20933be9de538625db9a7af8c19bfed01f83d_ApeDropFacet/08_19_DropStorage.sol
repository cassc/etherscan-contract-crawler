// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library DropStorage {
    bytes32 private constant STORAGE_SLOT =
        keccak256("niftykit.apps.drop.storage");

    struct Layout {
        mapping(address => uint256) _mintCount;
        bytes32 _merkleRoot;
        uint256 _dropRevenue;
        // Sales Parameters
        uint256 _maxAmount;
        uint256 _maxPerMint;
        uint256 _maxPerWallet;
        uint256 _price;
        // States
        bool _presaleActive;
        bool _saleActive;
    }

    function layout() internal pure returns (Layout storage ds) {
        bytes32 position = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}