// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface MinterInterface {
    function mint(address _to, uint256 _id) external;
}