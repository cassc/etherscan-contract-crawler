// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract PickleRoyalties {

    address public a = 0xb4005DB54aDecf669BaBC3efb19B9B7E3978ebc2;
    address public b = 0x3bC076F574648beA112BdD4E1aB4c6Ac178E7116;
    uint public withdrew = 0;

    event Received(address, uint);

    constructor() {
    }

    function updateA(address _addr) public {
        require(msg.sender == a || msg.sender == b, "not authorized");
        a = _addr;
    }

    function updateB(address _addr) public {
        require(msg.sender == a || msg.sender == b, "not authorized");
        b = _addr;
    }

    function withdraw() public {
        require(msg.sender == a || msg.sender == b, "not authorized");
        withdrew += address(this).balance;
        uint _val = address(this).balance / 2;
        Address.sendValue(payable(a), _val);
        Address.sendValue(payable(b), _val);
    }

    function receiveETH() public payable {
    }
}