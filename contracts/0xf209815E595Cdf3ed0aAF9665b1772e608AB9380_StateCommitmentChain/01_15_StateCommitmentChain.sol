// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";
import { Lib_MerkleTree } from "../../libraries/utils/Lib_MerkleTree.sol";

/* Interface Imports */
import { IStateCommitmentChain } from "./IStateCommitmentChain.sol";
import { ICanonicalTransactionChain } from "./ICanonicalTransactionChain.sol";
import { IBondManager } from "../verification/IBondManager.sol";
import { IChainStorageContainer } from "./IChainStorageContainer.sol";

/**
 * @title StateCommitmentChain
 * @dev The State Commitment Chain (SCC) contract contains a list of proposed state roots which
 * Proposers assert to be a result of each transaction in the Canonical Transaction Chain (CTC).
 * Elements here have a 1:1 correspondence with transactions in the CTC, and should be the unique
 * state root calculated off-chain by applying the canonical transactions one by one.
 *
 * Runtime target: EVM
 */
contract StateCommitmentChain is IStateCommitmentChain, Lib_AddressResolver {

    /*************
     * Constants *
     *************/

    uint256 public FRAUD_PROOF_WINDOW;
    uint256 public SEQUENCER_PUBLISH_WINDOW;
    
    
    uint256 public DEFAULT_CHAINID = 1088;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    constructor(
        address _libAddressManager,
        uint256 _fraudProofWindow,
        uint256 _sequencerPublishWindow
    )
        Lib_AddressResolver(_libAddressManager)
    {
        FRAUD_PROOF_WINDOW = _fraudProofWindow;
        SEQUENCER_PUBLISH_WINDOW = _sequencerPublishWindow;
    }
    
    function setFraudProofWindow (uint256 window) public {
        require (msg.sender == resolve("METIS_MANAGER"), "now allowed");
        FRAUD_PROOF_WINDOW = window;
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * Accesses the batch storage container.
     * @return Reference to the batch storage container.
     */
    function batches() public view returns (IChainStorageContainer) {
        return IChainStorageContainer(resolve("ChainStorageContainer-SCC-batches"));
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getTotalElements() public view returns (uint256 _totalElements) {
        return getTotalElementsByChainId(DEFAULT_CHAINID);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getTotalBatches() public view returns (uint256 _totalBatches) {
        return getTotalBatchesByChainId(DEFAULT_CHAINID);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getLastSequencerTimestamp() public view returns (uint256 _lastSequencerTimestamp) {
        return getLastSequencerTimestampByChainId(DEFAULT_CHAINID);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function appendStateBatch(bytes32[] memory _batch, uint256 _shouldStartAtElement) public {
        require (1==0, "don't use");
        //appendStateBatchByChainId(DEFAULT_CHAINID, _batch, _shouldStartAtElement, "1088_MVM_Proposer");
    }
    
    /**
     * @inheritdoc IStateCommitmentChain
     */
    function deleteStateBatch(Lib_OVMCodec.ChainBatchHeader memory _batchHeader) public {
        deleteStateBatchByChainId(DEFAULT_CHAINID, _batchHeader);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function verifyStateCommitment(
        bytes32 _element,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _proof
    ) public view returns (bool) {
        return verifyStateCommitmentByChainId(DEFAULT_CHAINID, _element, _batchHeader, _proof);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function insideFraudProofWindow(Lib_OVMCodec.ChainBatchHeader memory _batchHeader)
        public
        view
        returns (bool _inside)
    {
        (uint256 timestamp, ) = abi.decode(_batchHeader.extraData, (uint256, address));

        require(timestamp != 0, "Batch header timestamp cannot be zero");
        return (timestamp + FRAUD_PROOF_WINDOW) > block.timestamp;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Parses the batch context from the extra data.
     * @return Total number of elements submitted.
     * @return Timestamp of the last batch submitted by the sequencer.
     */
    function _getBatchExtraData() internal view returns (uint40, uint40) {
        bytes27 extraData = batches().getGlobalMetadata();

        // solhint-disable max-line-length
        uint40 totalElements;
        uint40 lastSequencerTimestamp;
        assembly {
            extraData := shr(40, extraData)
            totalElements := and(
                extraData,
                0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF
            )
            lastSequencerTimestamp := shr(
                40,
                and(extraData, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000)
            )
        }
        // solhint-enable max-line-length

        return (totalElements, lastSequencerTimestamp);
    }

    /**
     * Encodes the batch context for the extra data.
     * @param _totalElements Total number of elements submitted.
     * @param _lastSequencerTimestamp Timestamp of the last batch submitted by the sequencer.
     * @return Encoded batch context.
     */
    function _makeBatchExtraData(uint40 _totalElements, uint40 _lastSequencerTimestamp)
        internal
        pure
        returns (bytes27)
    {
        bytes27 extraData;
        assembly {
            extraData := _totalElements
            extraData := or(extraData, shl(40, _lastSequencerTimestamp))
            extraData := shl(40, extraData)
        }

        return extraData;
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getTotalElementsByChainId(
        uint256 _chainId
        )
        override
        public
        view
        returns (
            uint256 _totalElements
        )
    {
        (uint40 totalElements, ) = _getBatchExtraDataByChainId(_chainId);
        return uint256(totalElements);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getTotalBatchesByChainId(
        uint256 _chainId
        )
        override
        public
        view
        returns (
            uint256 _totalBatches
        )
    {
        return batches().lengthByChainId(_chainId);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function getLastSequencerTimestampByChainId(
        uint256 _chainId
        )
        override
        public
        view
        returns (
            uint256 _lastSequencerTimestamp
        )
    {
        (, uint40 lastSequencerTimestamp) = _getBatchExtraDataByChainId(_chainId);
        return uint256(lastSequencerTimestamp);
    }
    
    /**
     * @inheritdoc IStateCommitmentChain
     */
    function appendStateBatchByChainId(
        uint256 _chainId,
        bytes32[] calldata _batch,
        uint256 _shouldStartAtElement,
        string calldata proposer
    )
        override
        public
    {
        // Fail fast in to make sure our batch roots aren't accidentally made fraudulent by the
        // publication of batches by some other user.
        require(
            _shouldStartAtElement == getTotalElementsByChainId(_chainId),
            "Actual batch start index does not match expected start index."
        );
        
        address proposerAddr = resolve(proposer);

        // Proposers must have previously staked at the BondManager
        require(
            IBondManager(resolve("BondManager")).isCollateralizedByChainId(_chainId,msg.sender,proposerAddr),
            "Proposer does not have enough collateral posted"
        );

        require(
            _batch.length > 0,
            "Cannot submit an empty state batch."
        );

        require(
            getTotalElementsByChainId(_chainId) + _batch.length <= ICanonicalTransactionChain(resolve("CanonicalTransactionChain")).getTotalElementsByChainId(_chainId),
            "Number of state roots cannot exceed the number of canonical transactions."
        );

        // Pass the block's timestamp and the publisher of the data
        // to be used in the fraud proofs
        _appendBatchByChainId(
            _chainId,
            _batch,
            abi.encode(block.timestamp, msg.sender),
            proposerAddr
        );
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function deleteStateBatchByChainId(
        uint256 _chainId,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        override
        public
    {
        require(
            msg.sender == resolve(
              string(abi.encodePacked(uint2str(_chainId),"_MVM_FraudVerifier"))),
            "State batches can only be deleted by the MVM_FraudVerifier."
        );

        require(
            _isValidBatchHeaderByChainId(_chainId,_batchHeader),
            "Invalid batch header."
        );

        require(
            insideFraudProofWindowByChainId(_chainId,_batchHeader),
            "State batches can only be deleted within the fraud proof window."
        );

        _deleteBatchByChainId(_chainId,_batchHeader);
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function verifyStateCommitmentByChainId(
        uint256 _chainId,
        bytes32 _element,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader,
        Lib_OVMCodec.ChainInclusionProof memory _proof
    )
        override
        public
        view
        returns (
            bool
        )
    {
        require(
            _isValidBatchHeaderByChainId(_chainId,_batchHeader),
            "Invalid batch header."
        );

        require(
            Lib_MerkleTree.verify(
                _batchHeader.batchRoot,
                _element,
                _proof.index,
                _proof.siblings,
                _batchHeader.batchSize
            ),
            "Invalid inclusion proof."
        );

        return true;
    }

    /**
     * @inheritdoc IStateCommitmentChain
     */
    function insideFraudProofWindowByChainId(
        uint256 _chainId,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        override
        public
        view
        returns (
            bool _inside
        )
    {
        (uint256 timestamp,) = abi.decode(
            _batchHeader.extraData,
            (uint256, address)
        );

        require(
            timestamp != 0,
            "Batch header timestamp cannot be zero"
        );
        return timestamp + FRAUD_PROOF_WINDOW > block.timestamp;
    }
    

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Parses the batch context from the extra data.
     * @return Total number of elements submitted.
     * @return Timestamp of the last batch submitted by the sequencer.
     */
    function _getBatchExtraDataByChainId(
        uint256 _chainId
        )
        internal
        view
        returns (
            uint40,
            uint40
        )
    {
        bytes27 extraData = batches().getGlobalMetadataByChainId(_chainId);

        uint40 totalElements;
        uint40 lastSequencerTimestamp;
        assembly {
            extraData              := shr(40, extraData)
            totalElements          :=         and(extraData, 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF)
            lastSequencerTimestamp := shr(40, and(extraData, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000))
        }

        return (
            totalElements,
            lastSequencerTimestamp
        );
    }

    /**
     * Encodes the batch context for the extra data.
     * @param _totalElements Total number of elements submitted.
     * @param _lastSequencerTimestamp Timestamp of the last batch submitted by the sequencer.
     * @return Encoded batch context.
     */
    function _makeBatchExtraDataByChainId(
        uint256 _chainId,
        uint40 _totalElements,
        uint40 _lastSequencerTimestamp
    )
        internal
        pure
        returns (
            bytes27
        )
    {
        bytes27 extraData;
        assembly {
            extraData := _totalElements
            extraData := or(extraData, shl(40, _lastSequencerTimestamp))
            extraData := shl(40, extraData)
        }

        return extraData;
    }

    /**
     * Appends a batch to the chain.
     * @param _batch Elements within the batch.
     * @param _extraData Any extra data to append to the batch.
     */
    function _appendBatchByChainId(
        uint256 _chainId,
        bytes32[] memory _batch,
        bytes memory _extraData,
        address proposer
    )
        internal
    {
        (uint40 totalElements, uint40 lastSequencerTimestamp) = _getBatchExtraDataByChainId(_chainId);

        if (msg.sender == proposer) {
            lastSequencerTimestamp = uint40(block.timestamp);
        } else {
            // We keep track of the last batch submitted by the sequencer so there's a window in
            // which only the sequencer can publish state roots. A window like this just reduces
            // the chance of "system breaking" state roots being published while we're still in
            // testing mode. This window should be removed or significantly reduced in the future.
            require(
                lastSequencerTimestamp + SEQUENCER_PUBLISH_WINDOW < block.timestamp,
                "Cannot publish state roots within the sequencer publication window."
            );
        }

        // For efficiency reasons getMerkleRoot modifies the `_batch` argument in place
        // while calculating the root hash therefore any arguments passed to it must not
        // be used again afterwards
        Lib_OVMCodec.ChainBatchHeader memory batchHeader = Lib_OVMCodec.ChainBatchHeader({
            batchIndex: getTotalBatchesByChainId(_chainId),
            batchRoot: Lib_MerkleTree.getMerkleRoot(_batch),
            batchSize: _batch.length,
            prevTotalElements: totalElements,
            extraData: _extraData
        });

        emit StateBatchAppended(
            _chainId,
            batchHeader.batchIndex,
            batchHeader.batchRoot,
            batchHeader.batchSize,
            batchHeader.prevTotalElements,
            batchHeader.extraData
        );

        batches().pushByChainId(
            _chainId,
            Lib_OVMCodec.hashBatchHeader(batchHeader),
            _makeBatchExtraDataByChainId(
                _chainId,
                uint40(batchHeader.prevTotalElements + batchHeader.batchSize),
                lastSequencerTimestamp
            )
        );
    }

    /**
     * Removes a batch and all subsequent batches from the chain.
     * @param _batchHeader Header of the batch to remove.
     */
    function _deleteBatchByChainId(
        uint256 _chainId,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        internal
    {
        require(
            _batchHeader.batchIndex < batches().lengthByChainId(_chainId),
            "Invalid batch index."
        );

        require(
            _isValidBatchHeaderByChainId(_chainId,_batchHeader),
            "Invalid batch header."
        );

        batches().deleteElementsAfterInclusiveByChainId(
            _chainId,
            _batchHeader.batchIndex,
            _makeBatchExtraDataByChainId(
                _chainId,
                uint40(_batchHeader.prevTotalElements),
                0
            )
        );

        emit StateBatchDeleted(
            _chainId,
            _batchHeader.batchIndex,
            _batchHeader.batchRoot
        );
    }

    /**
     * Checks that a batch header matches the stored hash for the given index.
     * @param _batchHeader Batch header to validate.
     * @return Whether or not the header matches the stored one.
     */
    function _isValidBatchHeaderByChainId(
        uint256 _chainId,
        Lib_OVMCodec.ChainBatchHeader memory _batchHeader
    )
        internal
        view
        returns (
            bool
        )
    {
        return Lib_OVMCodec.hashBatchHeader(_batchHeader) == batches().getByChainId(_chainId,_batchHeader.batchIndex);
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}