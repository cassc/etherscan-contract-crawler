// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library LibDiamondStoragePause {
    struct DiamondStoragePause {
        bool isPaused;
    }

    bytes32 constant DIAMOND_STORAGE_POSITION_PAUSE = keccak256("diamond.standard.diamond.storage.DerivaDEX.Pause");

    function diamondStoragePause() internal pure returns (DiamondStoragePause storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION_PAUSE;
        assembly {
            ds_slot := position
        }
    }
}