/**
 *Submitted for verification at Etherscan.io on 2020-03-02
*/

pragma solidity ^0.4.21;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if(msg.sender != owner) revert();
        _;
    }

    function tranferOwnership(address _newOwner) public onlyOwner() {
        owner = _newOwner;
    }
}

contract Token {
    function mintTokens(address _atAddress, uint256 _amount) public;
}

contract TokenGeneration is owned {
    Token token;

    function setToken(address _token) public onlyOwner {
        token = Token(_token);
    }

    function generateTokens(address[] _addresses, uint256[] _amount) public onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            token.mintTokens(_addresses[i], _amount[i]);
        }
    }

    function getToken() public constant returns(address) {
        return address(token);
    }
}