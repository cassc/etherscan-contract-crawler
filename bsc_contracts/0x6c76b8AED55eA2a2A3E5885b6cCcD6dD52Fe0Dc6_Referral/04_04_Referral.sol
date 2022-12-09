// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Referral is Ownable {
    mapping(address => bool) public top;
    mapping(address => address) public parent;
    mapping(address => address[]) public children;

    event Registered(address indexed account, address indexed parent);

    constructor(address[] memory _tops) {
        for (uint i = 0; i < _tops.length; i++) {
            top[_tops[i]] = true;
            emit Registered(_tops[i], address(0));
        }
    }

    function addTop(address _top) public onlyOwner {
        if (registered(_top)) revert();
        top[_top] = true;
    }

    function registered(address _account) public view returns (bool) {
        return top[_account] || parent[_account] != address(0);
    }

    function childrenCount(address _account) external view returns (uint256) {
        return children[_account].length;
    }

    function register(address _parent) external {
        if (registered(_parent) == false) revert();
        if (registered(msg.sender) == true) revert();
        parent[msg.sender] = _parent;
        children[_parent].push(msg.sender);

        emit Registered(msg.sender, _parent);
    }
}