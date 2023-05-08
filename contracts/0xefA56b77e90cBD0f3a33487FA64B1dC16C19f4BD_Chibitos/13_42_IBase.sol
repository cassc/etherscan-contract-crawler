//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IBase {
    struct Args {
        address[] payees;
        uint256[] shares;
        address royaltiesRecipient;
        uint96 royaltyValue;
        StageConfig[] stages;
        TokenConfig tokenConfig;
    }

    struct StageConfig {
        uint256 limit;
        uint256 price;
        bytes32 merkleTreeRoot;
    }

    struct TokenConfig {
        string name;
        string symbol;
        uint256 supply;
        string prefix;
        string suffix;
    }
}