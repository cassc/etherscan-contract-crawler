// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/proxy/Clones.sol';

import 'hardhat/console.sol';

interface Instance {
    function initialize() external;
}

contract PayrollFactory is Ownable, Pausable {
    uint private nonce = 0;
    address public masterInstance;
    mapping(address => address) public instances;

    event InstanceCreated(address indexed owner, address indexed instance);
    event InstanceOwnerChanged(address indexed instance, address oldOwner, address newOwner);
    event MasterInstanceSet(address indexed oldInstance, address indexed newInstance);

    constructor() {
        _transferOwnership(tx.origin);
    }

    function create() external whenNotPaused {
        require(masterInstance != address(0), 'PayrollFactory(create): master instance not set');
        require(address(instances[msg.sender]) == address(0), 'PayrollFactory(create): sender already have owned instance');

        bytes32 salt = keccak256(abi.encodePacked(block.chainid, nonce++));
        instances[msg.sender] = Clones.cloneDeterministic(masterInstance, salt);
        Instance(instances[msg.sender]).initialize();
        Ownable(instances[msg.sender]).transferOwnership(msg.sender);

        emit InstanceCreated(msg.sender, instances[msg.sender]);
    }

    function updateOwner(address currentOwner, address newOwner) external {
        if (currentOwner == newOwner) {
            return;
        }
        if (currentOwner == address(this)) {
            return;
        }
        require(newOwner != address(this), 'PayrollFactory(updateOwner): factory can not be an employer');

        require(instances[currentOwner] == msg.sender, 'PayrollFactory(updateOwner): unknown instance');

        if (newOwner != address(0)) {
            require(address(instances[newOwner]) == address(0), 'PayrollFactory(updateOwner): newOwner already have owned instance');
            instances[newOwner] = msg.sender;
        }

        instances[currentOwner] = address(0);

        emit InstanceOwnerChanged(msg.sender, currentOwner, newOwner);
    }

    function setPause(bool pause) external onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setMasterInstance(address newInstance) public onlyOwner {
        require(newInstance != address(0), 'PayrollFactory(setMasterInstance): master instance address can not be a zero');
        require(newInstance != address(this), 'PayrollFactory(setMasterInstance): factory can not be a master instance');
        require(newInstance != masterInstance, 'PayrollFactory(setMasterInstance): that master instance already set');
        address oldInstance = masterInstance;
        masterInstance = newInstance;
        emit MasterInstanceSet(oldInstance, newInstance);
    }
}