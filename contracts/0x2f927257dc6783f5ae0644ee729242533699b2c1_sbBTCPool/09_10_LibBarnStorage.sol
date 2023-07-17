// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IRewards.sol";

library LibBarnStorage {
    bytes32 constant STORAGE_POSITION = keccak256("com.barnbridge.barn.storage");

    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
    }

    struct NodeInfo {
        bytes32 p2pkey;
        uint8   dataType;
    }

    struct Storage {
        bool initialized;

        // mapping of user address to history of Stake objects
        // every user action creates a new object in the history
        mapping(address => Stake[]) userStakeHistory;

        // array of bond staked Checkpoint
        // deposits/withdrawals create a new object in the history (max one per block)
        Checkpoint[] bondStakedHistory;

        // mapping of user address to history of delegated power
        // every delegate/stopDelegate call create a new checkpoint (max one per block)
        mapping(address => Checkpoint[]) delegatedPowerHistory;

        // mapping of user address to <p2pkey,dataType> for swingby node. (no history)
        mapping(address => NodeInfo) nodeInfo;

        IERC20 bond;
        IRewards rewards;
    }

    function barnStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}