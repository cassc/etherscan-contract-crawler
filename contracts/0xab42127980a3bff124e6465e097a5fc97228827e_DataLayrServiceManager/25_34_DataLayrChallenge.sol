// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";

import "@eigenlayer/contracts/interfaces/IQuorumRegistry.sol";
import "@eigenlayer/contracts/libraries/Merkle.sol";
import "@eigenlayer/contracts/libraries/BytesLib.sol";

import "@eigenlayer/contracts/libraries/BN254.sol";

import "../interfaces/IDataLayrServiceManager.sol";
import "../libraries/DataStoreUtils.sol";
import "./DataLayrChallengeUtils.sol";


/**
 * @title Used to create and manage low degree challenges related to DataLayr.
 * @author Layr Labs, Inc.
 */
contract DataLayrChallenge is Initializable {
    using SafeERC20 for IERC20;
    using BytesLib for bytes;

    IDataLayrServiceManager public immutable dataLayrServiceManager;
    IQuorumRegistry public immutable dlRegistry;
    DataLayrChallengeUtils public immutable challengeUtils;

    //Fixed gas limit to ensure pairing precompile doesn't use entire gas limit upon reversion
    uint256 public constant pairingGasLimit = 500e3;

    enum ChallengeStatus {
        UNSUCCESSFUL,
        SUCCESSFUL
    }

    struct LowDegreeChallenge {
        // challenger's address
        address challenger;
        // challenge status
        ChallengeStatus status;
    }

    struct NonSignerExclusionProof {
        address signerAddress;
        uint32 operatorHistoryIndex;
    }

    event SuccessfulLowDegreeChallenge(bytes32 indexed headerHash, address challenger);

    mapping(bytes32 => LowDegreeChallenge) public lowDegreeChallenges;

    //POT refers to Powers of Tau
    uint256 internal constant MAX_POT_DEGREE = (2 ** 28);
    uint256 internal constant POT_TREE_HEIGHT = 28;

    modifier onlyDataLayrServiceManagerOwner() {
        require(msg.sender == dataLayrServiceManager.owner(), "onlyDataLayrServiceManagerOwner");
        _;
    }

    constructor(
        IDataLayrServiceManager _dataLayrServiceManager,
        IQuorumRegistry _dlRegistry,
        DataLayrChallengeUtils _challengeUtils
    ) {
        dataLayrServiceManager = _dataLayrServiceManager;
        dlRegistry = _dlRegistry;
        challengeUtils = _challengeUtils;
        _disableInitializers();
    }

    /**
     *   @notice verifies all challenger inputs against stored hashes, computes low degreeness proof and
     *   freezes operator if verified as being excluded from nonsigner set.
     *   @param header is the header for the datastore in question.
     *   @param potElement is the G2 point of the POT element we are computing the pairing for (x^{n-m})
     *   @param potMerkleProof is the merkle proof for the POT element.
     *   @param dataStoreSearchData is the all relevant data about the datastore being challenged
     *   @param signatoryRecord is the record of signatures on said datastore
     */
    function challengeLowDegreenessProof(
        bytes calldata header,
        BN254.G2Point memory potElement,
        bytes memory potMerkleProof,
        IDataLayrServiceManager.DataStoreSearchData calldata dataStoreSearchData,
        IDataLayrServiceManager.SignatoryRecordMinusDataStoreId calldata signatoryRecord
    ) external {
        require(
            dataStoreSearchData.metadata.headerHash == keccak256(header),
            "DataLayrLowDegreeChallenge.challengeLowDegreenessProof: provided datastore searchData does not match provided header"
        );

        /// @dev Refer to the datastore header spec for makeup of header
        BN254.G1Point memory lowDegreenessProof;

        //Slice the header to retrieve the lowdegreeness proof (a G1 point)
        assembly {
            mstore(lowDegreenessProof, calldataload(add(header.offset, 116)))
            mstore(add(lowDegreenessProof, 32), calldataload(add(header.offset, 148)))
        }

        //prove searchData, including nonSignerPubkeyHashes (in the form of signatory record in the metadata) matches stored searchData
        require(
            dataLayrServiceManager.verifyDataStoreMetadata(
                dataStoreSearchData.duration,
                dataStoreSearchData.timestamp,
                dataStoreSearchData.index,
                dataStoreSearchData.metadata
            ),
            "DataLayrChallenge.challengeLowDegreeHeader: Provided metadata does not match stored datastore metadata hash"
        );

        bytes32 signatoryRecordHash = DataStoreUtils.computeSignatoryRecordHash(
            dataStoreSearchData.metadata.globalDataStoreId,
            signatoryRecord.nonSignerPubkeyHashes,
            signatoryRecord.signedStakeFirstQuorum,
            signatoryRecord.signedStakeSecondQuorum
        );

        require(
            dataStoreSearchData.metadata.signatoryRecordHash == signatoryRecordHash,
            "DataLayrChallenge.lowDegreeChallenge: provided signatoryRecordHash does not match signatorRecordHash in provided searchData"
        );

        require(
            !verifyLowDegreenessProof(header, potElement, potMerkleProof, lowDegreenessProof),
            "DataLayrChallenge.lowDegreeChallenge: low degreeness proof verified successfully"
        );

        /// @todo before this if condition gets satisfied, we need to update the header in off chain code
        ///       so as to include paddingProof and paddingQuotientPolyCommit in the header. 
        if (challengeUtils.getNumSysFromHeader(header) != uint32(challengeUtils.nextPowerOf2(challengeUtils.getNumSysFromHeader(header)))) {
            BN254.G1Point memory paddingProof;
            assembly {
                mstore(paddingProof, calldataload(add(header.offset, 180)))
                mstore(add(paddingProof, 32), calldataload(add(header.offset, 212)))
            }

            BN254.G1Point memory paddingQuotientPolyCommit;
            assembly {
                mstore(paddingQuotientPolyCommit, calldataload(add(header.offset, 244)))
                mstore(add(paddingQuotientPolyCommit, 32), calldataload(add(header.offset, 276)))
            }
            
            require(
                !verifyZeroPaddingProof(header, paddingProof, paddingQuotientPolyCommit),
                "DataLayrZeroPaddingChallenge.zeroPaddingChallenge: zero padding proof verified successfully"
            );
        }

        bytes32 dataStoreHash = keccak256(abi.encode(dataStoreSearchData));
        lowDegreeChallenges[dataStoreHash] = LowDegreeChallenge(msg.sender, ChallengeStatus.SUCCESSFUL);

        emit SuccessfulLowDegreeChallenge(dataStoreHash, msg.sender);
    }

    ///@notice slash an operator who signed a headerHash but failed a subsequent challenge
    function freezeOperatorsForLowDegreeChallenge(
        NonSignerExclusionProof[] memory nonSignerExclusionProofs,
        uint256 nonSignerIndex,
        IDataLayrServiceManager.DataStoreSearchData calldata searchData,
        IDataLayrServiceManager.SignatoryRecordMinusDataStoreId calldata signatoryRecord
    ) external {
        // prove searchData, including nonSignerPubkeyHashes (in the form of signatory record in the metadata) matches stored searchData
        require(
            dataLayrServiceManager.verifyDataStoreMetadata(
                searchData.duration,
                searchData.timestamp,
                searchData.index,
                searchData.metadata
            ),
            "DataLayrLowDegreeChallenge.freezeOperatorsForLowDegreeChallenge: Provided metadata does not match stored datastore metadata hash"
        );

        bytes32 signatoryRecordHash = DataStoreUtils.computeSignatoryRecordHash(
            searchData.metadata.globalDataStoreId,
            signatoryRecord.nonSignerPubkeyHashes,
            signatoryRecord.signedStakeFirstQuorum,
            signatoryRecord.signedStakeSecondQuorum
        );

        require(
            searchData.metadata.signatoryRecordHash == signatoryRecordHash,
            "DataLayrLowDegreeChallenge.freezeOperatorsForLowDegreeChallenge: provided signatoryRecordHash does not match signatorRecordHash in provided searchData"
        );

        // check that the DataStore in question has already been successfully challenged
        bytes32 dataStoreHash = keccak256(abi.encode(searchData));
        require(lowDegreeChallenges[dataStoreHash].status == ChallengeStatus.SUCCESSFUL,
            "DataLayrLowDegreeChallenge.freezeOperatorsForLowDegreeChallenge:  DataStore has not yet been successfully challenged");

        for (uint256 i; i < nonSignerExclusionProofs.length; i++) {
            address operator = nonSignerExclusionProofs[i].signerAddress;
            uint32 operatorHistoryIndex = nonSignerExclusionProofs[i].operatorHistoryIndex;

            // verify that operator was active *at the blockNumber*
            bytes32 operatorPubkeyHash = dlRegistry.getOperatorPubkeyHash(operator);
            IQuorumRegistry.OperatorStake memory operatorStake =
                dlRegistry.getStakeFromPubkeyHashAndIndex(operatorPubkeyHash, operatorHistoryIndex);
            require(
                // operator must have become active/registered before (or at) the block number
                (operatorStake.updateBlockNumber <= searchData.metadata.referenceBlockNumber)
                // operator must have still been active after (or until) the block number
                // either there is a later update, past the specified blockNumber, or they are still active
                && (
                    operatorStake.nextUpdateBlockNumber >= searchData.metadata.referenceBlockNumber
                        || operatorStake.nextUpdateBlockNumber == 0
                ),
                "DataLayrChallengeBase.freezeOperatorsForLowDegreeChallenge: operator was not active during blockNumber specified by dataStoreId / headerHash"
            );

            if (signatoryRecord.nonSignerPubkeyHashes.length != 0) {
                // check that operator was *not* in the non-signer set (i.e. they *did* sign)
                challengeUtils.checkExclusionFromNonSignerSet(operatorPubkeyHash, nonSignerIndex, signatoryRecord);
            }

            dataLayrServiceManager.freezeOperator(operator);
        }
    }

    /**
     * @notice This function verifies that a polynomial's degree is not greater than a provided degree and returns true if 
               the inputs to the pairing are valid and the pairing is successful.
     * @param header is the header information, which contains the kzg metadata (commitment and degree to check against)
     * @param potElement is the G2 point of the POT element we are computing the pairing for (x^{n-m})
     * @param potMerkleProof is the merkle proof for the POT element.
     * @param lowDegreenessProof is the provided G1 point which is the product of the POTElement and the polynomial, i.e., [(x^{n-m})*p(x)]_1
     *        This function computes the pairing e([p(x)]_1, [x^{n-m}]_2) = e([(x^{n-m})*p(x)]_1, [1]_2)
     */
    function verifyLowDegreenessProof(
        bytes calldata header,
        BN254.G2Point memory potElement,
        bytes memory potMerkleProof,
        BN254.G1Point memory lowDegreenessProof
    ) public view returns (bool) {
        require(potMerkleProof.length/32 ==  POT_TREE_HEIGHT, "DataLayrChallenge.verifyLowDegreenessProof: incorrect proof length");

        //retreiving the kzg commitment to the data in the form of a polynomial
        DataLayrChallengeUtils.DataStoreKZGMetadata memory dskzgMetadata =
            challengeUtils.getDataCommitmentAndMultirevealDegreeAndSymbolBreakdownFromHeader(header);

        //the index of the merkle tree containing the potElement
        uint256 potIndex = MAX_POT_DEGREE - dskzgMetadata.degree * challengeUtils.nextPowerOf2(dskzgMetadata.numSys);
        //computing hash of the powers of Tau element to verify merkle inclusion
        bytes32 hashOfPOTElement = keccak256(abi.encodePacked(potElement.X, potElement.Y));

        require(
            Merkle.verifyInclusionKeccak(potMerkleProof, BN254.powersOfTauMerkleRoot, hashOfPOTElement, potIndex),
            "DataLayrChallenge.proveLowDegreeness: PoT merkle proof failed"
        );

        (bool precompileWorks, bool pairingSuccessful) =
            BN254.safePairing(dskzgMetadata.c, potElement, lowDegreenessProof,  BN254.negGeneratorG2(), pairingGasLimit);

        return (precompileWorks && pairingSuccessful);
    }

    function verifyZeroPaddingProof(
        bytes calldata header,
        BN254.G1Point memory paddingProof,
        BN254.G1Point memory paddingQuotientPolyCommit
    ) public returns (bool) {

        // retreiving the kzg commitment to the data in the form of a polynomial
        DataLayrChallengeUtils.DataStoreKZGMetadata memory dskzgMetadata =
            challengeUtils.getDataCommitmentAndMultirevealDegreeAndSymbolBreakdownFromHeader(header);



        uint32 numNodeE = dskzgMetadata.numSys + dskzgMetadata.numPar;
        uint32 numSysE = uint32(challengeUtils.nextPowerOf2(dskzgMetadata.numSys));
        {
            // This evaluates the ratio [numsys + numPar]/numSys, which is the inverse of the coding ratio
            // and then this is multiplied with numSysE to determine the numNodeE .
            uint32 ratio = numNodeE / dskzgMetadata.numSys + (numNodeE % dskzgMetadata.numSys == 0 ? 0 : 1);
            numNodeE = uint32(challengeUtils.nextPowerOf2(numSysE * ratio));
        }



        
        // getting the challenge for Fiat-Shamir heurestic
        uint256 alpha  = uint256(
                            keccak256(
                                abi.encodePacked( 
                                    bytes32(paddingQuotientPolyCommit.X),
                                    bytes32(paddingQuotientPolyCommit.Y),
                                    bytes32(dskzgMetadata.c.X),
                                    bytes32(dskzgMetadata.c.Y)
                                ))) % BN254.FR_MODULUS;

        // constructing the evaluation of vanishing poly at alpha
        BN254.G1Point memory vanishingPolyEvalPi;
        {
            uint256 vanishingPolyEval = challengeUtils.constructZeroPolyEval(uint256(dskzgMetadata.numSys), uint32(dskzgMetadata.degree + 1), numNodeE, alpha);
            for (uint32 i = dskzgMetadata.numSys+1; i < numSysE; i++) {
                vanishingPolyEval = mulmod(vanishingPolyEval, challengeUtils.constructZeroPolyEval(uint256(i), uint32(dskzgMetadata.degree + 1), numNodeE, alpha), BN254.FR_MODULUS);
            }
            
            // [vanishingPolyEval][paddingQuotientPolyCommit(X)]_1
            vanishingPolyEvalPi = BN254.scalar_mul(paddingQuotientPolyCommit,vanishingPolyEval);
        }

        

        // We will be constructing summand next where 
        // summand is given by = alpha[proof]_1 + [metaPoly(X)]_1 - vanishingPolyEval[paddingQuotientPolyCommit]_1
        BN254.G1Point memory summand;

        // compute alpha[proof]_1
        summand = BN254.scalar_mul(paddingProof, alpha);

        // compute alpha[proof]_1 + [metaPoly]_1
        // summand = BN254.plus(alphaPaddingProof,dskzgMetadata.c);
        summand = BN254.plus(summand,dskzgMetadata.c);

    
        // compute alpha[proof]_1 + [metaPoly(X)]_1 - vanishingPolyEval[paddingQuotientPolyCommit]_1
        summand = BN254.plus(summand, BN254.negate(vanishingPolyEvalPi));

        BN254.G2Point memory negativeG2 = BN254.negGeneratorG2();
        BN254.G2Point memory G2SRS = BN254.G2SRSFirstPower();


        (bool precompileWorks, bool pairingSuccessful) =
            BN254.safePairing(paddingProof, G2SRS, summand, negativeG2, pairingGasLimit);

        return (precompileWorks && pairingSuccessful);

    }
}