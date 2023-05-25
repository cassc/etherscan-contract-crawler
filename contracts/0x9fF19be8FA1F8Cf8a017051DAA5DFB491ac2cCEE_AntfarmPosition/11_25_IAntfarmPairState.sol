// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;
import "../IAntfarmToken.sol";

interface IAntfarmPairState {
    /// @notice The contract that deployed the AntfarmPair, which must adhere to the IAntfarmFactory interface
    /// @return address The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the AntfarmPair, sorted by address
    /// @return address The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the AntfarmPair, sorted by address
    /// @return address The token contract address
    function token1() external view returns (address);

    /// @notice Fee associated to the AntfarmPair instance
    /// @return uint16 Fee
    function fee() external view returns (uint16);

    /// @notice The LP tokens total circulating supply
    /// @return uint Total LP tokens
    function totalSupply() external view returns (uint256);

    /// @notice The AntFarmPair AntFarm's tokens cumulated fees
    /// @return uint Total Antfarm tokens
    function antfarmTokenReserve() external view returns (uint256);
}