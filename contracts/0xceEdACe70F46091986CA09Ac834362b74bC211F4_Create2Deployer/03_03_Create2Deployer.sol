// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract Create2Deployer {
    using Address for address;

    event TemplateCreated(bytes32 indexed id);
    event Deployed(address indexed target);
    event Call(address indexed target, bytes data, bytes result);

    struct FunctionCall {
        address target;
        bytes data;
    }

    mapping(bytes32 => bytes) public template;

    function deployAddress(bytes memory bytecode, uint256 salt) public view returns (address addr) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );
        return address(uint160(uint256(hash)));
    }

    function templateAddress(bytes32 _templateId, uint256 salt) public view returns (address addr) {
        bytes memory _template = template[_templateId];
        require(_template.length > 0, 'INVALID_TEMPLATE');
        return deployAddress(_template, salt);
    }

    function cloneAddress(address target, uint256 salt) public view returns (address addr) {
        return Clones.predictDeterministicAddress(target, bytes32(salt));
    }

    function templateId(bytes calldata bytecode) public pure returns (bytes32) {
        return keccak256(bytecode);
    }

    function templateExists(bytes32 _templateId) public view returns (bool) {
        return template[_templateId].length > 0;
    }

    function deploy(bytes memory bytecode, uint256 salt, FunctionCall[] calldata calls) public returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr);

        call(calls);
    }

    function clone(address target, uint256 salt) public returns (address addr) {
        return Clones.cloneDeterministic(target, bytes32(salt));
    }

    function deployTemplate(bytes32 _templateId, uint256 salt, FunctionCall[] calldata calls) external returns (address) {
        bytes memory _template = template[_templateId];
        require(_template.length > 0, 'INVALID_TEMPLATE');
        return deploy(_template, salt, calls);
    }

    function createTemplate(bytes calldata bytecode) external returns (bytes32 _templateId) {
        _templateId = templateId(bytecode);
        require(!templateExists(_templateId), 'TEMPLATE_EXISTS');
        template[_templateId] = bytecode;
        emit TemplateCreated(_templateId);
    }

    function call(FunctionCall[] calldata calls) public returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            results[i] = calls[i].target.functionCall(calls[i].data);
            emit Call(calls[i].target, calls[i].data, results[i]);
        }
    }
}