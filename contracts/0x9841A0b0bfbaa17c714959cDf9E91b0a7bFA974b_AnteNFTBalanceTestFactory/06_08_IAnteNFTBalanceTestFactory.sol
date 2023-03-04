// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

interface IAnteNFTBalanceTestFactory {
    /// @notice Emitted when an AnteTest
    /// @param nftAddress The address of the test NFT
    /// @param holderAddress The address of the owner of the NFT to test
    /// @param thresholdBalance The NFT threshold balance of the holder
    /// @param anteNftBalanceTestAddress The deployed AnteTest address
    /// @param testCreator The test author address
    event AnteNFTBalanceTestCreated(
        address nftAddress,
        address holderAddress,
        uint256 thresholdBalance,
        address anteNftBalanceTestAddress,
        address testCreator
    );

    /// @notice Deploys the AnteTest with given parameters
    /// @param nftAddress The address of the test NFT
    /// @param holderAddress The address of the owner of the NFT to test
    /// @param thresholdBalance The NFT threshold balance of the holder
    function createNFTBalanceTest(
        address nftAddress,
        address holderAddress,
        uint256 thresholdBalance
    ) external returns (address anteTestAddress);

    /// @notice Returns a single address in the allNFTBalanceTests array
    /// @param i The array index of the address to return
    /// @return The address of the i-th NFTBalanceTest created by this factory
    function allNFTBalanceTests(uint256 i) external view returns (address);

    /// @notice Returns the address of the NFTBalanceTest corresponding to a given config hash
    /// @param configHash config hash of the NFTBalanceTest to look up
    /// @return The address of the corresponding NFTBalanceTest
    function testByConfig(bytes32 configHash) external view returns (address);
}