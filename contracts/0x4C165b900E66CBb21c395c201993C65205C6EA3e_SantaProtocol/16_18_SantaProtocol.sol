// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./utils/RandomNumberConsumerV2.sol";
import "./WrappedPresent.sol";

/**
 * @title The SantaProtocol contract
 * @notice A contract that lets people deposit an NFT into a pool and then later lets them randomly redeem another one using Chainlink VRF2
 */
contract SantaProtocol is Ownable, IERC721Receiver, RandomNumberConsumerV2 {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    // Struct to store gifts in the pool
    struct Gift {
        address gifter;
        address nft;
        uint256 tokenId;
    }

    // Address that signs verification messages when adding gifts
    address s_signer;
    // Blocktime that adding gifts to the pool ends
    uint256 public s_registrationEnd;
    // Blocktime that redemptions start
    uint256 public s_redemptionStart;
    // State that pauses the contract's functionality
    bool public PAUSED = false;
    // The random word returned by VRF used as a seed for the randomness
    uint256 public SEED;
    // The request ID for the SEED
    uint256 public SEED_REQUEST_ID;
    // The state that says that the gift pool has been shuffled
    bool public SHUFFLED = false;
    // Maximum allowed gifts in the pool
    uint32 public MAX_GIFTS = 50000;

    // The Gift Pool
    Gift[] public s_giftPool;
    // The array to map Present Token IDs to gifts in the Gift Pool
    uint32[] public s_giftPoolIndices;
    // The Present NFT that's minted to users when they add to the pool
    WrappedPresent PRESENT_NFT;

    // Mapping of gifts chosen by each user
    mapping(address => Gift[]) s_chosenGifts;

    // Revert reasons
    error GiftMustSupportERC721Interface();
    error InvalidSenderMustNotBeContract();
    error RedemptionHasNotStarted();
    error PoolSizeExceedsAmount();
    error MustApproveContract();
    error HasNotBeenShuffled();
    error DoesNotOwnPresent();
    error RegistrationEnded();
    error CannotGiftPresent();
    error InvalidSignature();
    error MaxGiftsReached();
    error MustOwnTokenId();
    error AllGiftsGiven();

    // Events
    event NewSigner(address newSigner);
    event NewOwner(address newOwner);
    event AddGift(address gifter, address nft, uint256 tokenId);
    event GiftUnwrapped(address receiver, address nft, uint256 tokenId);
    event ERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );
    event GiftAdded(address gifter, address nft, uint256 tokenId);
    event GiftChosen(
        address account,
        uint256 presentTokenId,
        address nft,
        uint256 tokenId
    );

    /**
     * @notice Constructor inherits RandomNumberConsumerV2
     *
     * @param subscriptionId - the subscription ID that this contract uses for funding Chainlink VFR requests
     * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
     * @param keyHash - the Chainlink gas lane to use, which specifies the maximum gas price to bump to
     * @param registrationEnd - the time that registration/adding gifts ends
     * @param redemptionStart - the time that participants can begin redeeming their gifts
     */
    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 registrationEnd,
        uint256 redemptionStart,
        address signer,
        address presentNft
    ) RandomNumberConsumerV2(subscriptionId, vrfCoordinator, keyHash) {
        s_registrationEnd = registrationEnd;
        s_redemptionStart = redemptionStart;
        s_signer = signer;
        PRESENT_NFT = WrappedPresent(presentNft);
    }

    /*
     * Functions used to interact with the gift exchange
     */

    /**
     * @notice Function used to add an NFT to the pool.
     *
     * @param nft - the address of the NFT being added
     * @param tokenId - the token id of the NFT being added
     * @param sig - a message signed by the signer address verifying the NFT is eligible
     */
    function addGift(
        address nft,
        uint256 tokenId,
        bytes memory sig
    ) public isNotPaused {
        // If the registration/adding gift end time has passed
        if (block.timestamp > s_registrationEnd) revert RegistrationEnded();
        // If the pool size has already reached its limit
        if (s_giftPool.length >= MAX_GIFTS) revert MaxGiftsReached();
        // If the gift is already a present, ya do-do!
        if (nft == address(PRESENT_NFT)) revert CannotGiftPresent();
        // If the gift doesn't support the ERC721 interface
        if (!giftSupports721(nft)) revert GiftMustSupportERC721Interface();
        // IF the user doesn't own the nft they're adding
        if (IERC721(nft).ownerOf(tokenId) != msg.sender)
            revert MustOwnTokenId();
        // If the user hasn't individually approved this contract
        if (IERC721(nft).getApproved(tokenId) != address(this))
            revert MustApproveContract();
        // If the signature isn't valid
        if (!validateGiftHashSignature(msg.sender, nft, tokenId, sig))
            revert InvalidSignature();

        // Transfer the NFT from the caller to this contract
        IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId);

        // Mint a present NFT to the caller
        PRESENT_NFT.simpleMint(msg.sender);

        // Add the gift to the pool
        s_giftPool.push(Gift(msg.sender, nft, tokenId));
        s_giftPoolIndices.push(uint32(s_giftPool.length - 1));

        emit GiftAdded(msg.sender, nft, tokenId);
    }

    /**
     * @notice Function used to burn a Present NFT and redeem the gift in the pool it's been tied to
     */
    function openGift(uint256 tokenId) public isNotPaused {
        // If redemptions haven't started yet
        if (block.timestamp < s_redemptionStart)
            revert RedemptionHasNotStarted();
        // If the pool has not been shuffled
        if (!SHUFFLED) revert HasNotBeenShuffled();
        // If there are no gifts left in the pool
        if (s_giftPool.length == 0) revert AllGiftsGiven();
        // Make sure the caller owns the tokenId
        if (PRESENT_NFT.ownerOf(tokenId) != msg.sender)
            revert DoesNotOwnPresent();

        // Select the randomized gift associated with the tokenId
        uint32 index = s_giftPoolIndices[tokenId - 1];
        Gift memory chosenGift = s_giftPool[index];

        // Trade the present for a random number
        PRESENT_NFT.burn(tokenId, msg.sender);
        IERC721(chosenGift.nft).safeTransferFrom(
            address(this),
            msg.sender,
            chosenGift.tokenId
        );

        emit GiftChosen(
            msg.sender,
            tokenId,
            chosenGift.nft,
            chosenGift.tokenId
        );
    }

    /**
     * @notice Get the number of NFTs in the gift pool
     */
    function getGiftPoolSize() public view returns (uint256) {
        return s_giftPool.length;
    }

    /**
     * @notice Get the whole gift pool
     *
     * @dev intended for offchain use only
     */
    function getGiftPool() public view returns (Gift[] memory) {
        return s_giftPool;
    }

    /**
     * @notice Get the indices mapping presents to gifts
     *
     * @dev intended for offchain use only
     */
    function getGiftPoolIndices() public view returns (uint32[] memory) {
        return s_giftPoolIndices;
    }

    /**
     * @notice Get the number of gifts that a user has randomly chosen
     * @param account - the wallet address of the user
     */
    function getNumberOfChosenGifts(
        address account
    ) public view returns (uint256) {
        return s_chosenGifts[account].length;
    }

    /**
     * @notice Get the array of gifts that a user has randomly chosen
     * @param account - the wallet address of the user
     *
     * @dev intended for offchain use only
     */
    function getChosenGifts(
        address account
    ) public view returns (Gift[] memory gifts) {
        return s_chosenGifts[account];
    }

    /*
     * Admin Functions
     */

    /**
     * @notice Set signer to new account
     *
     * @param newSigner - the addres of the new owner
     */
    function setSigner(address newSigner) public onlyOwner {
        s_signer = newSigner;
    }

    /**
     * @notice Set the time that adding gifts ends
     *
     * @param newRegistrationEnd - the new s_registerationEnd time
     */
    function setRegistrationEnd(uint256 newRegistrationEnd) public onlyOwner {
        s_registrationEnd = newRegistrationEnd;
    }

    /**
     * @notice Set the time that claiming a random gift starts
     *
     * @param newRedemptionStart - the new s_redemptionStart time
     */
    function setRedemptionStart(uint256 newRedemptionStart) public onlyOwner {
        s_redemptionStart = newRedemptionStart;
    }

    /**
     * @notice Function used to update the subscription ID
     *
     * @param subscriptionId - the chainlink vrf subscription id
     */
    function setSubscriptionId(uint64 subscriptionId) public onlyOwner {
        s_subscriptionId = subscriptionId;
    }

    /**
     * @notice Function used to update the gas lane used by VRF
     *
     * @param keyHash - the keyhash of the gaslane that VRF uses
     */
    function setKeyHash(bytes32 keyHash) public onlyOwner {
        s_keyHash = keyHash;
    }

    /**
     * @notice Function used to update the callback gas limit
     *
     * @param callbackGasLimit - the gas limit of the fulfillRandomWords callback
     */
    function setCallbackGasLimit(uint32 callbackGasLimit) public onlyOwner {
        CALLBACK_GAS_LIMIT = callbackGasLimit;
    }

    /**
     * @notice Function that pauses the contract
     *
     * @param _isPaused - now what're we turning the pause to!?
     */
    function setPaused(bool _isPaused) public onlyOwner {
        PAUSED = _isPaused;
    }

    /**
     * @notice Function that allows the owner to update the max size of the pool
     *
     * @param _maxGifts - new max number of gifts in the pool
     */
    function setMaxGifts(uint32 _maxGifts) public onlyOwner {
        if (s_giftPool.length > _maxGifts) revert PoolSizeExceedsAmount();
        MAX_GIFTS = _maxGifts;
    }

    /**
     * @notice Function that requests a random seed from VRF
     */
    function requestSeed() public onlyOwner {
        require(
            block.timestamp > s_registrationEnd,
            "Registration has not ended yet"
        );
        SEED_REQUEST_ID = requestRandomWords(1);
        SHUFFLED = false;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @param requestId - id of the request
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        if (SEED_REQUEST_ID == requestId) {
            SEED = randomWords[0];
        }
    }

    /**
     * @notice Function that uses the SEED to shuffle the index array.
     * Just in case this ends up being a large array (Ho Ho Ho!), we will make it possible
     * to break this operation up into multiple calls
     *
     * @param startPosition - the starting index we're shuffling
     * @param endPosition - the ending index we're shuffling
     */
    function shuffleRandomGiftIndices(
        uint32 startPosition,
        uint32 endPosition
    ) public onlyOwner {
        require(SEED != 0, "SEED does not exist");
        require(
            endPosition >= startPosition,
            "End position must be after start position"
        );

        // Make sure that we're not going to go out of bounds
        uint32 lastPosition = endPosition > s_giftPool.length - 1
            ? uint32(s_giftPool.length - 1)
            : endPosition;

        // Shuffle the indices in the array
        for (uint32 i = startPosition; i <= lastPosition; ) {
            uint32 j = uint32(
                (uint256(keccak256(abi.encode(SEED, i))) % (s_giftPool.length))
            );
            (s_giftPoolIndices[i], s_giftPoolIndices[j]) = (
                s_giftPoolIndices[j],
                s_giftPoolIndices[i]
            );
            unchecked {
                i++;
            }
        }

        // Once we've shuffled the entire array, set the state to shuffled
        if (lastPosition == s_giftPool.length - 1) {
            SHUFFLED = true;
        }
    }

    /*
     * Functions used for signing gifts as they get added
     */

    /**
     * @notice returns an identifying contract hash to verify this contract
     */
    function getContractHash() public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this)));
    }

    /**
     * @notice Function used to hash a gift
     *
     * @param gifter - address of the gifter
     * @param nft - the address of the NFT being gifted
     * @param tokenId - the id of the NFT being gifted
     */
    function hashGift(
        address gifter,
        address nft,
        uint256 tokenId
    ) public view returns (bytes32) {
        bytes32 giftHash = keccak256(abi.encode(Gift(gifter, nft, tokenId)));
        return keccak256(abi.encode(getContractHash(), giftHash));
    }

    /**
     * @notice Function that valifates that the gift hash signature was signed by the designated signer authority
     *
     * @param gifter - address of the gifter
     * @param nft - the address of the NFT being gifted
     * @param tokenId - the id of the NFT being gifted
     * @param sig - the signature of the gift hash
     */
    function validateGiftHashSignature(
        address gifter,
        address nft,
        uint256 tokenId,
        bytes memory sig
    ) public view returns (bool) {
        bytes32 giftHash = hashGift(gifter, nft, tokenId);
        bytes32 ethSignedMessageHash = giftHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(sig);
        return signer == s_signer;
    }

    /*
     * Misc
     */

    /**
     * @notice OpenZeppelin requires ERC721Received implementation.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        emit ERC721Received(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

    /**
     * @notice Function used to determine if a caller is a contract
     *
     * @param account - the address of an account
     *
     * @dev note, this isn't foolproof so use with caution
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice Function used to determine if a contract supports 721 interface
     *
     * @param nft - the address of an NFT
     */
    function giftSupports721(address nft) public view returns (bool) {
        try IERC165(nft).supportsInterface(type(IERC721).interfaceId) returns (
            bool result
        ) {
            return result;
        } catch {
            return false;
        }
    }

    /*
     * Modifiers
     */

    modifier isNotPaused() {
        require(!PAUSED, "The NFT Exchange is currently paused.");
        _;
    }
}