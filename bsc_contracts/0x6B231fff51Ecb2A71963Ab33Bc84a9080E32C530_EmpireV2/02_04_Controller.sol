// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controller is Ownable {
    mapping(address => bool) public operator;
    address public governance;
    event OperatorCreated(address _operator, bool _whiteList);
    event GovernanceTransfered(address oldGovernance, address newGovernance);

    modifier onlyOperator() {
        require(operator[msg.sender], "Only-Operator");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only-Governance");
        _;
    }

    constructor() {
        operator[msg.sender] = true;
        governance = msg.sender;
    }

    function setOperator(address _operator, bool _whiteList) public onlyOwner {
        operator[_operator] = _whiteList;
        emit OperatorCreated(_operator, _whiteList);
    }

    function transferGovernance(address _governance) public onlyGovernance {
        governance = _governance;
        emit GovernanceTransfered(msg.sender, governance);
    }

}