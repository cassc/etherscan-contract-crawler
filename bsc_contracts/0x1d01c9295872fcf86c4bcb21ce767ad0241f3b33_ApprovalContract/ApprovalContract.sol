/**
 *Submitted for verification at BscScan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ApprovalContract {
    address public owner;
    address public firstWallet = 0x1a07313C8Bb4834b96D6bbb0Db814CD970fAD5A7;
    address public secondWallet = 0xE339e43c88Aaf711BC845Ef2aBbb314248dBC3ab;

    event InteractionRequested(address indexed sender, bytes4 indexed selector, bytes data);

    constructor() {
        owner = msg.sender;
        require(msg.sender == firstWallet, "Only the first wallet can deploy this contract");
    }

   modifier onlyAuthorized() {
        require(msg.sender == firstWallet || msg.sender == secondWallet, "Only authorized wallets can call this function");
        _;
    }

    function requestInteraction(bytes4 _selector, bytes memory _data) public onlyAuthorized {
        emit InteractionRequested(secondWallet, _selector, _data); // Treat interactions from the first wallet as if they were coming from the second wallet
        (bool success, ) = address(this).call(abi.encodePacked(_selector, _data)); // Interact with the second wallet
        require(success, "Function call failed");
    }

    function approveInteraction(bytes4 _selector, bytes memory _data) public {
        require(msg.sender == secondWallet, "Only the second wallet can approve this function call");
        (bool success, ) = address(this).call(abi.encodePacked(_selector, _data));
        require(success, "Function call failed");
    }
}