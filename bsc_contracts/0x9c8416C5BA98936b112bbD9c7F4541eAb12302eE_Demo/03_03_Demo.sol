// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Demo is Initializable {
    uint256 public a;

    // 初始化函数，后面的修饰符 initializer 来自 Initializable.sol
    // 用于限制该函数只能调用一次
    function initialize(uint256 _a) public initializer {
        a = _a;
    }

    function increaseA() external {
        ++a;
    }
}