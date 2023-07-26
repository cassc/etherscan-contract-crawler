// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {AxiomV1Access} from "./AxiomV1Access.sol";
import {IAxiomV1State} from "./interfaces/core/IAxiomV1State.sol";
import {IAxiomV1Verifier} from "./interfaces/core/IAxiomV1Verifier.sol";
import {IAxiomV1Query, QUERY_MERKLE_DEPTH} from "./interfaces/IAxiomV1Query.sol";
import {MerkleTree} from "./libraries/MerkleTree.sol";
import "./libraries/configuration/AxiomV1Configuration.sol";

/// @title  AxiomV1Query
/// @notice Axiom smart contract that verifies batch queries into block headers, accounts, and storage slots.
/// @dev    Is a UUPS upgradeable contract.
contract AxiomV1Query is IAxiomV1Query, AxiomV1Access, UUPSUpgradeable {
    using Address for address payable;

    address public axiomAddress; // address of deployed AxiomV1 contract
    address public mmrVerifierAddress; // address of deployed ZKP verifier for MMR query verification

    mapping(bytes32 => bool) public verifiedKeccakResults;
    mapping(bytes32 => bool) public verifiedPoseidonResults;

    uint256 public minQueryPrice;
    uint256 public maxQueryPrice;
    uint32 public queryDeadlineInterval;
    mapping(bytes32 => AxiomQueryMetadata) public queries;

    error BlockHashNotValidatedInCache();
    error BlockMerkleRootDoesNotMatchProof();
    error ProofVerificationFailed();
    error MMRProofVerificationFailed();
    error MMREndBlockNotRecent();
    error BlockHashWitnessNotRecent();
    error ClaimedMMRDoesNotMatchRecent();

    error HistoricalMMRKeccakDoesNotMatchProof();   
    error KeccakQueryResponseDoesNotMatchProof();

    error QueryNotInactive();
    error PriceNotPaid();
    error PriceTooHigh();
    error CannotRefundIfNotActive();
    error CannotRefundBeforeDeadline();
    error CannotFulfillIfNotActive();

    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @notice Prevents the implementation contract from being initialized outside of the upgradeable proxy.
    constructor() {
        _disableInitializers();
    }

    function initialize(address _axiomAddress, address _mmrVerifierAddress, uint256 _minQueryPrice, uint256 _maxQueryPrice, uint32 _queryDeadlineInterval, address timelock, address guardian)
        public
        initializer
    {
        __UUPSUpgradeable_init();
        __AxiomV1Access_init_unchained();

        require(_axiomAddress != address(0), "AxiomV1Query: Axiom address is zero");
        require(_mmrVerifierAddress != address(0), "AxiomV1Query: MMR verifier address is zero");
        require(timelock != address(0), "AxiomV1Query: timelock address is zero");
        require(guardian != address(0), "AxiomV1Query: guardian address is zero");

        axiomAddress = _axiomAddress;
        mmrVerifierAddress = _mmrVerifierAddress;
        emit UpdateAxiomAddress(_axiomAddress);
        emit UpdateMMRVerifierAddress(_mmrVerifierAddress);

        minQueryPrice = _minQueryPrice;
        maxQueryPrice = _maxQueryPrice;
        queryDeadlineInterval = _queryDeadlineInterval;
        emit UpdateMinQueryPrice(_minQueryPrice);
        emit UpdateMaxQueryPrice(_maxQueryPrice);
        emit UpdateQueryDeadlineInterval(_queryDeadlineInterval);

        // prover is initialized to the contract deployer
        _grantRole(PROVER_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, timelock);
        _grantRole(TIMELOCK_ROLE, timelock);
        _grantRole(GUARDIAN_ROLE, guardian);
    }

    /// @notice Updates the address of the AxiomV1Core contract used to validate blockhashes, governed by a 'timelock'.
    /// @param  _axiomAddress the new address
    function updateAxiomAddress(address _axiomAddress) external onlyRole(TIMELOCK_ROLE) {
        axiomAddress = _axiomAddress;
        emit UpdateAxiomAddress(_axiomAddress);
    }

    /// @notice Updates the address of the MMR SNARK verifier contract, governed by a 'timelock'.
    /// @param  _mmrVerifierAddress the new address
    function updateMMRVerifierAddress(address _mmrVerifierAddress) external onlyRole(TIMELOCK_ROLE) {
        mmrVerifierAddress = _mmrVerifierAddress;
        emit UpdateMMRVerifierAddress(_mmrVerifierAddress);
    }

    /// @notice Set the price of a query, governed by a 'timelock'.
    /// @param  _minQueryPrice query price in wei
    function updateMinQueryPrice(uint256 _minQueryPrice) external onlyRole(TIMELOCK_ROLE) {
        minQueryPrice = _minQueryPrice;
        emit UpdateMinQueryPrice(_minQueryPrice);
    }

    /// @notice Set the price of a query, governed by a 'timelock'.
    /// @param  _maxQueryPrice query price in wei
    function updateMaxQueryPrice(uint256 _maxQueryPrice) external onlyRole(TIMELOCK_ROLE) {
        maxQueryPrice = _maxQueryPrice;
        emit UpdateMaxQueryPrice(_maxQueryPrice);
    }    

    /// @notice Set the query deadline interval, governed by a 'timelock'.
    /// @param  _queryDeadlineInterval interval in blocks
    function updateQueryDeadlineInterval(uint32 _queryDeadlineInterval) external onlyRole(TIMELOCK_ROLE) {
        queryDeadlineInterval = _queryDeadlineInterval;
        emit UpdateQueryDeadlineInterval(_queryDeadlineInterval);
    }

    function verifyResultVsMMR(
        uint32 mmrIdx,
        RecentMMRWitness calldata mmrWitness, 
        bytes calldata proof) external onlyProver {
        requireNotFrozen();
        _verifyResultVsMMR(mmrIdx, mmrWitness, proof);
    }

    function sendQuery(bytes32 keccakQueryResponse, address payable refundee, bytes calldata query) external payable {
        requireNotFrozen();
        // Check for minimum payment        
        if (msg.value < minQueryPrice) {
            revert PriceNotPaid();
        }
        // Check for maximum payment
        if (msg.value > maxQueryPrice) {
            revert PriceTooHigh();
        }
        _sendQuery(keccakQueryResponse, msg.value, refundee);
        bytes32 queryHash = keccak256(query);
        emit QueryInitiatedOnchain(keccakQueryResponse, msg.value, uint32(block.number) + queryDeadlineInterval, refundee, queryHash);
    }

    function sendOffchainQuery(bytes32 keccakQueryResponse, address payable refundee, bytes32 ipfsHash) external payable {
        requireNotFrozen();
        // Check for minimum payment        
        if (msg.value < minQueryPrice) {
            revert PriceNotPaid();
        }
        // Check for maximum payment
        if (msg.value > maxQueryPrice) {
            revert PriceTooHigh();
        }        
        _sendQuery(keccakQueryResponse, msg.value, refundee);
        emit QueryInitiatedOffchain(keccakQueryResponse, msg.value, uint32(block.number) + queryDeadlineInterval, refundee, ipfsHash);        
    }

    function fulfillQueryVsMMR(
        bytes32 keccakQueryResponse, 
        address payable payee, 
        uint32 mmrIdx, 
        RecentMMRWitness calldata mmrWitness,
        bytes calldata proof
    ) external onlyProver {
        requireNotFrozen();

        if (queries[keccakQueryResponse].state != AxiomQueryState.Active) {
            revert CannotFulfillIfNotActive();
        }

        bytes32 proofKeccakQueryResponse = _verifyResultVsMMR(mmrIdx, mmrWitness, proof);

        if (proofKeccakQueryResponse != keccakQueryResponse) {
            revert KeccakQueryResponseDoesNotMatchProof();
        }

        AxiomQueryMetadata memory newMetadata = AxiomQueryMetadata({
            payment:queries[keccakQueryResponse].payment,
            state:AxiomQueryState.Fulfilled,
            deadlineBlockNumber:queries[keccakQueryResponse].deadlineBlockNumber,
            refundee:queries[keccakQueryResponse].refundee
        });
        queries[keccakQueryResponse] = newMetadata;

        payee.sendValue(queries[keccakQueryResponse].payment);
        emit QueryFulfilled(keccakQueryResponse, queries[keccakQueryResponse].payment, payee);
    }

    function collectRefund(bytes32 keccakQueryResponse) external {
        AxiomQueryMetadata memory queryMetadata = queries[keccakQueryResponse];
        if (queryMetadata.state != AxiomQueryState.Active) {
            revert CannotRefundIfNotActive();
        }
        if (block.number <= queryMetadata.deadlineBlockNumber) {
            revert CannotRefundBeforeDeadline();
        }

        AxiomQueryMetadata memory newMetadata = AxiomQueryMetadata({
            payment:0,
            state:AxiomQueryState.Inactive,
            deadlineBlockNumber:0,
            refundee:payable(address(0))
        });
        queries[keccakQueryResponse] = newMetadata;

        queryMetadata.refundee.sendValue(queryMetadata.payment);
        emit QueryRefunded(keccakQueryResponse, queryMetadata.payment, queryMetadata.deadlineBlockNumber, queryMetadata.refundee);
    }            

    function isKeccakResultValid(bytes32 keccakBlockResponse, bytes32 keccakAccountResponse, bytes32 keccakStorageResponse)
        external
        view
        returns (bool) 
    {
        return verifiedKeccakResults[keccak256(abi.encodePacked(keccakBlockResponse, keccakAccountResponse, keccakStorageResponse))];
    }

    function isPoseidonResultValid(bytes32 poseidonBlockResponse, bytes32 poseidonAccountResponse, bytes32 poseidonStorageResponse)
        external
        view
        returns (bool) 
    {
        return verifiedPoseidonResults[keccak256(abi.encodePacked(poseidonBlockResponse, poseidonAccountResponse, poseidonStorageResponse))];
    }    

    function areResponsesValid(
        bytes32 keccakBlockResponse,
        bytes32 keccakAccountResponse,
        bytes32 keccakStorageResponse,
        BlockResponse[] calldata blockResponses,
        AccountResponse[] calldata accountResponses,
        StorageResponse[] calldata storageResponses
    ) external view returns (bool) {
        if (!verifiedKeccakResults[keccak256(abi.encodePacked(keccakBlockResponse, keccakAccountResponse, keccakStorageResponse))]) {
            return false;
        }

        for (uint32 idx = 0; idx < blockResponses.length; idx++) {
            bytes32 leaf = keccak256(abi.encodePacked(
                blockResponses[idx].blockHash,
                blockResponses[idx].blockNumber
            ));
            if (!isMerklePathValid(keccakBlockResponse, leaf, blockResponses[idx].proof, blockResponses[idx].leafIdx)) {
                return false;
            }
        }

        // `keccakAccountResponse` is the Merkle root of the packed addresses:
        //    * `keccak(blockNumber . addr . keccak(nonce . balance . storageRoot . codeHash))`.
        for (uint32 idx = 0; idx < accountResponses.length; idx++) {
            bytes32 leaf = keccak256(abi.encodePacked(
                accountResponses[idx].blockNumber,
                accountResponses[idx].addr,
                keccak256(abi.encodePacked(
                    accountResponses[idx].nonce,
                    accountResponses[idx].balance,
                    accountResponses[idx].storageRoot,
                    accountResponses[idx].codeHash
                ))
            ));
            if (!isMerklePathValid(keccakAccountResponse, leaf, accountResponses[idx].proof, accountResponses[idx].leafIdx)) {
                return false;
            }
        }

        for (uint32 idx = 0; idx < storageResponses.length; idx++) {
            bytes32 leaf = keccak256(abi.encodePacked(
                storageResponses[idx].blockNumber,
                storageResponses[idx].addr,
                storageResponses[idx].slot,
                storageResponses[idx].value
            ));
            if (!isMerklePathValid(keccakStorageResponse, leaf, storageResponses[idx].proof, storageResponses[idx].leafIdx)) {
                return false;
            }
        }
        return true;            
    } 

    /// @notice Record on-chain query.
    /// @param  keccakQueryResponse The hash of the query response.
    /// @param  payment The payment offered, in wei.
    /// @param  refundee The address to send any refund to.
    function _sendQuery(bytes32 keccakQueryResponse, uint256 payment, address payable refundee) internal {
        if (queries[keccakQueryResponse].state != AxiomQueryState.Inactive) {
            revert QueryNotInactive();
        }

        AxiomQueryMetadata memory queryMetadata = AxiomQueryMetadata({
            payment:payment,
            state:AxiomQueryState.Active,
            deadlineBlockNumber:uint32(block.number) + queryDeadlineInterval,
            refundee:refundee
        });
        queries[keccakQueryResponse] = queryMetadata;   
    }

    /// @notice Verify a query result on-chain.
    /// @param  mmrIdx The index of the cached MMR to verify against.
    /// @param  mmrWitness Witness data to reconcile `recentMMR` against `historicalRoots`.
    /// @param  proof The ZK proof data.
    function _verifyResultVsMMR(
        uint32 mmrIdx,
        RecentMMRWitness calldata mmrWitness,
        bytes calldata proof
    ) internal returns (bytes32) {
        requireNotFrozen(); 
        require(mmrIdx < MMR_RING_BUFFER_SIZE);

        AxiomMMRQueryResponse memory response = getMMRQueryData(proof);        

        // Check that the historical MMR matches a cached value in `mmrRingBuffer`
        if (IAxiomV1State(axiomAddress).mmrRingBuffer(mmrIdx) != response.historicalMMRKeccak) {
            revert HistoricalMMRKeccakDoesNotMatchProof();
        }

        // recentMMRKeccak = keccak(mmr[0] . mmr[1] . ... . mmr[9]), where mmr[idx] is either bytes32(0) or the Merkle root of 2 ** idx hashes
        // historicalRoots(startBlockNumber) = keccak256(prevHash . root . numFinal) 
        //         - root is the keccak Merkle root of hash(i) for i in [0, 1024), where
        //             hash(i) is the blockhash of block `startBlockNumber + i` if i < numFinal,
        //             hash(i) = bytes32(0x0) if i >= numFinal
        // We check that `recentMMRPeaks` is included in `historicalRoots[startBlockNumber].root` via `mmrComplementOrPeaks`
        // This proves that all block hashes committed to in `recentMMRPeaks` are part of the canonical chain.
        {
            bytes32 historicalRoot = IAxiomV1State(axiomAddress).historicalRoots(mmrWitness.startBlockNumber); 
            require(historicalRoot == keccak256(abi.encodePacked(mmrWitness.prevHash, mmrWitness.root, mmrWitness.numFinal)));
        }

        require(response.recentMMRKeccak == keccak256(abi.encodePacked(mmrWitness.recentMMRPeaks)));
        uint32 mmrLen = 0;
        for (uint32 idx = 0; idx < 10; idx++) {
            if (mmrWitness.recentMMRPeaks[idx] != bytes32(0)) {
                mmrLen = mmrLen + uint32(1 << idx);
            }
        }

        // if `mmrLen == 0`, there is no check necessary against blocks
        if (mmrLen > 0 && mmrLen <= mmrWitness.numFinal) {
            // In this case, the full `mmrWitness` should be committed to in `mmrWitness.root`
            // In this branch, `mmrWitness.mmrComplementOrPeaks` holds the complementary MMR which completes `mmrWitness`
            // We check that 
            //    * The MMR in `mmrWitness` can be completed to `mmrWitness.root`
            // This proves that the MMR in `mmrWitness` is the MMR of authentic block hashes with 0's appended.
            // Under the random oracle assumption, 0 can never be achieved as keccak of an erroenous block header,
            // so there is no soundness risk here.
            (bytes32 runningHash, ) = getMMRComplementRoot(mmrWitness.recentMMRPeaks, mmrWitness.mmrComplementOrPeaks);
            require(mmrWitness.root == runningHash);            
        } else if (mmrLen > mmrWitness.numFinal) {
            // Some of the claimed block hashes in `mmrWitness` were not committed to in `mmrWitness`
            // In this branch, `mmrWitness.mmrComplementOrPeaks` holds the MMR values of the non-zero hashes in `root`
            // We check that
            //    * block hashes for numbers [startBlockNumber + numFinal, startBlockNumber + mmrLen) are recent
            //    * appending these block hashes to the committed MMR in `mmrWitness` (without 0-padding) yields the MMR in `mmrWitness`
            if (mmrWitness.startBlockNumber + mmrLen > block.number) {
                revert MMREndBlockNotRecent();
            }
            if (mmrWitness.startBlockNumber + mmrWitness.numFinal < block.number - 256) {
                revert BlockHashWitnessNotRecent();
            }

            // zeroHashes[idx] is the Merkle root of a tree of depth idx with 0's as leaves
            bytes32[10] memory zeroHashes = [
                bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
                bytes32(0xad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5),
                bytes32(0xb4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30),
                bytes32(0x21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85),
                bytes32(0xe58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344),
                bytes32(0x0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d),
                bytes32(0x887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968),
                bytes32(0xffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83),
                bytes32(0x9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af),
                bytes32(0xcefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0)
            ];
            // read the committed MMR without zero-padding
            (bytes32 runningHash, uint32 runningSize) = getMMRComplementRoot(mmrWitness.mmrComplementOrPeaks, zeroHashes);
            require(mmrWitness.numFinal == runningSize);
            require(mmrWitness.root == runningHash);            

            // check appending to the committed MMR with recent blocks will yield the claimed MMR
            {
                bytes32[] memory append = new bytes32[](mmrLen - mmrWitness.numFinal);
                for (uint32 idx = 0; idx < mmrLen - mmrWitness.numFinal; idx++) {
                    append[idx] = blockhash(mmrWitness.startBlockNumber + mmrWitness.numFinal + idx);
                }
                uint32 appendLeft = mmrLen - mmrWitness.numFinal;
                uint32 height = 0;
                uint32 insert = 0;
                while (appendLeft > 0) {
                    insert = (mmrWitness.numFinal >> height) & 1;
                    for (uint32 idx = 0; idx < (appendLeft + insert) / 2; idx++) {
                        bytes32 left;
                        bytes32 right;
                        if (insert == 1) {
                            left = (idx == 0 ? mmrWitness.mmrComplementOrPeaks[height] : append[2 * idx - 1]);
                            right = append[2 * idx];
                        } else {
                            left = append[2 * idx];
                            right = append[2 * idx + 1];
                        }
                        append[idx] = keccak256(abi.encodePacked(left, right));
                    }
                    if ((appendLeft + insert) % 2 == 1) {                  
                        if (append[appendLeft - 1] != mmrWitness.recentMMRPeaks[height]) {
                            revert ClaimedMMRDoesNotMatchRecent();
                        }
                    } else {
                        // This should not be possible, but leaving this revert in for safety.
                        if (mmrWitness.recentMMRPeaks[height] != 0) {
                            revert ClaimedMMRDoesNotMatchRecent();
                        }
                    }
                    height = height + 1;
                    appendLeft = (appendLeft + insert) / 2;
                }
            }
        }

        // verify the ZKP itself
        (bool success, ) = mmrVerifierAddress.call(proof);
        if (!success) {
            revert MMRProofVerificationFailed();
        }

        // update the cache
        bytes32 keccakQueryResponse = keccak256(abi.encodePacked(response.keccakBlockResponse, response.keccakAccountResponse, response.keccakStorageResponse));

        verifiedKeccakResults[keccakQueryResponse] = true;
        verifiedPoseidonResults[keccak256(abi.encodePacked(response.poseidonBlockResponse, response.poseidonAccountResponse, response.poseidonStorageResponse))] = true;
        emit KeccakResultEvent(response.keccakBlockResponse, response.keccakAccountResponse, response.keccakStorageResponse);
        emit PoseidonResultEvent(response.poseidonBlockResponse, response.poseidonAccountResponse, response.poseidonStorageResponse);
        return keccakQueryResponse;
    }

    /// @dev    Given a non-empty MMR `mmr`, compute its `size` and the Merkle root of its completion to 1024 leaves using `mmrComplement`
    /// @param  mmr The peaks of a MMR, where `mmr[idx]` is either `bytes32(0x0)` or the Merkle root of a tree of depth `idx`.  
    ///         At least one peak is guaranteed to be non-zero.
    /// @param  mmrComplement Entries which contain peaks of a complementary MMR, where `mmrComplement[idx]` is either `bytes32(0x0)` or the
    ///         Merkle root of a tree of depth `idx`.  Only the relevant indices are accessed.
    /// @dev    As an example, if `mmr` has peaks of depth 9 8 6 3, then `mmrComplement` has peaks of depth 3 4 5 7
    ///         In this example, the peaks of `mmr` are Merkle roots of the first 2^9 leaves, then the next 2^8 leaves, and so on.
    ///         The peaks of `mmrComplement` are Merkle roots of the first 2^3 leaves after `mmr`, then the next 2^4 leaves, and so on.
    /// @return root The Merkle root of the completion of `mmr`.
    /// @return size The number of leaves contained in `mmr`.
    function getMMRComplementRoot(bytes32[10] memory mmr, bytes32[10] memory mmrComplement) internal pure returns (bytes32 root, uint32 size) {
        bool started = false;
        root = bytes32(0x0);
        size = 0;
        for (uint32 peakIdx = 0; peakIdx < 10; peakIdx++) {
            if (!started && mmr[peakIdx] != bytes32(0x0)) {
                root = mmrComplement[peakIdx];
                started = true;
            }
            if (started) {
                if (mmr[peakIdx] != bytes32(0x0)) {
                    root = keccak256(abi.encodePacked(mmr[peakIdx], root));
                    size = size + uint32(1 << peakIdx);
                } else {
                    root = keccak256(abi.encodePacked(root, mmrComplement[peakIdx]));
                }
            }
        }
    }

    /// @dev   Verify a Merkle inclusion proof into a Merkle tree with (1 << proof.length) leaves
    /// @param root The Merkle root.
    /// @param leaf The claimed leaf in the tree.
    /// @param proof The Merkle proof, where index 0 corresponds to a leaf in the tree.
    /// @param leafIdx The claimed index of the leaf in the tree, where index 0 corresponds to the leftmost leaf.
    function isMerklePathValid(bytes32 root, bytes32 leaf, bytes32[QUERY_MERKLE_DEPTH] memory proof, uint32 leafIdx) internal pure returns (bool) {
        bytes32 runningHash = leaf;
        for (uint32 idx = 0; idx < proof.length; idx++) {
            if ((leafIdx >> idx) & 1 == 0) {
                runningHash = keccak256(abi.encodePacked(runningHash, proof[idx]));
            } else {
                runningHash = keccak256(abi.encodePacked(proof[idx], runningHash));
            }
        }
        return (root == runningHash);
    }

    /// @dev   Extract public instances from proof.
    /// @param proof The ZK proof.
    // The public instances are laid out in the proof calldata as follows:
    //   ** First 4 * 3 * 32 = 384 bytes are reserved for proof verification data used with the pairing precompile
    //   ** The next blocks of 13 groups of 32 bytes each are:
    //   ** `poseidonBlockResponse`            as a field element
    //   ** `keccakBlockResponse`              as 2 field elements, in hi-lo form
    //   ** `poseidonAccountResponse`          as a field element
    //   ** `keccakAccountResponse`            as 2 field elements, in hi-lo form
    //   ** `poseidonStorageResponse`          as a field element
    //   ** `keccakStorageResponse`            as 2 field elements, in hi-lo form
    //   ** `historicalMMRKeccak` which is `keccak256(abi.encodePacked(mmr[10:]))` as 2 field elements in hi-lo form.
    //   ** `recentMMRKeccak`     which is `keccak256(abi.encodePacked(mmr[:10]))` as 2 field elements in hi-lo form.
    // Here:
    //   ** `{keccak, poseidon}{Block, Account, Storage}Response` are defined as in `AxiomMMRQueryResponse`.
    //   ** hi-lo form means a uint256 `(a << 128) + b` is represented as two uint256's `a` and `b`, each of which is
    //      guaranteed to contain a uint128.
    //   ** `mmr` is a variable length array of bytes32 containing the Merkle Mountain Range that `proof` is proving into.
    //      `mmr[idx]` is either `bytes32(0)` or the Merkle root of `1 << idx` block hashes.
    //   ** `mmr` is guaranteed to have length at least `10` and at most `32`.
    function getMMRQueryData(bytes calldata proof)
        internal 
        pure
        returns (AxiomMMRQueryResponse memory)
    {
        return AxiomMMRQueryResponse({
            poseidonBlockResponse:bytes32(proof[384:384 + 32]),
            keccakBlockResponse:bytes32(uint256(bytes32(proof[384 + 32: 384 + 2 * 32])) << 128 | uint256(bytes32(proof[384 + 2 * 32: 384 + 3 * 32]))),
            poseidonAccountResponse:bytes32(proof[384 + 3 * 32:384 + 4 * 32]),
            keccakAccountResponse:bytes32(uint256(bytes32(proof[384 + 4 * 32: 384 + 5 * 32])) << 128 | uint256(bytes32(proof[384 + 5 * 32: 384 + 6 * 32]))),
            poseidonStorageResponse:bytes32(proof[384 + 6 * 32:384 + 7 * 32]),
            keccakStorageResponse:bytes32(uint256(bytes32(proof[384 + 7 * 32: 384 + 8 * 32])) << 128 | uint256(bytes32(proof[384 + 8 * 32: 384 + 9 * 32]))),
            historicalMMRKeccak:bytes32(uint256(bytes32(proof[384 + 9 * 32: 384 + 10 * 32])) << 128 | uint256(bytes32(proof[384 + 10 * 32: 384 + 11 * 32]))),
            recentMMRKeccak:bytes32(uint256(bytes32(proof[384 + 11 * 32: 384 + 12 * 32])) << 128 | uint256(bytes32(proof[384 + 12 * 32: 384 + 13 * 32])))
        });
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool) {
        return interfaceId == type(IAxiomV1Query).interfaceId || super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address) internal override onlyRole(TIMELOCK_ROLE) {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;    
}