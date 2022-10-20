pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "../common/interfaces/IAllowList.sol";
import "./interfaces/IExecutor.sol";
import "./libraries/Diamond.sol";
import "./facets/Base.sol";
import "./Config.sol";

/// @author Matter Labs
/// @dev The contract is used only once to initialize the diamond proxy.
/// @dev The deployment process takes care of this contract's initialization.
contract DiamondInit is Base {
    constructor() reentrancyGuardInitializer {}

    /// @notice zkSync contract initialization
    /// @param _verifier address of Verifier contract
    /// @param _governor address who can manage the contract
    /// @param _validator address who can make blocks
    /// @param _genesisBlockHash Block hash of the genesis (initial) block
    /// @param _genesisIndexRepeatedStorageChanges The serial number of the shortcut storage key for genesis block
    /// @return Magic 32 bytes, which indicates that the contract logic is expected to be used as a diamond proxy initializer
    function initialize(
        Verifier _verifier,
        address _governor,
        address _validator,
        bytes32 _genesisBlockHash,
        uint64 _genesisIndexRepeatedStorageChanges,
        IAllowList _allowList,
        VerifierParams calldata _verifierParams,
        bool _zkPorterIsAvailable,
        bytes32 _l2BootloaderBytecodeHash,
        bytes32 _l2DefaultAccountBytecodeHash
    ) external reentrancyGuardInitializer returns (bytes32) {
        s.verifier = _verifier;
        s.governor = _governor;
        s.validators[_validator] = true;

        // We need to initialize the state hash because it is used in the commitment of the next block
        IExecutor.StoredBlockInfo memory storedBlockZero = IExecutor.StoredBlockInfo(
            0,
            _genesisBlockHash,
            _genesisIndexRepeatedStorageChanges,
            0,
            EMPTY_STRING_KECCAK,
            DEFAULT_L2_LOGS_TREE_ROOT_HASH,
            0,
            bytes32(0)
        );

        s.storedBlockHashes[0] = keccak256(abi.encode(storedBlockZero));
        s.allowList = _allowList;
        s.verifierParams = _verifierParams;
        s.zkPorterIsAvailable = _zkPorterIsAvailable;
        s.l2BootloaderBytecodeHash = _l2BootloaderBytecodeHash;
        s.l2DefaultAccountBytecodeHash = _l2DefaultAccountBytecodeHash;

        return Diamond.DIAMOND_INIT_SUCCESS_RETURN_VALUE;
    }
}