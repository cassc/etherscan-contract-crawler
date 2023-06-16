// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IV1Controller {
    function stretegies(address _want) external view returns (address _strategy);

    function vaults(address _want) external view returns (address _vault);
}