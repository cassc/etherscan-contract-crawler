// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract HolderRaiser is Ownable{
    address public constant SFC = 0x666cACA3EDeADF4a228a26b377CB3Eee1E45A605;
    
    address[] public holders;
    uint public holderCount;
    uint public lastTransfer;
    uint public amount;
    uint public tokenBalance;

    function addHolder(address[] calldata _holders) public onlyOwner {
        for(uint i = 0; i < _holders.length; i++) {
            holders.push(_holders[i]);
            holderCount++;
        }
    }

    function sendToHolders() public onlyOwner {
       require(((holderCount - lastTransfer) * amount) < tokenBalance, "BALANCE ERR");
       
       for(uint i = lastTransfer; i < holderCount; i++) {
           IERC20(SFC).transfer(holders[i], amount);
           lastTransfer++;
       }
    }

    function setAmount(uint _amount) public onlyOwner {
        amount = _amount;
    }

    function updateTokenBalance() public onlyOwner {
        tokenBalance = IERC20(SFC).balanceOf(address(this));
    }

     function emergencyWithdraw() public onlyOwner {
       uint balance = IERC20(SFC).balanceOf(address(this));
       IERC20(SFC).transfer(msg.sender, balance);
	   tokenBalance -= balance;
    }

}