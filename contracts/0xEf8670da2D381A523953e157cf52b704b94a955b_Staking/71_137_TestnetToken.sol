// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestnetToken is ERC20Pausable, Ownable  {
    
    //solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory symbol, uint8 decimals) public ERC20(name, symbol)  {
        _setupDecimals(decimals);
     }

    function mint(address to, uint256 amount) external onlyOwner {        
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {        
        _burn(from, amount);
    }

    function pause() external onlyOwner {        
        _pause();
    }

    function unpause() external onlyOwner {        
        _unpause();
    }
}