//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ISANPASS {
    struct factionCredits {
        uint8 chi;
        uint8 umi;
        uint8 sora;
        uint8 mecha;
        uint8 none;
    }

    enum Id {
        UNUSED,
        Chi,
        Umi,
        Sora,
        Mecha,
        None,
        VIP,
        Redvoxx
    }

    enum SaleState {
        Paused, // 0
        Open    // 1
    }

    event Sacrifice(
        address indexed sacrificer
    );

    event SaleStateChanged(
        SaleState newSaleState
    );

    error ExceedsMaxRoyaltiesPercentage();
    error SaleStateNotActive();
}