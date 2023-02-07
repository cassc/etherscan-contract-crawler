// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DogEthPool is OwnableUpgradeable, ReentrancyGuard {

    mapping(address => bool) public whitelist;

    function initialize() public initializer {
        __Ownable_init();
    }

    modifier onlyWL() {
        require(whitelist[msg.sender], "No Permission");
        _;
    }

    function mintByWL(address spender, uint256 amount) external onlyWL nonReentrant {
        uint256 balance = address(this).balance;
        require(amount <= balance, "No enough balance");
        payable(spender).transfer(amount);
    }

    function updateWL(address account, bool isWL) external onlyOwner {
        whitelist[account] = isWL;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(address(this)).transfer(balance);
    }

    receive() external payable {}
}