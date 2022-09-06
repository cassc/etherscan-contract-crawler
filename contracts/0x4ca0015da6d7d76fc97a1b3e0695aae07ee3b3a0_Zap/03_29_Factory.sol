// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Split.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Lock.sol";

contract SplitFactory {
    IOracle public oracle;

    constructor(IOracle _oracle) {
        oracle = _oracle;
    }

    mapping(IERC20 => Split) public splits;

    function create(IERC20 token) public returns (Split) {
        require(address(splits[token]) == address(0));

        Split s = new Split(token, oracle);
        splits[token] = s;
        return s;
    }

    function get(IERC20 token) public returns (Split) {
        Split s = splits[token];
        if (address(s) == address(0)) {
            s = new Split(token, oracle);
            splits[token] = s;
        }

        return s;
    }

    mapping(IERC20 => Lock) public locks;

    function createLock(IERC20 token) public returns (Lock) {
        require(address(locks[token]) == address(0));

        Lock s = new Lock(token, oracle);
        locks[token] = s;
        return s;
    }

    function getLock(IERC20 token) public returns (Lock) {
        Lock s = locks[token];
        if (address(s) == address(0)) {
            s = new Lock(token, oracle);
            locks[token] = s;
        }

        return s;
    }
}