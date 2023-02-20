/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// File: SecretWhitelist.sol



pragma solidity ^0.8.0;

contract WhiteList {
    mapping(address => bool) public whiteList;
    uint8 public counter = 0;

    function whiteListMeTest(string calldata secret) external {
        require(counter < 10, "Whitelist already closed");
        require(!whiteList[msg.sender], "Already whitelisted");
        
        bytes32 h = keccak256(bytes(secret));
        require(h == bytes32(0xeeed54591aee9886958337c4cf97909423c6e43ef5a9b97988708bf6f0797319), "Wrong Secret");
        counter = counter + 1;
        whiteList[msg.sender] = true;
    }

    function checkWhitelist(address addr) public view returns(bool) {
        return whiteList[addr];
    }
}