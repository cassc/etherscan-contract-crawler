// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TestERC20 is ERC20("test", "TST"), ERC20Permit("test")
{
    uint8 _decimals = 18;
    constructor() 
    {
        _mint(msg.sender, 1000000000 ether);
    }
    function decimals() public view virtual override returns (uint8) { return _decimals; }
    function setDecimals(uint8 __decimals) public { _decimals = __decimals; }
    function mint(address user, uint256 amount) public { _mint(user, amount); }
}