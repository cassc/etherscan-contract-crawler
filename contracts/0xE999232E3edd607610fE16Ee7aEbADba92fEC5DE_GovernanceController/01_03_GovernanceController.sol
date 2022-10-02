// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./utils/BytesLib.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract GovernanceController is Context {
   
    event FunctionOwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint indexed functionSelector);
    event AdminTransferred(address indexed previousOwner, address indexed newOwner);

    /// Map contract address to map of function identifiers to owners
    mapping(address => mapping(uint => address)) public functionOwner;

    address public admin;

    constructor(address _admin) {
        admin = _admin;
    }

    function batchFunctionCall(address[] memory targets, uint256[] memory values, bytes[] calldata calldatas) external {
        uint tarLength = targets.length;
        require(tarLength == values.length, "ER044");
        require(tarLength == calldatas.length, 'ER044');
        for (uint256 i = 0; i < tarLength; ++i) {
            functionCall(targets[i], values[i], calldatas[i]);
        }
    }

    /**
     * @notice calls a function which the msg.sender has permissions to access on a contract that is owned by this contract
     */
    function functionCall(address target, uint value, bytes calldata data) public {
        require(data.length >= 4, "ER028"); //Prevent calling fallback function for re-entry attack
        bytes memory selector = BytesLib.slice(data, 0, 4);
        uint32 functionSelector = BytesLib.toUint32(selector, 0);
        require(_msgSender() == functionOwner[target][functionSelector], 'ER024');
        (bool success, ) = target.call{value: value}(data);
        require(success, "ER022");
    } 


    /// @dev this should be called during set-up to register all functions and contracts
    function batchRegisterFunctions(address[] memory contracts, address[] memory owners, uint[] memory functionSelectors) external {
        require(_msgSender() == admin, 'ER024');
        uint contractsLength = contracts.length;
        require(contractsLength == owners.length, 'ER044');
        require(contractsLength == functionSelectors.length);
        for(uint i; i < contractsLength; ++i) {
            address contractAddress = contracts[i];
            uint functionSelector = functionSelectors[i];
            address newOwner = owners[i];
            require(functionOwner[contractAddress][functionSelector] == address(0), 'Cannot initialize an existing function');
            functionOwner[contractAddress][functionSelector] = newOwner;
        }
    }

    /**
     * @notice batch transfer ownership of functions to new owners
     */
    function batchTransferOwnership(address[] memory contracts, address[] memory owners, uint[] memory functionSelectors) external {
        uint contractsLength = contracts.length;
        require(contractsLength == owners.length, 'ER044');
        require(contractsLength == functionSelectors.length);
        for(uint i; i < contractsLength; ++i) {
            transferOwnership(contracts[i], owners[i], functionSelectors[i]);
        }
    }

    /**
     * @notice transfer the ownership of a function for a specific contract
     * @dev the contractAddress must be a contract with "owner" set to this contract
     */
    function transferOwnership(address contractAddress, address newOwner, uint functionSelector) public {
        address oldOwner = functionOwner[contractAddress][functionSelector];
        require(_msgSender() == oldOwner, 'ER024');
        functionOwner[contractAddress][functionSelector] = newOwner;
        emit FunctionOwnershipTransferred(oldOwner, newOwner, functionSelector);
    }

    /**
     * @notice allows the admin who can designate the owner for new functions to be transferred
     * @dev the admin can only register new functions and designate their owner once
     */
    function transferAdmin(address newAdmin) external {
        address oldAdmin = admin;
        require(_msgSender() == oldAdmin, 'ER024');
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

}