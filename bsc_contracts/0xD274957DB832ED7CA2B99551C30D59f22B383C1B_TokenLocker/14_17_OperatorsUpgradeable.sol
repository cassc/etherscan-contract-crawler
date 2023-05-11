// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IOperators.sol";

contract OperatorsUpgradeable is OwnableUpgradeable, IOperators {
    mapping(address => bool) private operators;

    function __Operators_init() internal initializer {
        __Ownable_init();
        operators[msg.sender] = true;
    }

    function setOper(address _a, bool _b) external override onlyOwner {
        operators[_a] = _b;
    }

    function isOper(address _a) external view override returns (bool) {
        return operators[_a];
    }

    modifier onlyOper() {
        require(operators[msg.sender], "caller is not the oper");
        _;
    }
}