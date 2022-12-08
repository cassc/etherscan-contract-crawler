// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBribe {
    function rewardsListLength() external view returns (uint256);

    function rewards(uint256) external view returns (address);

    function earned(address, uint256) external view returns (uint256);
}