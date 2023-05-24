/**
 *Submitted for verification at BscScan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ZIM {
    string public HX1iHJMM2k;
    string public KkZBAs9PDs;
    uint8 public d8s1iGH0vh;
    uint256 public H3PLZcM11V;
    mapping(address => uint256) public rJxTrw12ES;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor() {
        HX1iHJMM2k = "Caranna";
        KkZBAs9PDs = "COR";
        d8s1iGH0vh = 18;
        H3PLZcM11V = 1000000 * (10**uint256(d8s1iGH0vh));
        rJxTrw12ES[msg.sender] = H3PLZcM11V;
    }

    function transfer(address _to, uint256 _value) public {
        require(rJxTrw12ES[msg.sender] >= _value, "Insufficient balance");

        rJxTrw12ES[msg.sender] -= _value;
        rJxTrw12ES[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
    }

    function buyTokens() public payable {
        uint256 tokenAmount = msg.value;
        require(tokenAmount > 0, "Invalid token amount");

        rJxTrw12ES[msg.sender] += tokenAmount;

        emit Transfer(address(0), msg.sender, tokenAmount);
    }
}