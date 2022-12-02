// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable{

    mapping(address => bool) private _governance;


    modifier onlyGovernance() {
        require(_governance[_msgSender()], "CYBER_NFT: caller is not the governance");
        _;
    }


    function addGovernance(address member) public onlyOwner {
        _governance[member] = true;
    }


    function removeGovernance(address member) public onlyOwner {
        _governance[member] = false;
    }


    function isGovernance(address member) public view returns(bool) {
        return _governance[member];
    }
}