// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Action.sol";

interface IChainlinkAccessor {
    struct ChainlinkParameters {
        bytes32 jobId;
        uint256 fee;
        string urlData;
        string pathToOffchainAssets;
        string pathToTotalOffchainAssetAtLastClose;
    }

    struct RequestData {
        address investor;
        uint256 amount;
        Action action;
    }
}