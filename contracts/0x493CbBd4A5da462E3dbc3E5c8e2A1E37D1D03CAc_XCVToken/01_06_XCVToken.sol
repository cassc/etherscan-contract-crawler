// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XCVToken is ERC20("XCarnival", "XCV"), Ownable{

    uint256 public constant MAX_SUPPLY = 1000000000 * 10**18;

    constructor(){
    }

    function mint(address account, uint256 amount) external onlyOwner{
        require(amount + totalSupply() <= MAX_SUPPLY, "total amount exceeds upper limit");
        _mint(account, amount);
    }

    function burn(uint256 amount) external{
        _burn(msg.sender, amount);
    }
}