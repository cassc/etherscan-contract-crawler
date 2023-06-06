//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IBullaManager.sol";

struct Multihash {
    bytes32 hash;
    uint8 hashFunction;
    uint8 size;
}

enum Status {
    Pending,
    Repaying,
    Paid,
    Rejected,
    Rescinded
}

struct Claim {
    uint256 claimAmount;
    uint256 paidAmount;
    Status status;
    uint256 dueBy;
    address debtor;
    address claimToken;
    Multihash attachment;
}

interface IBullaClaim {
    event ClaimCreated(
        address bullaManager,
        uint256 indexed tokenId,
        address parent,
        address indexed creditor,
        address indexed debtor,
        address origin,
        string description,
        Claim claim,
        uint256 blocktime
    );

    event ClaimPayment(
        address indexed bullaManager,
        uint256 indexed tokenId,
        address indexed debtor,
        address paidBy,
        address paidByOrigin,
        uint256 paymentAmount,
        uint256 blocktime
    );

    event ClaimRejected(
        address indexed bullaManager,
        uint256 indexed tokenId,
        uint256 blocktime
    );

    event ClaimRescinded(
        address indexed bullaManager,
        uint256 indexed tokenId,
        uint256 blocktime
    );

    event FeePaid(
        address indexed bullaManager,
        uint256 indexed tokenId,
        address indexed collectionAddress,
        uint256 paymentAmount,
        uint256 transactionFee,
        uint256 blocktime
    );

    event BullaManagerSet(
        address indexed prevBullaManager,
        address indexed newBullaManager,
        uint256 blocktime
    );

    function createClaim(
        address creditor,
        address debtor,
        string memory description,
        uint256 claimAmount,
        uint256 dueBy,
        address claimToken,
        Multihash calldata attachment
    ) external returns (uint256 newTokenId);

    function createClaimWithURI(
        address creditor,
        address debtor,
        string memory description,
        uint256 claimAmount,
        uint256 dueBy,
        address claimToken,
        Multihash calldata attachment,
        string calldata _tokenUri
    ) external returns (uint256 newTokenId);

    function payClaim(uint256 tokenId, uint256 paymentAmount) external;

    function rejectClaim(uint256 tokenId) external;

    function rescindClaim(uint256 tokenId) external;

    function getClaim(uint256 tokenId) external view returns (Claim calldata);

    function bullaManager() external view returns (address);
}