// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { IDDX } from "../tokens/interfaces/IDDX.sol";

library LibDiamondStorageDerivaDEX {
    struct DiamondStorageDerivaDEX {
        string name;
        address admin;
        IDDX ddxToken;
    }

    bytes32 constant DIAMOND_STORAGE_POSITION_DERIVADEX =
        keccak256("diamond.standard.diamond.storage.DerivaDEX.DerivaDEX");

    function diamondStorageDerivaDEX() internal pure returns (DiamondStorageDerivaDEX storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION_DERIVADEX;
        assembly {
            ds_slot := position
        }
    }
}