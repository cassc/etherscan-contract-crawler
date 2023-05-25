// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.14;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Delegated is Context, Ownable {
    mapping(address => bool) private delegates;

    constructor() {
        delegates[_msgSender()] = true;
    }

    modifier onlyDelegates() {
        require(delegates[msg.sender], "DELEGATED: caller is not delegated");
        _;
    }

    function isDelegated(address _a) public view returns (bool) {
        return delegates[_a];
    }

    function setDelegated(address _a, bool _bool) public onlyOwner {
        delegates[_a] = _bool;
    }
}