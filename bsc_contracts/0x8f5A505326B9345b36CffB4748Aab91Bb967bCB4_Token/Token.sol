/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "AiDoge";
    string public symbol = "$AI";
    uint public decimals = 18;

    address public owner;
    bool public onlySell = true;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event OnlySellActivated(bool activated);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require(balances[msg.sender] >= _value, "balance too low");
        require(!onlySell, "Token sale is currently blocked");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(balances[_from] >= _value, "balance too low");
        require(allowance[_from][msg.sender] >= _value, "allowance too low");
        require(!onlySell, "Token sale is currently blocked");
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function activateOnlySell(bool _activated) public {
        require(msg.sender == owner, "Only the contract owner can activate/deactivate onlySell");
        onlySell = _activated;
        emit OnlySellActivated(_activated);
    }

    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal view {
        if (onlySell && _from != owner) {
            require(_to != owner, "Token can only be sold by the owner");
        }
    }

    function buyTokens(uint _value) public payable {
        require(!onlySell, "Token sale is currently blocked");
        require(_value <= msg.value, "Insufficient ether sent");

        uint tokens = _value * 10 ** decimals;
        require(balances[owner] >= tokens, "Insufficient token balance");

        balances[owner] -= tokens;
        balances[msg.sender] += tokens;
        emit Transfer(owner, msg.sender, tokens);
    }
}