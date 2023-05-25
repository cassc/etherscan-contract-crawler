// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BondlyToken is Ownable, ERC20 {
    //total fixed supply of 1,000,000,000 (1 billion) tokens.
    uint256 public cap = 1000000000000000000000000000;
    address burner = 0x58A058ca4B1B2B183077e830Bc929B5eb0d3330C;

    constructor () ERC20("Bondly Token", "BONDLY") public {
        super._mint(msg.sender, cap);
        transferOwnership(0x58A058ca4B1B2B183077e830Bc929B5eb0d3330C);
    }

    function setBurner(address _address) onlyOwner external {
        burner = _address;
    }

    function burn(uint256 amount) external {
        require(msg.sender == burner, 'wrong burner');
        _burn(msg.sender, amount);
    }
}