pragma solidity ^0.8.0;

contract Governance {
    mapping(address => bool) public _governance;

    constructor() {
        _governance[tx.origin] = true;
    }

    modifier onlyGovernance {
        require(_governance[msg.sender], "not governance");
        _;
    }

    function setGovernance(address governance) public onlyGovernance {
        require(governance != address(0), "new governance the zero address");
        _governance[governance] = true;
    }
}