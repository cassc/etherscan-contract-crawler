// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteNFTBalanceTest} from "./AnteNFTBalanceTest.sol";
import {IAnteNFTBalanceTestFactory} from "./interfaces/IAnteNFTBalanceTestFactory.sol";

error InvalidNFTAddress();
error InvalidHolderAddress();
error InvalidBalance();
error AlreadyExists();
error FailingTest();

contract AnteNFTBalanceTestFactory is IAnteNFTBalanceTestFactory {
    /// @inheritdoc IAnteNFTBalanceTestFactory
    address[] public override allNFTBalanceTests;

    /// @inheritdoc IAnteNFTBalanceTestFactory
    mapping(bytes32 => address) public override testByConfig;

    /// @inheritdoc IAnteNFTBalanceTestFactory
    function createNFTBalanceTest(
        address nftAddress,
        address holderAddress,
        uint256 thresholdBalance
    ) external override returns (address anteNFTBalanceTestAddress) {
        if (nftAddress == address(0)) {
            revert InvalidNFTAddress();
        }
        if (holderAddress == address(0)) {
            revert InvalidHolderAddress();
        }
        if (thresholdBalance == 0) {
            revert InvalidBalance();
        }

        bytes32 configHash = keccak256(
            abi.encodePacked(nftAddress, holderAddress, thresholdBalance)
        );
        address testAddr = testByConfig[configHash];
        if(testAddr != address(0)) {
            revert AlreadyExists();
        }

        AnteNFTBalanceTest anteNFTBalanceTest = new AnteNFTBalanceTest{salt: configHash}(
            nftAddress,
            holderAddress,
            thresholdBalance,
            msg.sender
        );

        if(anteNFTBalanceTest.checkTestPasses() == false) {
          revert FailingTest();
        }

        anteNFTBalanceTestAddress = address(anteNFTBalanceTest);
        allNFTBalanceTests.push(anteNFTBalanceTestAddress);
        testByConfig[configHash] = anteNFTBalanceTestAddress;

        emit AnteNFTBalanceTestCreated(
            nftAddress,
            holderAddress,
            thresholdBalance,
            anteNFTBalanceTestAddress,
            msg.sender
        );
    }
}