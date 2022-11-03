// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IOperatorRegistry.sol";

contract OperatorRegistry is IOperatorRegistry, AccessControl {
    mapping(address => bytes32) _operators;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setOperator(bytes32 identifier, address operator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _operators[operator] = identifier;

        emit OperatorIdentified(identifier, operator);
    }

    function getIdentifier(address operator) external view returns (bytes32) {
        return _operators[operator];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IOperatorRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}