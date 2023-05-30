/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TreasureHunt {

    address public owner;
    uint256 public claimableAmount;
    mapping (address => bool) public whitelisted;

    constructor() {
        owner = msg.sender;
        claimableAmount = 20000000000000000;
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function drain() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function changeClaimableAmount(uint256 newClaimableAmount) external onlyOwner {
        claimableAmount = newClaimableAmount;
    }


    function whitelistAddress(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }

    function claim() external {
        require(whitelisted[msg.sender], "ONLY_WHITELISTED");
        whitelisted[msg.sender] = false;
        payable(msg.sender).transfer(claimableAmount);
    }

}