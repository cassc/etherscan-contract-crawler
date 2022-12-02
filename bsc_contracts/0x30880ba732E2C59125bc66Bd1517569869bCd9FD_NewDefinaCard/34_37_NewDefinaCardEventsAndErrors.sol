// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * @title NewDefinaCardEventsAndErrors
 * @notice NewDefinaCardEventsAndErrors contains all events and errors.
 */
interface NewDefinaCardEventsAndErrors {

    event MintMulti(address indexed owner, uint _amount);
    event Burn(uint indexed tokenId_);

    event AddMint(uint256 indexed tokenId, uint256 _amount, bool forWhitelist, address owner);
    event MintSuccess(uint256 indexed tokenId, uint256 _amount, bool forWhitelist, address owner, bytes32 randTransactionHash);

    event AddMerge(uint256 indexed tokenIdA, uint256 indexed tokenIdB, address indexed owner, uint256 blockNumber);
    event MergeSuccess(uint256 indexed tokenIdA, uint256 indexed tokenIdB, address indexed owner, uint _currentRarity, uint _currentHero, bool success, bytes32 randTransactionHash);


    /**
     * @dev Contract address cannot be empty
     */
    error AddressIsNull();

    /**
     * @dev Array cannot be empty, length must be greater than 0
     */
    error ArrayIsNull();

    /**
     * @dev Incorrect array length
     */
    error ArrayLengthError();

    /**
     * @dev sale has already begun
     */
    error SaleHasAlreadyBegun();

    /**
     * @dev Price must be greater than 0
     */
    error PriceIsZero();

    /**
     * @dev wrong amount
     */
    error WrongAmount();

    /**
     * @dev Mint exceeds supply
     */
    error MintExceedsSupply();

    /**
     * @dev already claimed
     */
    error AlreadyClaimed();

    /**
     * @dev You must own the token to traverse
     */
    error NotTheOwner();

    /**
     * @dev NFT not allowed to claim
     */
    error NotAllowedClaim();


    /**
     * @dev Merge has already begun
     */
    error MergeHasAlreadyBegun();

    /**
     * @dev caller is not owner nor approved
     */
    error NotApprovedOrOwner();

    /**
     * @dev Two cards do not meet the merge rules
     */
    error NotMeetMergeRules();

    /**
     * @dev NFT already for merging
     */
    error AlreadyMerging();

    /**
     * @dev NFT merge object is error
     */
    error MergeInfoError();

    /**
     * @dev This chain is currently unavailable for travel
     */
    error ChainUnavailable();

    /**
     * @dev LZNFT: msg.value not enough to cover messageFee. Send gas for message fees
     */
    error NotEnoughMessageFee();
}