// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./receiver.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Factory is AccessControl {
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    address public saasImp;

    event SaasCreated(address indexed);

    constructor(address imp) {
        saasImp = imp;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEPLOYER_ROLE, msg.sender);
    }

    function deploySaas(
        address vault
    ) external onlyRole(DEPLOYER_ROLE) returns (address instance) {
        instance = Clones.clone(saasImp);
        (bool success, ) = instance.call(
            abi.encodeWithSignature("initialize(address)", vault)
        );
        require(success);
        emit SaasCreated(instance);
        return instance;
    }
}