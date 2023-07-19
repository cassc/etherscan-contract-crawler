//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Options{

    uint256 public mintCost;

    uint256 public maxSupply = 8888;
    uint256 public freeAmount = 2888;

    uint256 public maxMintAmount = 20;
    string public baseExtension = ".json";

    bool public paused = true;
    bool public revealed = true;
    string public notRevealedUri = "ipfs://notrevealedurl";

    mapping(address => uint256) public mintedFreeAmount;
    uint256 public maxFreePerWallet = 2;

    // Modifiers
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
}