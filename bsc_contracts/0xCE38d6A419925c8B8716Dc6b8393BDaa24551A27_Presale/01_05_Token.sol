// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol" ;
import "./SafeMath.sol";


contract Presale {
    using SafeMath for uint;
    // Define the presale parameters
    IERC20 public  token;
    address payable public   beneficiary;
    uint public  price;
    address public owner = 0xe737Db5C7F9645459393e2FA0DA9fD46B87de6E1;

    // Keep track of the amount raised and the investor list
    uint public tokenSold;
    mapping(address => uint) public investments;

    // Define the constructor
    constructor(
        IERC20 _token,
        address _beneficiary

    ) {
        token = _token;
        beneficiary = payable(_beneficiary);
    }

    function setPrice(uint256 _price) public {
        require(msg.sender == owner, "Only the owner can set the price.");
        price = _price;
    }
    receive() external payable{ invest();} 

    function tokenForSale() public view returns(uint){
        return token.allowance(beneficiary, address(this));
    }
    // Define the invest function
    function invest() public payable {
        // Check if the investment is within the limits
        require(msg.sender != address(0), " 0 address not allowed");
        // Calculate the amount of tokens to be transferred
        uint tokens = msg.value.mul(price);
        require(tokens <= tokenForSale(), "less quantity remaining");

        
        // Transfer the tokens to the investor
        require(token.transferFrom(beneficiary, msg.sender, tokens), "Token transfer failed");

        // Update the amount raised and the investor list
        tokenSold += tokens;
        investments[msg.sender] += msg.value;

        // Transfer the invested ether to the beneficiary
        payable(beneficiary).transfer(msg.value);
    }
}
