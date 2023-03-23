// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @notice The Time Stamping contract is used to store timestamps of documents.
 */
interface ITimeStamping {
    /**
     * @notice A structure that stores information about timestamp
     * @param timestamp a timestamp
     * @param usersSigned a count of users that signed this timestamp
     * @param isPublic a flag that shows if timestamp is public
     * @param signers an array of signers
     */
    struct StampInfo {
        uint256 timestamp;
        uint256 usersSigned;
        bool isPublic;
        EnumerableSet.AddressSet signers;
    }

    /**
     * @notice A structure that stores information about signer of certain timestamp
     * @param signer a signer
     * @param isAddmitted a flag that shows if signer is admitted
     * @param signatureTimestamp a timestamp of signature
     */
    struct SignerInfo {
        address signer;
        bool isAddmitted;
        uint256 signatureTimestamp;
    }

    /**
     * @notice A structure that stores detailed information about timestamp
     * @param isPublic a flag that shows if timestamp is public
     * @param timestamp a timestamp
     * @param usersToSign a total number of users
     * @param usersSigned a number of users who already signed
     * @param stampHash a hash of timestamp
     * @param signersInfo an array with info about signers
     */
    struct DetailedStampInfo {
        bool isPublic;
        uint256 timestamp;
        uint256 usersToSign;
        uint256 usersSigned;
        bytes32 stampHash;
        SignerInfo[] signersInfo;
    }

    /**
     * @notice A structure that stores information about ZKP
     * @param a an array of parameters A for ZKP
     * @param b a matrix of parameters B for ZKP
     * @param c an array of parameters C for ZKP
     */
    struct ZKPPoints {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    /**
     * @notice The event that is emitted during the adding new timestamps
     * @param stampHash a hash of the added timestamp
     * @param timestamp a timestamp
     * @param signers an array of signers
     */
    event StampCreated(bytes32 indexed stampHash, uint256 timestamp, address[] signers);

    /**
     * @notice The event that is emitted during the signing stamp by user
     * @param stampHash a hash
     * @param signer a address of the signer
     */
    event StampSigned(bytes32 indexed stampHash, address indexed signer);

    /**
     * @notice Function for initial initialization of contract parameters
     * @param fee_ a fee for stamp creation
     * @param verifier_ an address of verifier contract
     * @param poseidonHash_ an address of poseidon hash contract
     */
    function __TimeStamping_init(
        uint256 fee_,
        address verifier_,
        address poseidonHash_
    ) external;

    /**
     * @notice Function to set verifier address
     * @param verifier_ an address of verifier
     */
    function setVerifier(address verifier_) external;

    /**
     * @notice Function for set fee for timestamp creation
     * @param fee_ a fee for timestamp creation
     */
    function setFee(uint256 fee_) external;

    /**
     * @notice Function for obtain fee for timestamp creation
     * @return fee a fee for timestamp creation
     */
    function fee() external view returns (uint256);

    /**
     * @notice Function for admin to withdraw fee
     * @param recipient an address of recipient
     */
    function withdrawFee(address recipient) external;

    /**
     * @notice Function for create new timestamp with provided signers and approved ZKP, if fee is paid
     * @param stampHash_ a new hash for timestamp
     * @param isSigned_ a parameter that shows whether user sign this stamp
     * @param signers_ an array of signers
     * @param zkpPoints_ a structure with ZKP points
     */
    function createStamp(
        bytes32 stampHash_,
        bool isSigned_,
        address[] calldata signers_,
        ZKPPoints calldata zkpPoints_
    ) external payable;

    /**
     * @notice Function for sign existing timestamp
     * @param stampHash_ an existing hash
     */
    function sign(bytes32 stampHash_) external;

    /**
     * @notice Function for obtain hash of document
     * @param bytes_ a document provided as bytes
     * @return poseidonHash a hash of document
     */
    function getStampHashByBytes(
        bytes calldata bytes_
    ) external view returns (bytes32 poseidonHash);

    /**
     * @notice Function for obtain number of signers of timestamp
     * @param stampHash_ a hash
     * @return count_ a count of signers
     */
    function getStampSignersCount(
        bytes32 stampHash_
    ) external view returns (uint256 count_);

    /**
     * @notice Function for obtain information about hash
     * @param stampHash_ hash of timestamps
     * @return detailedStampInfo_ a structure of informations about hash
     */
    function getStampInfo(
        bytes32 stampHash_
    ) external view returns (DetailedStampInfo memory detailedStampInfo_);

    /**
     * @notice Function for obtain information about hash
     * @param stampHash_ hash of timestamps
     * @param offset_ an offset for pagination
     * @param limit_ a maximum number of elements for pagination
     * @return detailedStampInfo_ aa structure of informations about hash
     */
    function getStampInfoWithPagination(
        bytes32 stampHash_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (DetailedStampInfo memory detailedStampInfo_);

    /**
     * @notice Function for obtain array of hashes that user signed
     * @param user_ an address of user
     * @return stampHashes_ an array of hashes signed by user
     */
    function getHashesByUserAddress(
        address user_
    ) external view returns (bytes32[] memory stampHashes_);

    /**
     * @notice Function to get info about hash and user
     * @param user_ an address of user
     * @param stampHash_ hash of timestamps
     * @return signerInfo a struct with info about provided hash and signer
     */
    function getUserInfo(
        address user_,
        bytes32 stampHash_
    ) external view returns (SignerInfo memory signerInfo);
}