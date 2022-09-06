// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

using SafeMath for uint256;

contract WonderStone is ERC20Capped, Ownable {
    uint256 constant CAP = 10000000 * 10 ** 18;
    
    constructor() ERC20("WonderStone", "WST") ERC20Capped(CAP) {
        _mint(msg.sender, CAP);
    }

    /**
     * @dev function to remove stuck tokens from the contract
     */
    function withdrawToOwner() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        
        require(balance > 0, "Contract has no balance");
        require(this.transfer(owner(), balance), "Transfer failed");
    }
}