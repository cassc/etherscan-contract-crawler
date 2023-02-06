// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./libs/UniformRandomNumber.sol";
import "./utils/Recoverable.sol";
import "./interfaces/IERC721Listener.sol";

/**
 * @title MintingRaffle to allow raffling prize NFTs to minters of mintable collection 
 * every N mints automatically using Chainlink VRFv2.
 */
contract MintingRaffle is VRFConsumerBaseV2, Recoverable, IERC721Listener, Pausable {
    
    event RaffleCompleted(uint16 startTokenId, uint16 winnerTokenId, uint16 prizeTokenId, address winner);

    struct VRFConfig {
        bytes32 keyHash;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint64 subscriptionId;
    }

    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    VRFConfig private vrfConfig;

    IERC721Enumerable public immutable mintable;
    IERC721Enumerable public immutable prize;
    uint256 public immutable drawEveryNMints;
    address public immutable prizeVault;

    mapping(uint256 => uint256) public vrfRequestStartTokenId;
    uint256 public nextDrawAtTokenId;

    constructor(
        address _vrfCoordinator,
        uint64 _vrfSubscriptionId,
        bytes32 _vrfKeyHash,
        uint32 _vrfCallbackGasLimit,
        uint16 _vrfRequestConfirmations,
        address _mintable,
        address _prize,
        address _prizeVault,
        uint256 _drawEveryNMints
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        require(_mintable != address(0), "Invalid mintable");

        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfConfig = VRFConfig({
            subscriptionId: _vrfSubscriptionId,
            keyHash: _vrfKeyHash,
            callbackGasLimit: _vrfCallbackGasLimit,
            requestConfirmations: _vrfRequestConfirmations
        });


        mintable = IERC721Enumerable(_mintable);
        prize = IERC721Enumerable(_prize);

        drawEveryNMints = _drawEveryNMints;
        nextDrawAtTokenId = _drawEveryNMints;
        prizeVault = _prizeVault;
    }

    /**
     * @notice Change Chainlink VRF V2 configuration
     */
    function configureVRF(
        uint64 _vrfSubscriptionId,
        bytes32 _vrfKeyHash,
        uint16 _vrfRequestConfirmations,
        uint32 _vrfCallbackGasLimit
    ) external onlyOwner {
        VRFConfig storage vrf = vrfConfig;
        vrf.subscriptionId = _vrfSubscriptionId;
        vrf.keyHash = _vrfKeyHash;
        vrf.requestConfirmations = _vrfRequestConfirmations;
        vrf.callbackGasLimit = _vrfCallbackGasLimit;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused() {
        _unpause();
    }

    /**
     * @dev Fallback method in case VRF is stuck
     */
    function fulfillRandomWordsFallback(uint256 requestId)
        external
        onlyOwner
    {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = uint256(keccak256(abi.encode(requestId, block.difficulty, block.gaslimit, block.number, msg.sender)));
        _rafflePrize(requestId, randomWords);
    }

    /**
     * @dev Requests a new random number from the Chainlink VRF
     * @dev The result of the request is returned in the function `fulfillRandomness`
     */ 
    function _requestRandomness(uint256 startTokenId) internal {
        VRFConfig memory vrf = vrfConfig;
        uint256 vrfRequestId = vrfCoordinator.requestRandomWords(
            vrf.keyHash,
            vrf.subscriptionId,
            vrf.requestConfirmations,
            vrf.callbackGasLimit,
            1
        );

        vrfRequestStartTokenId[vrfRequestId] = startTokenId;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     * @dev The VRF Coordinator will only send this function verified responses.
     * @dev The VRF Coordinator will not pass randomness that could not be verified.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        _rafflePrize(requestId, randomWords);
    }

    function _rafflePrize(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal whenNotPaused {
        uint256 startTokenId = vrfRequestStartTokenId[requestId];
        require(startTokenId != 0, "Already fulfilled");
        vrfRequestStartTokenId[requestId] = 0;

        uint256 winnerTokenId = startTokenId + UniformRandomNumber.uniform(
            randomWords[0],
            drawEveryNMints
        );
        address winner = mintable.ownerOf(winnerTokenId);

        uint256 prizeIndex = UniformRandomNumber.uniform(
            uint256(keccak256(abi.encode(randomWords[0], requestId))),
            prize.balanceOf(prizeVault)
        );
        uint256 prizeTokenId = prize.tokenOfOwnerByIndex(
            prizeVault,
            prizeIndex
        );

        prize.transferFrom(prizeVault, winner, prizeTokenId);
        emit RaffleCompleted(uint16(startTokenId), uint16(winnerTokenId), uint16(prizeTokenId), winner);
    }

    function checkRaffleConditions() public whenNotPaused() {
        if (mintable.totalSupply() >= nextDrawAtTokenId) {
            _requestRandomness(nextDrawAtTokenId - drawEveryNMints + 1);
            nextDrawAtTokenId += drawEveryNMints;
        }
    }

    function beforeTokenTransfer(address, address, uint256) external override {}

    function afterTokenTransfer(address from, address, uint256 tokenId) external override {
        if (from == address(0) && tokenId >= nextDrawAtTokenId && !paused()) { 
            checkRaffleConditions();
        }
    }
}