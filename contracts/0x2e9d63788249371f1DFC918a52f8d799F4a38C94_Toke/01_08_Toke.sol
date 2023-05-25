// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Toke is ERC20Pausable, Ownable  {
    uint256 private constant SUPPLY = 100_000_000e18;
    constructor() public ERC20("Tokemak", "TOKE")  {        
        _mint(msg.sender, SUPPLY); // 100M
    }

    function pause() external onlyOwner {        
        _pause();
    }

    function unpause() external onlyOwner {        
        _unpause();
    }
}