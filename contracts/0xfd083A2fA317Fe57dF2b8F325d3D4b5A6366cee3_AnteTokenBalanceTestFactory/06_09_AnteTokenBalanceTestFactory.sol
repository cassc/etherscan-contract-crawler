// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTokenBalanceTest} from "./AnteTokenBalanceTest.sol";
import {IAnteTokenBalanceTestFactory} from "./interfaces/IAnteTokenBalanceTestFactory.sol";

error InvalidNftAddress();
error InvalidHolderAddress();
error InvalidBalance();
error AlreadyExists();
error FailingTest();

contract AnteTokenBalanceTestFactory is IAnteTokenBalanceTestFactory {
    /// @inheritdoc IAnteTokenBalanceTestFactory
    address[] public override allTokenBalanceTests;

    /// @inheritdoc IAnteTokenBalanceTestFactory
    mapping(bytes32 => address) public override testByConfig;

    /// @inheritdoc IAnteTokenBalanceTestFactory
    function createTokenBalanceTest(
        address tokenAddress,
        address holderAddress,
        uint256 thresholdBalance
    ) external override returns (address anteTokenBalanceTestAddress) {
        if (holderAddress == address(0)) {
            revert InvalidHolderAddress();
        }
        if (thresholdBalance == 0) {
            revert InvalidBalance();
        }

        bytes32 configHash = keccak256(
            abi.encodePacked(tokenAddress, holderAddress, thresholdBalance)
        );
        address testAddr = testByConfig[configHash];
        if(testAddr != address(0)) {
            revert AlreadyExists();
        }

        AnteTokenBalanceTest anteTokenBalanceTest = new AnteTokenBalanceTest{salt: configHash}(
            tokenAddress,
            holderAddress,
            thresholdBalance,
            msg.sender
        );

        if(anteTokenBalanceTest.checkTestPasses() == false) {
          revert FailingTest();
        }

        anteTokenBalanceTestAddress = address(anteTokenBalanceTest);
        allTokenBalanceTests.push(anteTokenBalanceTestAddress);
        testByConfig[configHash] = anteTokenBalanceTestAddress;

        emit AnteTokenBalanceTestCreated(
            tokenAddress,
            holderAddress,
            thresholdBalance,
            anteTokenBalanceTestAddress,
            msg.sender
        );
    }
}