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

    function withdraw(address payable beneficiary) public payable onlyOwner whenNotPaused {
        // TODO add event emission
        beneficiary.transfer(address(this).balance);
    }


    function withdrawFroggies(uint256 _amount) external {
        require(balances[msg.sender] >= _amount);
        emit WithdrawFroggies(msg.sender, _amount);
        //0xd563994115761f7fce8bc419be56420dc9987ee3
        IERC20 froggies = IERC20(0x7029994f28fd39ff934A96b25591D250A2183f67);
        // it seems to send the balance divided by 9 why?

        //5 * 10^9 where 9 is decimal
        //https://docs.openzeppelin.com/contracts/3.x/erc20
        froggies.transfer(msg.sender, _amount * 10^9);
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
    // old but did work
    function withdrawToken(address _tokenContract, uint256 _amount) external {
        IERC20 tokenContract = IERC20(_tokenContract);
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        // TODO add event emission
        tokenContract.transfer(msg.sender, _amount);
    }

    

    
    /*
    
        this didn't work

    function withdrawBox(address box) external {
        require(msg.sender == box);
        require(balances[box] != 0);

        // do we even need the address here?
        // shouldnt it be any address can call this
    
        // froggies contract on bsc test net is same
        address froggies = 0xcC1873C2D5eb2C5f9B503F96a316cF059b3a75F7;

        IERC20 tokenContract = IERC20(froggies);
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, balances[box]);
        balances[box] = 0;
    }
    */
		


}