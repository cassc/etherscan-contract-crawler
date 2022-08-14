//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./PaymentSplitter.sol";

/**
 * @title PaymentSplitterFactory
 * @dev This contract allows users to create and track minimal proxy contracts (clones) of an implementation of PaymentSplitter
 *
 */
contract PaymentSplitterFactory is Ownable {
    event PaymentSplitterCreated(address indexed owner, address indexed splitter, string title);

    address[] private _splitters;
    address public immutable implementation;
    /**
     * @dev Creates an instance of `PaymentSplitterFactory`.
     */
    constructor () {
        implementation = address(new PaymentSplitter());
    }

    /**
     * @dev Spawn a new PaymentSplitter passing in `members` to its initializer
     */
    function newSplitter(string calldata title, PaymentSplitter.Member[] calldata members) external onlyOwner returns(address) {
        address payable clone = payable(Clones.clone(implementation));
        PaymentSplitter s = PaymentSplitter(clone);
        emit PaymentSplitterCreated(msg.sender, clone, title);
        s.initialize(members);
        _splitters.push(clone);
        return clone;
    }

    function getSplitters(address account) external view returns (address[] memory) {
        address[] memory splitters = new address[](_splitters.length);
        uint256 cnt = 0;
        for (uint256 i = 0; i < _splitters.length; ++i) {
            address payable splitter = payable(_splitters[i]);
            PaymentSplitter s = PaymentSplitter(splitter);
            if(s.isMember(account)) {
                splitters[cnt] = splitter;
                ++cnt;
            }
        }
        address[] memory result = new address[](cnt);
        for (uint256 i = 0; i < cnt; ++i) {
            result[i] = splitters[i];
        }
        return result;
    }
}