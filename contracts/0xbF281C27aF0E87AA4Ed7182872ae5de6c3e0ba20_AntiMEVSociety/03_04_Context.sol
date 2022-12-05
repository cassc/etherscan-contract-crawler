// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Inspo: https://etherscan.io/address/0xd65960facb8e4a2dfcb2c2212cb2e44a02e2a57e#code

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}