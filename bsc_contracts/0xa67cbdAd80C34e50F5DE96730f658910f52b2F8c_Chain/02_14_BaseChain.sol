// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@umb-network/toolbox/dist/contracts/lib/ValueDecoder.sol";

import "./interfaces/IBaseChainV1.sol";
import "./interfaces/IStakingBank.sol";
import "./extensions/Registrable.sol";
import "./Registry.sol";

abstract contract BaseChain is Registrable, Ownable {
    using ValueDecoder for bytes;
    using ValueDecoder for uint224;
    using MerkleProof for bytes32[];

    /// @param root merkle root for consensus
    /// @param dataTimestamp consensus timestamp
    struct Block {
        bytes32 root;
        uint32 dataTimestamp;
    }

    /// @param value FCD value
    /// @param dataTimestamp FCD timestamp
    struct FirstClassData {
        uint224 value;
        uint32 dataTimestamp;
    }

    /// @param blocksCountOffset number of all blocks that were generated before switching to this contract
    /// @param sequence is a total number of blocks (consensus rounds) including previous contracts
    /// @param lastTimestamp is a timestamp of last submitted block
    /// @param padding number of seconds that need to pass before new submit will be possible
    /// @param deprecated flag that changes to TRUE on `unregister`, when TRUE submissions are not longer available
    struct ConsensusData {
        uint32 blocksCountOffset;
        uint32 sequence;
        uint32 lastTimestamp;
        uint32 padding;
        bool deprecated;
    }

    uint256 constant public VERSION = 2;

    bool internal immutable _ALLOW_FOR_MIXED_TYPE; // solhint-disable-line var-name-mixedcase

    bytes4 constant private _VERSION_SELECTOR = bytes4(keccak256("VERSION()"));

    /// @dev minimal number of signatures required for accepting submission (PoA)
    uint16 internal immutable _REQUIRED_SIGNATURES; // solhint-disable-line var-name-mixedcase

    ConsensusData internal _consensusData;

    bytes constant public ETH_PREFIX = "\x19Ethereum Signed Message:\n32";

    /// @dev block id (consensus ID) => root
    /// consensus ID is at the same time consensus timestamp
    mapping(uint256 => bytes32) public roots;

    /// @dev FCD key => FCD data
    mapping(bytes32 => FirstClassData) public fcds;

    event LogDeprecation(address indexed deprecator);
    event LogPadding(address indexed executor, uint32 timePadding);

    error ArraysDataDoNotMatch();
    error AlreadyDeprecated();
    error AlreadyRegistered();
    error BlockSubmittedToFastOrDataToOld();
    error ContractNotReady();
    error FCDOverflow();
    error InvalidContractType();
    error NoChangeToState();
    error OnlyOwnerOrRegistry();
    error UnregisterFirst();

    modifier onlyOwnerOrRegistry () {
        if (msg.sender != address(contractRegistry) && msg.sender != owner()) revert OnlyOwnerOrRegistry();
        _;
    }

    /// @param _contractRegistry Registry address
    /// @param _padding required "space" between blocks in seconds
    /// @param _requiredSignatures number of required signatures for accepting consensus submission
    constructor(
        IRegistry _contractRegistry,
        uint32 _padding,
        uint16 _requiredSignatures,
        bool _allowForMixedType
    ) Registrable(_contractRegistry) {
        _ALLOW_FOR_MIXED_TYPE = _allowForMixedType;
        _REQUIRED_SIGNATURES = _requiredSignatures;

        _setPadding(_padding);

        BaseChain oldChain = BaseChain(_contractRegistry.getAddress("Chain"));

        if (address(oldChain) == address(0)) {
            // if this is first contract in sidechain, then we need to initialise lastTimestamp so submission
            // can be possible
            _consensusData.lastTimestamp = uint32(block.timestamp) - _padding - 1;
        }
    }

    /// @dev setter for `padding`
    function setPadding(uint16 _padding) external {
        _setPadding(_padding);
    }

    /// @notice if this method needs to be called manually (not from Registry)
    /// it is important to do it as part of tx batch
    /// eg using multisig, we should prepare set of transactions and confirm them all at once
    /// @inheritdoc Registrable
    function register() external override onlyOwnerOrRegistry {
        address oldChain = contractRegistry.getAddress("Chain");

        // registration must be done before address in registry is replaced
        if (oldChain == address(this)) revert AlreadyRegistered();

        if (oldChain == address(0x0)) {
            return;
        }

        _cloneLastDataFromPrevChain(oldChain);
    }

    /// @inheritdoc Registrable
    function unregister() external override onlyOwnerOrRegistry {
        // in case we deprecated contract manually, we simply return
        if (_consensusData.deprecated) return;

        address newChain = contractRegistry.getAddress("Chain");
        // unregistering must be done after address in registry is replaced
        if (newChain == address(this)) revert UnregisterFirst();

        // TODO:
        // I think we need to remove restriction for type (at least once)
        // when we will switch to multichain architecture

        if (!_ALLOW_FOR_MIXED_TYPE) {
            // can not be replaced with chain of different type
            if (BaseChain(newChain).isForeign() != this.isForeign()) revert InvalidContractType();
        }

        _consensusData.deprecated = true;
        emit LogDeprecation(msg.sender);
    }

    /// @notice it allows to deprecate contract manually
    /// Only new Registry calls `unregister()` where we set deprecated to true
    /// In old Registries we don't have this feature, so in order to safely redeploy new Chain
    /// we will have to first deprecate current contract manually, then register new contract
    function deprecate() external onlyOwnerOrRegistry {
        if (_consensusData.deprecated) revert AlreadyDeprecated();

        _consensusData.deprecated = true;
        emit LogDeprecation(msg.sender);
    }

    /// @dev getter for `_consensusData`
    function getConsensusData() external view returns (ConsensusData memory) {
        return _consensusData;
    }

    /// @dev number of blocks (consensus rounds) saved in this contract
    function blocksCount() external view returns (uint256) {
        return _consensusData.sequence - _consensusData.blocksCountOffset;
    }

    function blocksCountOffset() external view returns (uint32) {
        return _consensusData.blocksCountOffset;
    }

    function lastBlockId() external view returns (uint256) {
        return _consensusData.lastTimestamp;
    }

    /// @return TRUE if contract is ForeignChain, FALSE otherwise
    function isForeign() external pure virtual returns (bool);

    /// @inheritdoc Registrable
    function getName() external pure override returns (bytes32) {
        return "Chain";
    }

    /// @param _affidavit root and FCDs hashed together
    /// @param _v part of signature
    /// @param _r part of signature
    /// @param _s part of signature
    /// @return signer address
    function recoverSigner(bytes32 _affidavit, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(ETH_PREFIX, _affidavit));
        return ecrecover(hash, _v, _r, _s);
    }

    /// @param _blockId ID of submitted block
    /// @return block data (root + timestamp)
    function blocks(uint256 _blockId) external view returns (Block memory) {
        return Block(roots[_blockId], uint32(_blockId));
    }

    /// @return current block ID
    /// please note, that current ID is not the same as last ID, current means that once padding pass,
    /// ID will switch to next one and it will be pointing to empty submit until submit for that ID is done
    function getBlockId() external view returns (uint32) {
        if (_consensusData.lastTimestamp == 0) return 0;

        return getBlockIdAtTimestamp(block.timestamp);
    }

    function requiredSignatures() external view returns (uint16) {
        return _REQUIRED_SIGNATURES;
    }

    /// @dev calculates block ID for provided timestamp
    /// this function does not works for past timestamps
    /// @param _timestamp current or future timestamp
    /// @return block ID for provided timestamp
    function getBlockIdAtTimestamp(uint256 _timestamp) virtual public view returns (uint32) {
        ConsensusData memory data = _consensusData;

        unchecked {
            // we can't overflow because we adding two `uint32`
            if (data.lastTimestamp + data.padding < _timestamp) {
                return uint32(_timestamp);
            }
        }

        return data.lastTimestamp;
    }

    /// @return last submitted block ID, please note, that on deployment, when there is no submission for this contract
    /// block for last ID will be available in previous contract
    function getLatestBlockId() virtual public view returns (uint32) {
        return _consensusData.lastTimestamp;
    }

    /// @dev verifies if the leaf is valid leaf for merkle tree
    /// @param _proof merkle proof for merkle tree
    /// @param _root merkle root
    /// @param _leaf leaf hash
    /// @return TRUE if `_leaf` is valid, FALSE otherwise
    function verifyProof(bytes32[] memory _proof, bytes32 _root, bytes32 _leaf) public pure returns (bool) {
        if (_root == bytes32(0)) {
            return false;
        }

        return _proof.verify(_root, _leaf);
    }

    /// @dev creates leaf hash, that has is used in merkle tree
    /// @param _key key under which we store the value
    /// @param _value value itself as bytes
    /// @return leaf hash
    function hashLeaf(bytes memory _key, bytes memory _value) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_key, _value));
    }

    /// @dev verifies, if provided key-value pair was part of consensus
    /// @param _blockId consensus ID for which we doing a check
    /// @param _proof merkle proof for pair
    /// @param _key pair key
    /// @param _value pair value
    /// @return TRUE if key-value par was part of consensus, FALSE otherwise
    function verifyProofForBlock(
        uint256 _blockId,
        bytes32[] memory _proof,
        bytes memory _key,
        bytes memory _value
    )
        public
        view
        returns (bool)
    {
        return _proof.verify(roots[_blockId], keccak256(abi.encodePacked(_key, _value)));
    }

    /// @dev this is helper method, that extracts one merkle proof from many hashed provided as bytes
    /// @param _data many hashes as bytes
    /// @param _offset this is starting point for extraction
    /// @param _items how many hashes to extract
    /// @return merkle proof (array of bytes32 hashes)
    function bytesToBytes32Array(
        bytes memory _data,
        uint256 _offset,
        uint256 _items
    )
        public
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory dataList = new bytes32[](_items);

        // we can unchecked because we working only with `i` and `_offset`
        // in case of wrong `_offset` it will throw
        unchecked {
            for (uint256 i = 0; i < _items; i++) {
                bytes32 temp;
                uint256 idx = (i + 1 + _offset) * 32;

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    temp := mload(add(_data, idx))
                }

                dataList[i] = temp;
            }
        }

        return (dataList);
    }

    /// @dev batch method for data verification
    /// @param _blockIds consensus IDs for which we doing a checks
    /// @param _proofs merkle proofs for all pair, sequence of hashes provided as bytes
    /// @param _proofItemsCounter array of counters, each counter tells how many hashes proof for each leaf has
    /// @param _leaves array of merkle leaves
    /// @return results array of verification results, TRUE if leaf is part of consensus, FALSE otherwise
    function verifyProofs(
        uint32[] memory _blockIds,
        bytes memory _proofs,
        uint256[] memory _proofItemsCounter,
        bytes32[] memory _leaves
    )
        public
        view
        returns (bool[] memory results)
    {
        results = new bool[](_leaves.length);
        uint256 offset = 0;

        for (uint256 i = 0; i < _leaves.length;) {
            results[i] = bytesToBytes32Array(_proofs, offset, _proofItemsCounter[i]).verify(
                roots[_blockIds[i]], _leaves[i]
            );

            unchecked {
                // we can uncheck because it will not overflow in a lifetime, and if someone provide invalid counter
                // we verification will not be valid (or we throw because of invalid memory access)
                offset += _proofItemsCounter[i];
                // we can uncheck because `i` will not overflow in a lifetime
                i++;
            }
        }
    }

    /// @param _blockId consensus ID
    /// @return root for provided consensus ID
    function getBlockRoot(uint32 _blockId) external view returns (bytes32) {
        return roots[_blockId];
    }

    /// @param _blockId consensus ID
    /// @return timestamp for provided consensus ID
    function getBlockTimestamp(uint32 _blockId) external view returns (uint32) {
        return roots[_blockId] == bytes32(0) ? 0 : _blockId;
    }

    /// @dev batch getter for FCDs
    /// @param _keys FCDs keys to fetch
    /// @return values array of FCDs values
    /// @return timestamps array of FCDs timestamps
    function getCurrentValues(bytes32[] calldata _keys)
        external
        view
        returns (uint256[] memory values, uint32[] memory timestamps)
    {
        timestamps = new uint32[](_keys.length);
        values = new uint256[](_keys.length);

        for (uint i=0; i<_keys.length;) {
            FirstClassData storage numericFCD = fcds[_keys[i]];
            values[i] = uint256(numericFCD.value);
            timestamps[i] = numericFCD.dataTimestamp;

            unchecked {
                // we can uncheck because `i` will not overflow in a lifetime
                i++;
            }
        }
    }

    /// @dev getter for single FCD value
    /// @param _key FCD key
    /// @return value FCD value
    /// @return timestamp FCD timestamp
    function getCurrentValue(bytes32 _key) external view returns (uint256 value, uint256 timestamp) {
        FirstClassData storage numericFCD = fcds[_key];
        return (uint256(numericFCD.value), numericFCD.dataTimestamp);
    }

    /// @dev getter for single FCD value in case its type is `int`
    /// @param _key FCD key
    /// @return value FCD value
    /// @return timestamp FCD timestamp
    function getCurrentIntValue(bytes32 _key) external view returns (int256 value, uint256 timestamp) {
        FirstClassData storage numericFCD = fcds[_key];
        return (numericFCD.value.toInt(), numericFCD.dataTimestamp);
    }

    function _setPadding(uint32 _padding) internal onlyOwner {
        if (_consensusData.padding == _padding) revert NoChangeToState();

        _consensusData.padding = _padding;
        emit LogPadding(msg.sender, _padding);
    }

    /// @dev we cloning last block time, because we will need reference point for next submissions
    function _cloneLastDataFromPrevChain(address _prevChain) internal {
        (bool success, bytes memory v) = _prevChain.staticcall(abi.encode(_VERSION_SELECTOR));
        uint256 prevVersion = success ? abi.decode(v, (uint256)) : 1;

        if (prevVersion == 1) {
            uint32 latestId = IBaseChainV1(address(_prevChain)).getLatestBlockId();
            _consensusData.lastTimestamp = IBaseChainV1(address(_prevChain)).getBlockTimestamp(latestId);

            // +1 because getLatestBlockId subtracts 1
            // +1 because it might be situation when tx is already in progress in old contract
            // and old contract do not have deprecated flag
            _consensusData.sequence = latestId + 2;
            _consensusData.blocksCountOffset = latestId + 2;
        } else { // VERSION 2
            // with new Registry, we have register/unregister methods
            // Chain will be deprecated, so there is no need to do "+1" as in old version
            // TODO what with current Registries??
            // we need a way to make it deprecated!
            ConsensusData memory data = BaseChain(_prevChain).getConsensusData();

            _consensusData.sequence = data.sequence;
            _consensusData.blocksCountOffset = data.sequence;
            _consensusData.lastTimestamp = data.lastTimestamp;
        }
    }
}