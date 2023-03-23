// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferHelper.sol";
import "./DexData.sol";

library Aggregator1InchV5 {
    using TransferHelper for IERC20;
    using DexData for bytes;

    bytes4 constant UNISWAP_V3_SWAP = 0xe449022e;
    bytes4 constant UNO_SWAP = 0x0502b1c5;
    bytes4 constant SWAP = 0x12aa3caf;
    uint constant default_length = 32;

    function swap1inch(
        address router,
        bytes memory data,
        address payee,
        address buyToken,
        address sellToken,
        uint sellAmount,
        uint minBuyAmount
    ) internal returns (uint boughtAmount) {
        bytes4 functionName = getCallFunctionName(data);
        if (functionName != UNISWAP_V3_SWAP) {
            // verify sell token
            require(to1InchSellToken(data, functionName) == sellToken, "sell token error");
        }
        data = replace1InchSellAmount(data, functionName, sellAmount);
        uint buyTokenBalanceBefore = IERC20(buyToken).balanceOf(payee);
        IERC20(sellToken).safeApprove(router, sellAmount);
        (bool success, bytes memory returnData) = router.call(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        IERC20(sellToken).safeApprove(router, 0);
        boughtAmount = IERC20(buyToken).balanceOf(payee) - buyTokenBalanceBefore;
        require(boughtAmount >= minBuyAmount, "1inch: buy amount less than min");
    }

    function getCallFunctionName(bytes memory data) private pure returns (bytes4 bts) {
        bytes memory subData = DexData.subByte(data, 0, 4);
        assembly {
            bts := mload(add(subData, 32))
        }
    }

    function replace1InchSellAmount(bytes memory data, bytes4 functionName, uint sellAmount) private pure returns (bytes memory) {
        uint startIndex;
        if (functionName == SWAP) {
            startIndex = 164;
        } else if (functionName == UNO_SWAP) {
            startIndex = 36;
        } else if (functionName == UNISWAP_V3_SWAP) {
            startIndex = 4;
        } else {
            revert("USF");
        }
        bytes memory b1 = DexData.concat(DexData.subByte(data, 0, startIndex), DexData.toBytes(sellAmount));
        uint secondIndex = startIndex + default_length;
        return DexData.concat(b1, DexData.subByte(data, secondIndex, data.length - secondIndex));
    }

    function to1InchSellToken(bytes memory data, bytes4 functionName) private pure returns (address) {
        uint startIndex;
        if (functionName == SWAP) {
            startIndex = 36;
        } else if (functionName == UNO_SWAP) {
            startIndex = 4;
        } else {
            revert("USF");
        }
        bytes memory bts = DexData.subByte(data, startIndex, default_length);
        return DexData.bytesToAddress(bts);
    }
}