//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;

import "../interfaces/IAddressRegistry.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

//solhint-disable var-name-mixedcase
contract BaseController {

    address public immutable manager;
    address public immutable accessControl;
    IAddressRegistry public immutable addressRegistry;

    bytes32 public immutable ADD_LIQUIDITY_ROLE = keccak256("ADD_LIQUIDITY_ROLE");
    bytes32 public immutable REMOVE_LIQUIDITY_ROLE = keccak256("REMOVE_LIQUIDITY_ROLE");
    bytes32 public immutable MISC_OPERATION_ROLE = keccak256("MISC_OPERATION_ROLE");

    constructor(address _manager, address _accessControl, address _addressRegistry) public {
        require(_manager != address(0), "INVALID_ADDRESS");
        require(_accessControl != address(0), "INVALID_ADDRESS");
        require(_addressRegistry != address(0), "INVALID_ADDRESS");

        manager = _manager;
        accessControl = _accessControl;
        addressRegistry = IAddressRegistry(_addressRegistry);
    }

    modifier onlyManager() {
        require(address(this) == manager, "NOT_MANAGER_ADDRESS");
        _;
    }

    modifier onlyAddLiquidity() {
        require(AccessControl(accessControl).hasRole(ADD_LIQUIDITY_ROLE, msg.sender), "NOT_ADD_LIQUIDITY_ROLE");
        _;
    }

    modifier onlyRemoveLiquidity() {
        require(AccessControl(accessControl).hasRole(REMOVE_LIQUIDITY_ROLE, msg.sender), "NOT_REMOVE_LIQUIDITY_ROLE");
        _;
    }

    modifier onlyMiscOperation() {
        require(AccessControl(accessControl).hasRole(MISC_OPERATION_ROLE, msg.sender), "NOT_MISC_OPERATION_ROLE");
        _;
    }
}