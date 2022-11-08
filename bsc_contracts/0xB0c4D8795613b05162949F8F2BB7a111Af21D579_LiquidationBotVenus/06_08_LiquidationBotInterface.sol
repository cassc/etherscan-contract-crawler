//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface LiquidationBotInterface {
    function liquidateTokenToToken(bytes memory argsData) external;
    function liquidateTokenToEth(bytes memory argsData) external;
    function liquidateEthToToken(bytes memory argsData) external;
}