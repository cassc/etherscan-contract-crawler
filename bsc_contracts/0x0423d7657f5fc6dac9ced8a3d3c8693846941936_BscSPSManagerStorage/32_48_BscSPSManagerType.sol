// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BscSPSManagerType {

    bytes32 constant CLAIM_MYSTERY_BOX_KUCOIN_WALLET = "KucoinWalletType";
    bytes32 constant CLAIM_MYSTERY_BOX_OKX_WALLET = "OkxWalletType";
    bytes32 constant CLAIM_MYSTERY_BOX_BLUE = "BlueType";
    bytes32 constant CLAIM_MYSTERY_BOX_ORANGE = "OrangeType";
    bytes32 constant CLAIM_MYSTERY_THREE_GREEN = "ThreeGreenType";

    struct SquadIdoConfig {

        //starts from 1
        uint256 stage;
        uint256 beginTime;
        uint256 endTime;
        bool enableWhiteList;
        //usd per squad, 0.035
        //35
        uint256 usdPriceNumerator;
        //1000
        uint256 usdPriceDenominator;
        //500
        uint256 usdQuota;

        uint256 periodNumber;
    }


    struct SquadIdoPeriodConfig {

        //starts from 1
        uint256 stage;
        //starts from 1
        uint256 periodNumber;
        uint256 unlockTime;
        uint256 unlockPerMillion;
    }

    struct ClaimMysteryBoxXParam {
        address who;
        bytes32[] reasons;
        bytes32[] mysteryBoxType;
        uint256[] amounts;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct RelayMysteryBoxXParam {
        address spsAddress;
        uint256[] threeGreenTokenIds;
        uint256[] kucoinWalletTokenIds;
        uint256[] okxWalletTokenIds;
        uint256[] blueTokenIds;
        uint256[] orangeTokenIds;
    }

    struct VSquadRecord {
        uint256 unlockTimestampOneMonth;
        uint256 vSquadBalanceOneMonth;

        uint256 unlockTimestampHalfYear;
        uint256 vSquadBalanceHalfYear;

        uint256 unlockTimestampOneYear;
        uint256 vSquadBalanceOneYear;

        uint256 unlockTimestampTwoYear;
        uint256 vSquadBalanceTwoYear;

        uint256 unlockTimestampFourYear;
        uint256 vSquadBalanceFourYear;
    }

    struct AirdropBoxXParam {
        AirdropBoxThreeGreenParam[] threeGreen;
        AirdropBoxKucoinWalletParam[] kucoinWallet;
        AirdropBoxOkxWalletParam[] okxWallet;
        AirdropBoxBlueParam[] blue;
        AirdropBoxOrangeParam[] orange;
    }

    struct AirdropBoxKucoinWalletParam {
        address who;
        uint256 amount;
    }

    struct AirdropBoxOkxWalletParam {
        address who;
        uint256 amount;
    }

    struct AirdropBoxThreeGreenParam {
        address who;
        uint256 amount;
    }

    struct AirdropBoxBlueParam {
        address who;
        uint256 amount;
    }

    struct AirdropBoxOrangeParam {
        address who;
        uint256 amount;
    }
}