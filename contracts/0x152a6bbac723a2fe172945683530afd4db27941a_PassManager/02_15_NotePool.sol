// SPDX-License-Identifier: MIT

/**

 @powered by: amadeus-nft.io
*/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Note.sol";

contract NotePool is Ownable, ReentrancyGuard {

    constructor(address _note) {
        note = _note;
    }

    address private note;

    function setMusicNoteAddress(address _note) external onlyOwner {
        note = _note;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function repo(uint256 amount) external {
        Note(note).burn(msg.sender, amount);
        payable(msg.sender).transfer(calculateRepoEtherAmount(amount));
    }

    function calculateRepoEtherAmount(uint256 amount) public pure returns (uint256) {
        uint256 result = 0;
        for (;amount >= 100000;) {
            result += 100000 * 0.017 ether;
            amount -= 100000;
        }
        for (;amount >= 10000;) {
            result += 10000 * 0.016 ether;
            amount -= 10000;
        }
        for (;amount >= 1000;) {
            result += 1000 * 0.015 ether;
            amount -= 1000;
        }
        for (;amount >= 100;) {
            result += 100 * 0.0145 ether;
            amount -= 100;
        }
        for (;amount >= 20;) {
            result += 20 * 0.014 ether;
            amount -= 20;
        }
        for (;amount >= 10;) {
            result += 10 * 0.0125 ether;
            amount -= 10;
        }
        for (;amount >= 5;) {
            result += 5 * 0.012 ether;
            amount -= 5;
        }
        for (;amount >= 1;) {
            result += 0.008 ether;
            amount--;
        }
        return result;
    }

    receive() external payable { }
}