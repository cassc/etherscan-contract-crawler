// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AirDrop is Ownable {
    IERC20 public token;
    uint256 public constant CLAIM_AMOUNT = 777 * 10**18;
    mapping(address => bool) public claimants;

    event Claimed(address claimant);

    constructor() {
        token = IERC20(0x5091cFed6b48a3CA20f2f845a0BEeD791117087C);
    }

    function claim() external {
        require(!claimants[msg.sender], "Claimant has already claimed tokens");
        require(token.balanceOf(address(this)) >= CLAIM_AMOUNT, "Not enough tokens left");

        claimants[msg.sender] = true; 
        token.transfer(msg.sender, CLAIM_AMOUNT);

        emit Claimed(msg.sender);
    }
}