// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DelegateOwnership {
    mapping(address => bool) private _owners;
    mapping(address => uint256) private _delegated_layer;

    function owners(address _user) external view returns (bool) {
        return _owners[_user];
    }

    function delegated_layer(address _user) external view returns (uint256) {
        return _delegated_layer[_user];
    }

    constructor() {
        _owners[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(_owners[msg.sender], "800");
        _;
    }

    modifier onlyDelegator(address _owner) {
        if (_delegated_layer[msg.sender] != 0 || !_owners[msg.sender]) {
            require(_delegated_layer[msg.sender] < _delegated_layer[_owner], "801");
        }
        _;
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_delegated_layer[msg.sender] <= 2, "802");
        _owners[_newOwner] = true;
        _delegated_layer[_newOwner] = _delegated_layer[msg.sender] + 1;
    }

    function removeOwner(address _removedOwner) external onlyDelegator(_removedOwner) {
        _owners[_removedOwner] = false;
        _delegated_layer[_removedOwner] = 0;
    }
}