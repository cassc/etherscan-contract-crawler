// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "../universal/UniversalRegistrar.sol";
import "./IExtensionAccess.sol";

abstract contract Access {
    UniversalRegistrar public registrar;

    constructor(UniversalRegistrar _registrar) {
        registrar = _registrar;
    }

    modifier nodeOperator(bytes32 node) {
        require(_isNodeOperator(node, msg.sender), "Caller is not a node operator");
        _;
    }

    modifier nodeApprovedOrOwner(bytes32 node) {
        require(_isNodeApprovedOrOwner(node, msg.sender), "Caller is not a node owner nor approved by owner");
        _;
    }

    function isNodeOperator(bytes32 node, address operator) public view returns (bool) {
        return _isNodeOperator(node, operator);
    }

    function isNodeApprovedOrOwner(bytes32 node, address operator) public view returns (bool) {
        return _isNodeApprovedOrOwner(node, operator);
    }

    function _isNodeOperator(bytes32 node, address addr) internal view returns (bool) {
        address owner = registrar.ownerOfNode(node);
        if (!Address.isContract(owner)) {
            return owner == addr;
        }

        try IERC165(owner).supportsInterface(type(IExtensionAccess).interfaceId) returns (bool supported) {
            if (supported) {
                return IExtensionAccess(owner).isApprovedOrOwner(addr, uint256(node)) ||
                 IExtensionAccess(owner).getOperator(uint256(node)) == addr;
            }
        } catch {}

        return owner == addr;
    }

    function _isNodeApprovedOrOwner(bytes32 node, address addr) internal view returns (bool) {
        address owner = registrar.ownerOfNode(node);
        if (!Address.isContract(owner)) {
            return owner == addr;
        }

        try IERC165(owner).supportsInterface(type(IExtensionAccess).interfaceId) returns (bool supported) {
            if (supported) {
                return IExtensionAccess(owner).isApprovedOrOwner(addr, uint256(node));
            }
        } catch {}

        return owner == addr;
    }
}