// SPDX-License-Identifier: MIT

/// @title Monthly Art Giveaway
/// @notice contract to select 3 pass ids that win art for that month - specifies which piece of art the winners get
/// @dev contract can be reused monthly
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import "VRFConsumerBaseV2.sol";
import "VRFCoordinatorV2Interface.sol";
import "Ownable.sol";
import "IERC721.sol";

contract MonthlyArtGiveaway is VRFConsumerBaseV2, Ownable {

    struct ArtPiece {
        address contractAddress;
        uint256 tokenId;
    }

    // state variables
    bytes32 private _keyHash;
    uint64 private _subscriptionId;
    uint16 private _requestConfirmations;
    uint32 private _callbackGasLimit;
    uint32 private _numWords;
    uint256[] private _randomWords;

    VRFCoordinatorV2Interface public coordinator;
    
    bool public artSet;
    ArtPiece[3] private _art;

    uint256[] private _entries;

    uint256 private _numTokens;
    IERC721 public rarePassContract;
    
    // events
    event RandomnessFulfilled(uint256 indexed requestId);
    event Winner(address indexed winner, address indexed contractAddress, uint256 indexed tokenId, uint256 winnerRarePassId);

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
        _numTokens = 239; // 250 minus the 11 partner passes that may not be given out by the first raffle - can be updated by owner after passes are given out
        rarePassContract = IERC721(rarePassAddress);
    }

    /// @notice function to set number of RARE Pass tokens to include in the raffle
    /// @dev requires contract owner
    /// @dev needed as the partner passes may be given out slowly and don't want to include them in the monthly art raffles
    function setNumTokens(uint256 newNumTokens) external onlyOwner {
        _numTokens = newNumTokens;
    }

    /// @notice function to set the art
    /// @dev requires contract owner
    function setArt(address[3] calldata contractAddresses, uint256[3] calldata tokenIds) external onlyOwner {
        // reset dynamic array to be from 1 to _numTokens
        uint256[] memory tempEntries = new uint256[](_numTokens);
        for (uint256 id = 1; id < _numTokens + 1; id++) {
            tempEntries[id-1] = id;
        }
        _entries = tempEntries;
        
        // set art
        for (uint256 i = 0; i < 3; i++) {
            ArtPiece memory art = ArtPiece(contractAddresses[i], tokenIds[i]);
            _art[i] = art;
        }

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

    /// @notice function to select winners
    /// @dev requires contract owner
    /// @dev should only be called after randomness is fulfilled
    /// @dev requires art to be set and that the number of random words is at least three
    function selectWinners() external onlyOwner {
        require(artSet, "art has not been set");
        require(_randomWords.length >= 3, "at least three random words are needed");
        
        for (uint256 i = 0; i < 3; i++) {
            uint256 winningIndex = _getRandomIndex(_randomWords[i], _entries.length);
            uint256 winningRarePassId = _entries[winningIndex];
            address winner = rarePassContract.ownerOf(winningRarePassId);

            _entries[winningIndex] = _entries[_entries.length - 1];
            _entries.pop();

            emit Winner(winner, _art[i].contractAddress, _art[i].tokenId, winningRarePassId);
        }

        delete _randomWords;
        artSet = false;
    }

    /// @notice function override for fulfilling random words
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _randomWords = randomWords;

        emit RandomnessFulfilled(requestId);
    }

    /// @notice function to get random array index from random word supplied from VRF
    /// @dev modulo bias is insignificant for maxIndex less than 100 billion
    function _getRandomIndex(uint256 randomWord, uint256 maxIndex) internal pure returns(uint256) {
        return randomWord % maxIndex;
    }
}