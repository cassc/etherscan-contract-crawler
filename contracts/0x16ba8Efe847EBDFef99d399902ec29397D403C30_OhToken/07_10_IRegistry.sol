// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IRegistry {
    function governance() external view returns (address);

    function manager() external view returns (address);
}