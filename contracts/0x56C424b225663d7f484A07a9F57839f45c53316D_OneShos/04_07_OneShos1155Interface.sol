//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface OneShos1155Interface {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function isApprovedForAll(address account, address operator) external view returns (bool);
}