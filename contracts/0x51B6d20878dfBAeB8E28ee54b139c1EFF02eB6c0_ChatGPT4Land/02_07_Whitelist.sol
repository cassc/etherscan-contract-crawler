// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// from openzeppelin
import "@openzeppelin/contracts/access/Ownable.sol";

// White list contract
contract Whitelist is Ownable{

    constructor() {}

    // white list wallets
    mapping(address => uint256) public whitelistWallets;


    // add wallets to white list
    function addWhitelist(address[] calldata receivers) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            whitelistWallets[receivers[i]] = 1;
        }
    }

    // is a wallet in whitelist
    function isInWhitelist(address wallet) public view returns(bool){
        return whitelistWallets[wallet] == 1;
    }

}