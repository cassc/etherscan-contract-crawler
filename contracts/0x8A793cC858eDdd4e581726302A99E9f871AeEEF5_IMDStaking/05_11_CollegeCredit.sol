pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICollegeCredit.sol";

contract CollegeCredit is ERC20, Ownable, ICollegeCredit {
    constructor() ERC20("College Credit", "CREDIT") {}
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function mint(address recipient, uint256 amount) override external onlyOwner {
        _mint(recipient, amount);
    }
}