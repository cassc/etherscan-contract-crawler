// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPipInterface {
    function read() external returns (bytes32);
}

interface SpotterLike {
    function ilks(bytes32) external view returns (IPipInterface pip, uint256 mat);

    function par() external view returns (uint256);
}