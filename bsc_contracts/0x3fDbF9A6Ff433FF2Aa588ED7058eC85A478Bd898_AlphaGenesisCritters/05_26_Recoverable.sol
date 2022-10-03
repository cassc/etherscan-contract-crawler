// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

contract Recoverable {
    function _recover(uint256 amount, address receiver) internal {
        Address.sendValue(payable(receiver), amount);
    }
}