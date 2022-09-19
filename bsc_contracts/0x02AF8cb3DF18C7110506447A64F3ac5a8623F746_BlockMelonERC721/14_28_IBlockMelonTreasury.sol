// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBlockMelonTreasury {
    /**
     * @notice Returns the address of the treasury
     */
    function getBlockMelonTreasury() external view returns (address payable);
}