// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IOpenOceanRouter {
    struct CallDescription {
        uint256 target;
        uint256 gasLimit;
        uint256 value;
        bytes data;
    }

    struct SwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 guaranteedAmount;
        uint256 flags;
        address referrer;
        bytes permit;
    }

    function swap(
        address caller,
        SwapDescription calldata desc,
        CallDescription[] calldata calls
    ) external payable returns (uint256 returnAmount); // 0x90411a32

    function uniswapV3SwapTo(
        address recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount); //0xbc80f1a8

    function callUniswapTo(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools, /* pools */
        address recipient
    ) external payable returns (uint256 returnAmount); //0x6b58f2f0
}