// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AlfheimRefundsByColiseum is Ownable, ReentrancyGuard{
    error NotAllowed();
    error InsufficientValue();

    constructor() {
        controllers[0x026A0477D732A3c66790B67Ca5e01955d4764524] = true;
    }

    mapping(address => bool) controllers;

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function refund(address[] calldata addresses) payable public {
        if ((msg.sender != owner()) && (!controllers[msg.sender])) revert NotAllowed();
        uint256 amount = msg.value / addresses.length;
        if(amount < 0.077 ether) revert InsufficientValue();

        for (uint i = 0; i < addresses.length; i++) {
             payable(addresses[i]).transfer(0.077 ether);
        }
    }
    
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}