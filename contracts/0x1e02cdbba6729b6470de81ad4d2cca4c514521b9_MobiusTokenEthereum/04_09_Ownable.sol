pragma solidity =0.8.4;

// SPDX-License-Identifier: MIT
import '../lib/Strings.sol';
import './Constants.sol';
import '../interfaces/IOwnable.sol';

contract Ownable is Constants, IOwnable {
    using Strings for string;

    string public override contractName;
    address public owner;
    address public manager;

    constructor() {
        owner = msg.sender;
        manager = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, contractName.concat(': caller is not the owner'));
        _;
    }

    modifier onlyManager(bytes32 managerName) {
        require(msg.sender == manager, contractName.concat(': caller is not the ', managerName));
        _;
    }

    modifier allManager() {
        require(
            msg.sender == manager || msg.sender == owner,
            contractName.concat(': caller is not the manager or the owner')
        );
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        require(_owner != address(0), contractName.concat(': new owner is the zero address'));
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function setManager(address _manager) public virtual onlyOwner {
        require(_manager != address(0), contractName.concat(': new manager is the zero address'));
        emit ManagerChanged(manager, _manager);
        manager = _manager;
    }

    function setContractName(bytes32 _contractName) internal {
        contractName = string(abi.encodePacked(_contractName));
    }
}