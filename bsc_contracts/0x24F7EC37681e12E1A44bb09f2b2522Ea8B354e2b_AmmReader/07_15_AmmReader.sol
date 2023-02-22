// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {Amm} from "./Amm.sol";
import {Decimal} from "./utils/MixedDecimal.sol";

contract AmmReader {
    using Decimal for Decimal.decimal;

    struct AmmStates {
        uint256 quoteAssetReserve;
        uint256 baseAssetReserve;
        uint256 tradeLimitRatio;
        uint256 fundingPeriod;
        string baseAssetSymbol;
        bytes32 priceFeedKey;
        address priceFeed;
    }

    function getAmmStates(address _amm)
        external
        view
        returns (AmmStates memory)
    {
        Amm amm = Amm(_amm);
        (
            Decimal.decimal memory quoteAssetReserve,
            Decimal.decimal memory baseAssetReserve
        ) = amm.getReserve();

        bytes32 priceFeedKey = amm.priceFeedKey();
        return
            AmmStates({
                quoteAssetReserve: quoteAssetReserve.toUint(),
                baseAssetReserve: baseAssetReserve.toUint(),
                tradeLimitRatio: amm.tradeLimitRatio(),
                fundingPeriod: amm.fundingPeriod(),
                priceFeed: address(amm.priceFeed()),
                priceFeedKey: priceFeedKey,
                baseAssetSymbol: bytes32ToString(priceFeedKey)
            });
    }

    // TODO: move to library
    function bytes32ToString(bytes32 _key)
        private
        pure
        returns (string memory)
    {
        uint8 length;
        while (length < 32 && _key[length] != 0) {
            length++;
        }
        bytes memory bytesArray = new bytes(length);
        for (uint256 i = 0; i < 32 && _key[i] != 0; i++) {
            bytesArray[i] = _key[i];
        }
        return string(bytesArray);
    }
}