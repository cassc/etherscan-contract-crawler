// SPDX-License-Identifier: Apache-2.0 OR MIT OR GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IMevWeth {
    function mev() external returns (uint256);
    function addMev(uint256 value) external;
    function addMev(address from, uint256 value) external;
    function getMev() external;
    function getMev(uint256 value) external;
    function getMev(address to) external;
    function getMev(address to, uint256 value) external;
}