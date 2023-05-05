//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Types {
    enum TokenStandard {
        ERC721,
        ERC1155
    }

    enum PaymentMethod {
        NATIVE_TOKEN,
        BRN_TOKEN
    }

    enum PaymentOptions {
        FixedPrice,
        OpenForBids,
        TimedAuction
    }
}