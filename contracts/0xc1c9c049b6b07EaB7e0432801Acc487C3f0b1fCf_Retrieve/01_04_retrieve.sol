// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Retrieve is Ownable {
    address public constant contractAddress = 0xdA727Da4b044EcEf867400421e8B27b5B6c40E8a;

    function withdraw() external onlyOwner {
        uint256 balance = payable(address(this)).balance;
        require(balance > 0, "Contract has no balance");
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed");
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(IERC20(tokenAddress).transfer(owner(), tokenAmount), "Transfer failed");
    }
}