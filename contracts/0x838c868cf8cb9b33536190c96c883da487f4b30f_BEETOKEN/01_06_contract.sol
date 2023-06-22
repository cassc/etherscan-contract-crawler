// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BEETOKEN is Ownable, ERC20 {
    //tokenname, displayname
    constructor() ERC20("BEETOKEN", "BEE COIN") {
        // Mint 69 tokens to contract deployer
        _mint(msg.sender, 69 * 10 ** decimals());
    }

    receive() external payable {}

    function sendEther(
        address payable recipient,
        uint256 amountInWei
    ) external onlyOwner {
        require(address(this).balance >= amountInWei, "Insufficient balance");
        recipient.transfer(amountInWei);
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount * 10 ** decimals());
    }
}