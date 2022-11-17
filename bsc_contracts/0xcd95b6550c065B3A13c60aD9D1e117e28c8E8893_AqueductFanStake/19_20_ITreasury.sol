// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasury {
    function getErc20Address() external view returns (address);

    function isAdmin(address sender) external view returns (bool);
}