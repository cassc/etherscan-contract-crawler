// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

struct MintAuthorization {
    uint256 id;
    address to;
    uint128 dropId;
    uint128 amount;
    uint256 fee;
    bytes32 r;
    bytes32 s;
    uint256 validFrom;
    uint256 validPeriod;
    uint8 v;
    uint8 freezePeriod;
    uint256[] variants;
}

library QuantumSpacesStorage {
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    struct Layout {
        mapping(uint128 => string) dropCID;
        mapping(uint128 => uint128) dropMaxSupply;
        mapping(uint256 => uint256) tokenVariant;
        mapping(uint128 => uint256) dropNumOfVariants;
        BitMapsUpgradeable.BitMap isDropPaused;
        string ipfsURI;
        address authorizer;
        address payable quantumTreasury;
        address blackListAddress;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quantum.contracts.storage.quantumspaces.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
//QuantumSpacesStorage.Layout storage qs = QuantumSpacesStorage.layout();