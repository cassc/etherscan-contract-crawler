//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./ITransferProxy.sol";

abstract contract OperatorRole is OwnableUpgradeable {
    mapping(address => bool) public operators;

    function setOperator(address _operator, bool _value) external onlyOwner {
        _setOperator(_operator, _value);
    }

    function setOperators(address[] memory _operators, bool[] memory _values)
        external
        onlyOwner
    {
        require(
            _operators.length == _values.length,
            "OperatorRole: operators and values length mismatch"
        );
        uint256 length = _operators.length;
        for (uint256 i = 0; i < length; i++) {
            _setOperator(_operators[i], _values[i]);
        }
    }

    function _setOperator(address operator, bool value) internal {
        operators[operator] = value;
    }

    modifier onlyOperator() {
        require(
            operators[_msgSender()],
            "OperatorRole: caller is not the operator"
        );
        _;
    }

    uint256[50] private __gap;
}