// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { TraderDefs } from "../libs/defs/TraderDefs.sol";
import { IDDXWalletCloneable } from "../tokens/interfaces/IDDXWalletCloneable.sol";

library LibDiamondStorageTrader {
    struct DiamondStorageTrader {
        mapping(address => TraderDefs.Trader) traders;
        bool rewardCliff;
        IDDXWalletCloneable ddxWalletCloneable;
    }

    bytes32 constant DIAMOND_STORAGE_POSITION_TRADER = keccak256("diamond.standard.diamond.storage.DerivaDEX.Trader");

    function diamondStorageTrader() internal pure returns (DiamondStorageTrader storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION_TRADER;
        assembly {
            ds_slot := position
        }
    }
}