// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "./Staking.sol";

contract EpochInitializer {
    function initEpochs(address stakingAddr, address[] memory tokens) public {
        Staking staking = Staking(stakingAddr);

        uint128 currentEpoch = staking.getCurrentEpoch();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint128 lastInitEpoch;
            address t = tokens[i];

            for (uint128 j = currentEpoch + 1; j >= 0; j--) {
                bool ok = staking.epochIsInitialized(t, j);

                if (ok) {
                    lastInitEpoch = j;
                    break;
                }
            }

            for (uint128 j = lastInitEpoch + 1; j <= currentEpoch; j++) {
                address[] memory initTokens = new address[](1);
                initTokens[0] = t;

                staking.manualEpochInit(initTokens, j);
            }
        }
    }
}