// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AppStorage {
    struct PassEntry {
        uint256 price;
        uint256 maxSupply;
        bool isValue;
    }

    struct Layout {
        string name;
        string symbol;
        string  baseURI;
        bytes32 merkleRoot;
        // pass type supply per sale
        mapping(uint256 => mapping(uint256 => uint256)) supplyById;
        // passes per sale id
        mapping(uint256 => mapping(uint256 => PassEntry)) passesForSaleById;
    }

    bytes32 internal constant APP_STORAGE_SLOT =
        keccak256("TheHub.contracts.AppStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = APP_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}