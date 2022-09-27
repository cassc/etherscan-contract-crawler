// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MultiSaleStorage {
    struct Layout {
        // mint count per sale
        mapping(uint256 => mapping(address => uint256)) mintCount;
        // supply per sale
        mapping(uint256 => uint256) saleSupply;
        // max mint per sale
        mapping(uint256 => uint256) maxPerMint;
        // states per sale
        mapping(uint256 => bool) saleActive;
        mapping(uint256 => bool) presaleActive;
        mapping(uint256 => bool) maxPerWallet;
    }

    bytes32 internal constant MULTI_SALE_STORAGE_SLOT =
        keccak256("TheHub.contracts.MultiSaleStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = MULTI_SALE_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}