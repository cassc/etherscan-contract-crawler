// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAllowed {
    function isCustomFeeReceiverOrSender(address sender, address receiver)
        external
        view
        returns (bool);
}