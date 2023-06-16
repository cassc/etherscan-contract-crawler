// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IVaultParentManager {
    function requestBridgeToChain(
        uint16 dstChainId,
        address asset,
        uint256 amount,
        uint256 minAmountOut,
        uint lzFee
    ) external payable;

    function requestCreateChild(uint16 newChainId, uint lzFee) external payable;

    function sendBridgeApproval(uint16 dstChainId, uint lzFee) external payable;

    function changeManagerMultiChain(
        address newManager,
        uint[] memory lzFees
    ) external payable;

    function setDiscountForHolding(
        uint256 tokenId,
        uint256 streamingFeeDiscount,
        uint256 performanceFeeDiscount
    ) external;
}