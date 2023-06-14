// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title TraderDefs
 * @author DerivaDEX
 *
 * This library contains the common structs and enums pertaining to
 * traders.
 */
library TraderDefs {
    // Consists of trader attributes, including the DDX balance and
    // the onchain DDX wallet contract address
    struct Trader {
        uint96 ddxBalance;
        address ddxWalletContract;
    }
}