// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract DAPP is ERC20, Ownable, ERC20Permit {
    
    address public minter;
   
    constructor(address _minter) ERC20("DAPP TOKEN", "DAPP") ERC20Permit("DAPP TOKEN") {
        minter = _minter;
    }
    
    function mint(address account, uint _amount) public {
        require(msg.sender == minter, 'Only minter can mint');
        _mint(account, _amount);
    }
       
    function burn(uint _amount) public {
        _burn(msg.sender, _amount);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 4;
    }
    
     function changeMinter(address _minter) onlyOwner() public{
        minter = _minter;
    }
}