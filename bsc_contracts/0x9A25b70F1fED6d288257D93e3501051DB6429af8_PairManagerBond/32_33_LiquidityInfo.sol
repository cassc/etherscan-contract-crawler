// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library LiquidityInfo {
    struct Data {
        bytes32 poolId;
        //        uint80 lowerLimit;
        //        uint80 upperLimit;
        //        // gridData contains gridType and gridCount packed in a 16 bit slot
        //        // because solidity only store minimum 8 bit, so we need to pack and unpack manually
        //        // gridType is the fist bit 0 or 1 (0 for arithmetic, 1 for geometric) - if add anyother type
        //        // will need refactor the pack and unpack Grid Data
        //        // gridCount can store up to 15 bits with the maximum 32767
        //        uint16 gridData;
        uint128 baseAmount;
        uint128 quoteAmount;
        // consider packed or remove?
        uint128 priceOfFundingCertificate; // Reward debt. See explanation below.
        uint128 amountOfFC;
        uint128 quoteDeposited;
    }

    // manually tested on Remix
    function packGridData(uint8 gridType, uint16 gridCount)
        internal
        pure
        returns (uint16 gridData)
    {
        require(gridCount <= 32767, "gridCount must <= 32767");
        // WARNING: if you want to change gridType > 1, you need to re-write the packing slot below
        // becuase 1 bit can only store 0 or 1
        require(gridType <= 1, "gridType must <= 1");
        gridData = (gridType << 15) | gridCount;
    }

    function unpackGridData(uint16 gridData)
        internal
        pure
        returns (uint8 gridType, uint16 gridCount)
    {
        gridType = uint8(gridData >> 15);
        gridCount = gridData & 0x7FFF; // gridData & 32767
        /*
        EG:
        let gridType = 1, gridCount = 1123 => gridData = 33891
        0x463	    1000010001100011	33891
        &	0x7fff	0111111111111111	32767
        =	0x463	0000010001100011	1123

        let gridType = 1, gridCount = 1123 => gridData = 1123
        0x463	    0000010001100011	1123
        &	0x7fff	0111111111111111	32767
        =	0x463	0000010001100011	1123
        */
    }
}