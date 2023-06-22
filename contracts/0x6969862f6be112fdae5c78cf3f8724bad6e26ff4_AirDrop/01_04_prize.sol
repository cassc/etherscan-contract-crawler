// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AirDrop is Ownable {
    IERC20 public token;
    uint256 public constant CLAIM_AMOUNT = 777 * 10**15;  // Adjusted for tokens
    uint256 public constant ETH_AMOUNT = 0.00777 ether; // For Ether
    mapping(address => bool) public claimants;

    uint256 private nonce;

    event Claimed(address claimant);

    constructor() {
        token = IERC20(0x5091cFed6b48a3CA20f2f845a0BEeD791117087C);
    }

    function getRandomNumber() private returns (uint256) {
        nonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce)));
    }

    function claim() external {
        require(!claimants[msg.sender], "Claimant has already claimed tokens");
        require(token.balanceOf(address(this)) >= CLAIM_AMOUNT, "Not enough tokens left");
        require(address(this).balance >= ETH_AMOUNT, "Not enough Ether left");

        claimants[msg.sender] = true;
        token.transfer(msg.sender, CLAIM_AMOUNT);

        emit Claimed(msg.sender);

        uint256 randomNumber = getRandomNumber();
        
        if (randomNumber % 777 == 0) {
            payable(msg.sender).transfer(ETH_AMOUNT);
        }
    }

    receive() external payable {}
}