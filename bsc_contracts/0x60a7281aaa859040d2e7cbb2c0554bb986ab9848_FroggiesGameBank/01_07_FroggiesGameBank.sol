// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract FroggiesGameBank is Ownable, Pausable {

    mapping(address => uint256) public balances;
    constructor() Ownable()  {
    }
		
	event Received(address, uint);
    event WithdrawFroggies(address, uint256);
    event FundAddress(address, uint256, uint256);
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdrawFroggies(uint256 _amount) external {
        require(balances[msg.sender] >= _amount);
        emit WithdrawFroggies(msg.sender, _amount);

        IERC20 froggies = IERC20(0x7029994f28fd39ff934A96b25591D250A2183f67);
        froggies.transferFrom(address(this), msg.sender, _amount);

        uint256 reducedBalance = balances[msg.sender] - _amount;
        if (reducedBalance < 0) {
            reducedBalance = 0;
        }
        balances[msg.sender] = reducedBalance;
    }
    
    function fundAddress(address box, uint256 amount) public payable onlyOwner whenNotPaused {
        uint256 newAmount = amount + balances[box];
        emit FundAddress(box, amount, newAmount);
        balances[box] = newAmount;
    }

    function getBalanceAtAddress(address box) public view returns (uint256) {
        return balances[box];
    }

}