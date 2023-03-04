// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

interface IAnteTokenBalanceTestFactory {
    /// @notice Emitted when an AnteTest
    /// @param tokenAddress The address of the tested ERC20 token
    /// @param holderAddress The address of the tokens holder
    /// @param thresholdBalance The threshold balance of the holder
    /// @param anteTokenBalanceTestAddress The deployed AnteTest address
    /// @param testCreator The test author address
    event AnteTokenBalanceTestCreated(
        address tokenAddress,
        address holderAddress,
        uint256 thresholdBalance,
        address anteTokenBalanceTestAddress,
        address testCreator
    );

    /// @notice Deploys the AnteTest with given parameters
    /// @param tokenAddress The address of the tested ERC20 token
    /// @param holderAddress The address of the tokens holder
    /// @param thresholdBalance The threshold balance of the holder
    function createTokenBalanceTest(
        address tokenAddress,
        address holderAddress,
        uint256 thresholdBalance
    ) external returns (address anteTestAddress);

    /// @notice Returns a single address in the allTokenBalanceTests array
    /// @param i The array index of the address to return
    /// @return The address of the i-th AnteTokenBalanceTest created by this factory
    function allTokenBalanceTests(uint256 i) external view returns (address);

    /// @notice Returns the address of the AnteTokenBalanceTest corresponding to a given config hash
    /// @param configHash config hash of the AnteTokenBalanceTest to look up
    /// @return The address of the corresponding AnteTokenBalanceTest
    function testByConfig(bytes32 configHash) external view returns (address);
}