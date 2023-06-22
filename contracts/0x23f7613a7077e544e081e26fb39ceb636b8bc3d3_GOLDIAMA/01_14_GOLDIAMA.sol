//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";


contract GOLDIAMA is ERC20PresetMinterPauser, ERC20Capped, Ownable {
    uint256 private initialSupply;
    using SafeMath for uint256;
    
    constructor(string memory name, string memory symbol, address _beneficiary, uint256 _initialSupply, uint256 supply) ERC20PresetMinterPauser(name, symbol)  ERC20Capped(supply * 10 ** 8) public{
        initialSupply = _initialSupply * 10 ** 8;
        _mint(_beneficiary, initialSupply);
        
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override( ERC20Capped, ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }


}