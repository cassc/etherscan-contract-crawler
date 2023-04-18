// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

contract MockSwap {
    function getHOPEPrice() public view returns (uint256) {
        return 1000;
    }

    function getStHOPEPrice() public view returns (uint256) {
        return 1000;
    }

    function getLTPrice() public view returns (uint256) {
        return 1;
    }
}