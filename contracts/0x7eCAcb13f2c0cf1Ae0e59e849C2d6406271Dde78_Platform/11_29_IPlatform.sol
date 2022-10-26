// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPlatform {
    function onReceivePaymentTokens( address paymentTokenAddress_, uint platformCut_) external;
}