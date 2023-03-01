//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Mintable.sol";
import "./Burnable.sol";
import "./Ownable.sol";

abstract contract Rules is Ownable, Mintable, Burnable
{

    function mint(address account, uint256 amount) override public onlyOwner
    {
        super.mint(account,amount);
    }

    function burn(address account, uint256 amount) override public onlyOwner
    {
        super.burn(account,amount);
    }
}