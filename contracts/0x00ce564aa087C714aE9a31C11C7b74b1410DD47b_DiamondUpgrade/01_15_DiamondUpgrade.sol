pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./interfaces/IExecutor.sol";
import "./facets/Base.sol";
import "./Config.sol";
import "./libraries/Diamond.sol";

/// @author Matter Labs
contract DiamondUpgrade is Base {
    function initialize(
        bytes32 _genesisBlockHash,
        bytes32 _genesisBlockCommitment,
        uint64 _genesisIndexRepeatedStorageChanges
    ) external returns (bytes32) {
        IExecutor.StoredBlockInfo memory storedBlockZero = IExecutor.StoredBlockInfo(
            0,
            _genesisBlockHash,
            _genesisIndexRepeatedStorageChanges,
            0,
            EMPTY_STRING_KECCAK,
            DEFAULT_L2_LOGS_TREE_ROOT_HASH,
            0,
            _genesisBlockCommitment
        );

        s.storedBlockHashes[0] = keccak256(abi.encode(storedBlockZero));

        return Diamond.DIAMOND_INIT_SUCCESS_RETURN_VALUE;
    }
}