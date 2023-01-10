// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IMLC {
    function mintTo(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
}