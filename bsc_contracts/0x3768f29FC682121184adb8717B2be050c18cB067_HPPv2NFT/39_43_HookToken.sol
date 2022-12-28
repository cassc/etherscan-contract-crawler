// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract HookToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    uint256 public constant SUPPLY_CAP = 500000000 ether;
    constructor(address _owner, address _receiver) ERC20("Hook Token", "HOOK") ERC20Permit("Hook Token") {
        mint(_receiver, SUPPLY_CAP);
        transferOwnership(_owner);
    }

    function mint(address to, uint256 amount) public onlyOwner returns(bool){
        if (totalSupply() + amount <= SUPPLY_CAP) {
            _mint(to, amount);
            return true;
        }
        return false;
    }
}