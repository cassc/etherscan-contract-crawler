// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bitch is ERC20, Ownable {

    constructor() ERC20("Bitch coin", "Bitch") {
        _mint(msg.sender, 999_900_000_000 * 10 ** 18);
    }

    function withdrawETH() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}

}