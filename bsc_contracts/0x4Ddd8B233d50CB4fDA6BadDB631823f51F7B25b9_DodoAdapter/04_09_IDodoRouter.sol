//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IDodoRouter {
    function mixSwap(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory mixAdapters,
        address[] memory mixPairs,
        address[] memory assetTo,
        uint256 directions,
        bytes[] memory moreInfos,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);

    function _DODO_APPROVE_PROXY_() external view returns (address);
}