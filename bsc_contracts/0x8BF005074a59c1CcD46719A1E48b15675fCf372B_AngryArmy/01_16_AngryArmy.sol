// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract AngryArmy is ERC20, ERC20Permit, ERC20Votes, Ownable {

    uint256[] public burnInfo;
    
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol) ERC20Permit(_name) {
        _mint(msg.sender, _totalSupply * 10**decimals());
    }

    function decimals() 
        public 
        pure 
        override(ERC20)
        returns (uint8) 
    {
        return 18;
    }

    function burn(address account, uint256 amount)
        external
        onlyOwner()
    {
        _burn(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        burnInfo.push(amount);
        super._burn(account, amount);
    }
}