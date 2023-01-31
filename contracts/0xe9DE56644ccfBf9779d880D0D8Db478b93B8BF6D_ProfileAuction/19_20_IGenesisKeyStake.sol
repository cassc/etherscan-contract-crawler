// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

interface IGenesisKeyStake {
    function stakedAddress(address _user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalStakedCoin() external view returns (uint256);
}