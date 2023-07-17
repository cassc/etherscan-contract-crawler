// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IDecentralandEstateRegistry {
    /**
     * @notice Return the amount of tokens for a given Estate
     * @param estateId Estate id to search
     * @return Tokens length
     */
    function getEstateSize(uint256 estateId) external view returns (uint256);
}