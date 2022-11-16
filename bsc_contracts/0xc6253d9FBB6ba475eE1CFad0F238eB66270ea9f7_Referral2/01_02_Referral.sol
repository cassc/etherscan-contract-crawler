// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract Referral {
    address public immutable root;

    mapping(address => address) public parent;
    mapping(address => address[]) public children;

    event Registered(address indexed account, address indexed parent);

    constructor(address _root) {
        root = _root;
    }

    function isRegistered(address _account) public view returns (bool) {
        if (_account == root) {
            return true;
        }

        return parent[_account] != address(0);
    }

    function childrenCount(address _account) external view returns (uint256) {
        return children[_account].length;
    }

    function _register(address _account, address _parent) internal {
        if (_account == root) revert();
        if (_parent == address(0)) revert();
        if (isRegistered(_parent) == false) revert();

        if (isRegistered(_account) == true) return;

        parent[_account] = _parent;
        children[_parent].push(_account);

        emit Registered(_account, _parent);
    }
}