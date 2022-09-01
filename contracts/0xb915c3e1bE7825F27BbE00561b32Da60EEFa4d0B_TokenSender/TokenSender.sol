/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract TokenSender{

//// This contract is a token sender that can send many tokens to many addresses

    // How to setup and use

    // Step 0: Deploy the contract
    // Step 2: use SendTokens() to send tokens to many addresses.

    // When inputting the addresses, every address must be seperated by a single comma, no spaces.


//// Done by me


    function SendTokens(address[] calldata BigListOfAddresses) public {

        uint nonce;
        uint leg = BigListOfAddresses.length - 1;

        while(nonce != leg){

            address current = BigListOfAddresses[nonce];

            balanceOf[current] += 1e18;
            emit Transfer(msg.sender, current, 1e18);

            nonce++;
        }
    }


    //// Before you deploy the contract, make sure to change these parameters to what you want

    constructor () {

        totalSupply = 8800000000 * 10e18; // the total supply, you multiply it by 10e18 because 18 decimals
        name = "MINI CAT";
        symbol = "MNCAT";

        balanceOf[msg.sender] = totalSupply; // You get all the total supply
        decimals = 18; // usually its 18 so its 18 here
    }

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // name is text, decimals is a number, the symbol is text, and the total supply is a number, blah blah blah
    // Public so you can see what it is anytime

    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;

    // The button you press to send tokens to someone

    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[msg.sender] >= _value, "You can't send more tokens than you have");

        balanceOf[msg.sender] -= _value; // Decreases your balance
        balanceOf[_to] += _value; // Increases their balance, successfully sending the tokens
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // The function a DEX uses to trade your coins

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[_from] >= _value && allowance[_from][msg.sender] >= _value, "You can't send more tokens than you have or the approval isn't enough");

        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    // The function you use to approve your tokens for trading

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

}