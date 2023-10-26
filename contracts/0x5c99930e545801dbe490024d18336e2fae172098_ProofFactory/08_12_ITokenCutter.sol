// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface ITokenCutter {
    function swapTradingStatus() external;

    function setLaunchedAt() external;

    function cancelToken() external;
}