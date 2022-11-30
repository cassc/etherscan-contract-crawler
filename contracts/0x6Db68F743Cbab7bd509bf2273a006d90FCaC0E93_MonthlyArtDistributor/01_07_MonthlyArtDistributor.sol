// SPDX-License-Identifier: MIT

/// @title Monthly Art Distributor
/// @notice contract to airdrop art to pass holders in a randomized way
/// @dev contract can be reused monthly
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import "VRFConsumerBaseV2.sol";
import "VRFCoordinatorV2Interface.sol";
import "Ownable.sol";
import "IERC721.sol";

contract MonthlyArtDistributor is VRFConsumerBaseV2, Ownable {

    // state variables
    bytes32 private _keyHash;
    uint64 private _subscriptionId;
    uint16 private _requestConfirmations;
    uint32 private _callbackGasLimit;
    uint32 private _numWords;
    uint256[] private _randomWords;

    VRFCoordinatorV2Interface public coordinator;

    bool public artSet;
    address public artist;
    IERC721 public nftContract;
    uint256 public startToken;

    IERC721 public rarePassContract;
    
    // events
    event RandomnessFulfilled(uint256 indexed requestId);

    constructor(
        bytes32 keyHash,
        uint64 subscriptionId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address vrfCoordinator,
        address rarePassAddress
    )
    VRFConsumerBaseV2(vrfCoordinator)
    Ownable()
    {
        _keyHash = keyHash;
        _subscriptionId = subscriptionId;
        _requestConfirmations = requestConfirmations;
        _callbackGasLimit = callbackGasLimit;
        _numWords = numWords;
        coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        rarePassContract = IERC721(rarePassAddress);
    }

    /// @notice function to set the art
    /// @dev requires contract owner
    function setArt(address artistAddress, address contractAddress, uint256 startTokenId) external onlyOwner {
        artist = artistAddress;
        nftContract = IERC721(contractAddress);
        startToken = startTokenId;
        artSet = true;
    }

    /// @notice function to set keyHash
    /// @dev requires contract owner
    function setKeyHash(bytes32 newKeyHash) external onlyOwner {
        _keyHash = newKeyHash;
    }

    /// @notice function to set subscriptionId
    /// @dev requires contract owner
    function setSubscriptionId(uint64 newSubscriptionId) external onlyOwner {
        _subscriptionId = newSubscriptionId;
    }

    /// @notice function to set requestConfirmations
    /// @dev requires contract owner
    function setRequestConfirmations(uint16 newRequestConfirmations) external onlyOwner {
        _requestConfirmations = newRequestConfirmations;
    }

    /// @notice function to set callbackGasLimit
    /// @dev requires contract owner
    function setCallbackGasLimit(uint32 newCallbackGasLimit) external onlyOwner {
        _callbackGasLimit = newCallbackGasLimit;
    }

    /// @notice function to set numWords
    /// @dev requires contract owner
    function setNumWords(uint32 newNumWords) external onlyOwner {
        _numWords = newNumWords;
    }

    /// @notice function to request randomness from the coordinator
    /// @dev requires contract owner
    /// @dev should not be called multiple times unless something goes wrong
    /// @dev requires art to be set
    function requestRandomness() external onlyOwner {
        require(artSet, "art has not been set");
        coordinator.requestRandomWords(
            _keyHash,
            _subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            _numWords
        );
    }

    /// @notice function to distribute art based on random starting index from VRF randomness
    /// @dev requires contract owner
    /// @dev should only be called after randomness is fulfilled
    /// @dev chooses a random RARE Pass token id to get the second token in the series of 250
    /// @dev rare pass #1 always gets the first work in the art series
    /// @dev requires art to be set and at least one random word
    function distribute() external onlyOwner {
        require(artSet, "art has not been set");
        require(_randomWords.length >= 1, "at least one random word is needed");
        
        address passHolderOne = rarePassContract.ownerOf(1);
        nftContract.transferFrom(artist, passHolderOne, startToken);

        uint256 rarePassTokenId = _getRandomToken(_randomWords[0], 249);
        for (uint256 i = 1; i < 250; i++) {
            uint256 nftTokenId = startToken + i;
            if (rarePassTokenId > 250) {
                rarePassTokenId = 2; // rollover at token id 250 to token 2 since token 1 always gets the first piece of art in the series
            }
            address passHolder = rarePassContract.ownerOf(rarePassTokenId);
            nftContract.transferFrom(artist, passHolder, nftTokenId);
            rarePassTokenId++;
        }

        delete _randomWords;
        artSet = false;
    }

    /// @notice function override for fulfilling random words
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _randomWords = randomWords;

        emit RandomnessFulfilled(requestId);
    }

    /// @notice function to get random token id from random word supplied from VRF
    /// @dev between 2 and maxNum + 1
    /// @dev modulo bias is insignificant for maxNum less than 100 billion
    function _getRandomToken(uint256 randomWord, uint256 maxNum) internal pure returns(uint256) {
        return randomWord % maxNum + 2;
    }
}