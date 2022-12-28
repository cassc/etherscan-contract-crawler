// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TestGrumpyERC20 is ERC20("test", "TST"), ERC20Permit("test")
{
    function approve(address spender, uint256 amount) public override returns (bool)
    {
        require(amount == 0 || allowance(msg.sender, spender) == 0, "Set to 0 first");
        return super.approve(spender, amount);
    }

    function transfer(address, uint256) public override pure returns (bool) 
    {
        require(false, "Blarg");
        return false;
    }

    function transferFrom(address, address, uint256) public override pure returns (bool) 
    {
        require(false, "Blarg");
        return false;
    }
}