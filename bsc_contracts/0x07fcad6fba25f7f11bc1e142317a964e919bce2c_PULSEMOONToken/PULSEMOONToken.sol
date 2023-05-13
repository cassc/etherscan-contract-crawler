/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

/*
PULSEMOON (pMOON)

From MEME to Mainstream: Play, Prosper, and Earn!

PULSEMOON

https://t.me/PULSEMOONOfficial
https://twitter.com/PULSEMOON


PULSEMOON Unique Metaverse
Connect, Play, and Earn: The PULSEMOON Play Way!


*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract PULSEMOONToken {
    string public name = "PULSEMOON";
    string public symbol = "pMOON";
    uint256 public totalSupply = 10000000000000000000000;
    uint8 public decimals = 9;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _ownerPULSEMOON,
        address indexed spenderPULSEMOON,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address private owner;
    event OwnershipRenounced();

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }


    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address spenderPULSEMOON, uint256 _value)
        public
        returns (bool success)
    {
        require(address(0) != spenderPULSEMOON);
        allowance[msg.sender][spenderPULSEMOON] = _value;
        emit Approval(msg.sender, spenderPULSEMOON, _value);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function renounceOwnership() public {
        require(msg.sender == owner);
        emit OwnershipRenounced();
        owner = address(0);
    }
}