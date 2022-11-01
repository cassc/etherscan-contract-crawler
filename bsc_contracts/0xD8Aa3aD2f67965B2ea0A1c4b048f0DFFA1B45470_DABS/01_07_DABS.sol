// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DABS is ERC20, ERC20Burnable, Ownable {
    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

    event GrantModRole(address _user);

    event RevokeModeRole(address _user);

    mapping (address => bool) public isBlackListed;    
    mapping (address =>bool) public isMode;

    constructor() ERC20("DABASE","DABS") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    modifier onlyMod() {
        require(isMode[msg.sender],"TS: caller is not mod");
        _;
    }

    function grantMode(address user) external onlyOwner{
        isMode[user] = true;
        emit GrantModRole(user);
    }
    function revodeMode(address user) external onlyOwner {
        isMode[user] = false;
        emit RevokeModeRole(user);
    }

    function addBlackList (address _evilUser) public onlyMod {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyMod {
        isBlackListed[_clearedUser] = false;
        emit  RemovedBlackList(_clearedUser);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal        
        override
    {
        require(!isBlackListed[from],"TS: Transfer from blacklist!");        
        super._beforeTokenTransfer(from, to, amount);
    }
    
}