/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

/*

Twitter: https://twitter.com/PSYOP_BRC/status/1664055527633047553?s=20

TG: https://t.me/psyopbrc

Discord: https://discord.com/invite/psyopbrc

The FIRST ever BRC-20 launch on PinkSale, as a holder you shouldn't worry about how to invest in BRC-20. We make it easy with the first ever dApp to allow you to transfer from ERC-20 ➡️ BRC-20.

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BRC20 {
    string public name = 'Ordinal Psyop';
    string public symbol = 'BRC20';
    uint8 public decimals = 9;
    uint256 public totalSupply = 1000000000 * 10 ** decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer(address _from, address _to, uint256 _value) private {
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}