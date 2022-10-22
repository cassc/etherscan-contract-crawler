//SPDX-License-Identifier: AFL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenBatchTransfer is Ownable {


    ERC20 public token; // Address of token contract
    address public transferOperator; // Address to manage the Transfers
    address private _token = 0xbb7438732BC43a91966a5137F6b52B3E76d42A81;

    // Modifiers
    modifier onlyOperator() {
        require(
            msg.sender == transferOperator,
            "Only operator can call this function."
        );
        _;
    }
    constructor() 
    {
        token = ERC20(_token);
        transferOperator = msg.sender;
    }


    // Events
    event NewOperator(address transferOperator);
    event WithdrawToken(address indexed owner, uint256 stakeAmount);

    function updateOperator(address newOperator) public onlyOwner {

        require(newOperator != address(0), "Invalid operator address");
        
        transferOperator = newOperator;

        emit NewOperator(newOperator);
    }

    // To withdraw tokens from contract, to deposit directly transfer to the contract
    function withdrawToken(uint256 value) public onlyOperator
    {

        // Check if contract is having required balance 
        require(token.balanceOf(address(this)) >= value, "Not enough balance in the contract");
        require(token.transfer(msg.sender, value), "Unable to transfer token to the owner account");

        emit WithdrawToken(msg.sender, value);
        
    }

    // To transfer tokens from Contract to the provided list of token holders with respective amount
    function batchTransfer(address[] calldata tokenHolders, uint256  amount) 
    external 
    onlyOperator
    {

        for(uint256 indx = 0; indx < tokenHolders.length; indx++) {
            require(token.transfer(tokenHolders[indx], amount), "Unable to transfer token to the account");
        }
    }

}