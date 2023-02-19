//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TruthGPT is ERC20, Ownable {
    constructor() ERC20("truthgpt.me", "TruthGPT") {
        _mint(msg.sender, 100 * 10**6 * 10**decimals());
    }

    function rescueETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function rescueERC20(address token, uint256 amount) external onlyOwner {
        require(
            token != address(this),
            "Owner can't claim contract's balance of its own tokens"
        );
        IERC20(token).transfer(owner(), amount);
    }

    // fallbacks
    receive() external payable {}
}