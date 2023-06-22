// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IRatioAdmin {

    event UpdateRatio(address indexed sender, address indexed token, uint ratio);

    function getRatio(address token) external view returns (uint ratio);
    function updateRatio(address token, uint ratio) external;
}