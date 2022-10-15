// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./HackedGameBase.sol";
import "./StakingTierProvider.sol";
import "./ReentryProvider.sol";
import "../utils/Recoverable.sol";


contract HackedGameV1 is HackedGameBase, StakingTierProvider, ReentryProvider, VRFConsumerBaseV2, Recoverable, Pausable {

    event GameComplete(uint256 indexed gameId, uint256 indexed tokenId, address indexed winner, uint256 prize);
    event GameStarted(uint256 indexed gameId);
    event RoundRequested(uint256 indexed gameId, uint256 indexed roundId, address indexed executor, uint256 tokenId);
    event RoundCompleted(uint256 indexed gameId, uint256 indexed roundId);

    struct VRFConfig {
        bytes32 keyHash;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint64 subscriptionId;
    }

    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    VRFConfig private vrfConfig;

    address immutable public hacked;
    address immutable public hackedStaked;
    address immutable public stakingContract;
    uint256 public feeReenterStaked = 0.005 ether;
    uint256 public feeReenterStakedTier4 = 0.01 ether;
    uint256 public feeReenter = 0.01 ether;
    uint256 public feeReenterTier4 = 0.015 ether;
    uint256 public feePercent = 10;
    address public feeWallet = 0x86EC34C96D006e99433909dAc627B747BED372e5;
    uint256 public roundDuration = 24 hours;

    mapping(uint256 => uint256) public requestIds;
    mapping(uint256 => mapping(uint256 => uint256)) public roundRequests;
    mapping(address => bool) public authorized;


    modifier onlyAuthorized() {
        require(msg.sender == owner() || authorized[msg.sender], "Not authorized");
        _;
    }

    modifier isInitialized() {
        ( ,uint256 defaultSymbols,,) = _decodeTokenState(LAST_TOKEN_ID);
        require(defaultSymbols != 0, "Not initialized");
        _;
    }

    constructor(
        address _hacked, 
        address _hackedStaked, 
        address _stakingContract,
        address _vrfCoordinator,
        uint64 _vrfSubscriptionId,
        bytes32 _vrfKeyHash,
        uint32 _vrfCallbackGasLimit,
        uint16 _vrfRequestConfirmations
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        hacked = _hacked;
        hackedStaked = _hackedStaked;
        stakingContract = _stakingContract;

        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfConfig = VRFConfig({
            subscriptionId: _vrfSubscriptionId,
            keyHash: _vrfKeyHash,
            callbackGasLimit: _vrfCallbackGasLimit,
            requestConfirmations: _vrfRequestConfirmations
        });
    }

    // solhint-disable no-empty-blocks
    receive() external payable {} 

    function initializeState(uint256 tokenId, uint256 length) external onlyOwner {
        uint256 limit = tokenId + length;
        if (limit > LAST_TOKEN_ID + 1) {
            limit = LAST_TOKEN_ID + 1;
        }

        uint256 lastSymbol = 0;
        if (tokenId != 1) {
            ( ,uint256 _defaultSymbols,,) = _decodeTokenState(tokenId-1);
            require(_defaultSymbols != 0, "Previous state not set");
            lastSymbol = _defaultSymbols;
        } 
        ( ,uint256 defaultSymbols,,) = _decodeTokenState(tokenId);
        require(defaultSymbols == 0, "State already set");

        for (; tokenId < limit; ++tokenId) {
            lastSymbol = _nextRandom(lastSymbol);
            _encodeTokenState(tokenId, 0, lastSymbol, 0, 0);
            _encodeSymbolState(lastSymbol, type(uint16).max, tokenId);
        }
    }

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

    function setFees(uint256 _feeReenterStaked, uint256 _feeReenterStakedTier4, uint256 _feeReenter, uint256 _feeReenterTier4) external onlyOwner {
        feeReenterStaked = _feeReenterStaked;
        feeReenterStakedTier4 = _feeReenterStakedTier4;
        feeReenter = _feeReenter;
        feeReenterTier4 = _feeReenterTier4;
    }

    function setRoundDuration(uint256 duration) external onlyOwner {
        roundDuration = duration;
    }

    function setFeeReceiver(uint256 _feePercent, address _feeWallet) external onlyOwner {
        require(_feePercent <= 100, "Invalid fees");
        feePercent = _feePercent;
        feeWallet = _feeWallet;
    }

    function pause() external whenNotPaused onlyAuthorized {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function authorize(address user) external onlyOwner {
        authorized[user] = true;
    }

    function revokeAuthorization(address user) external onlyOwner {
        authorized[user] = false;
    }

    function upgradeTierProvider(address provider) external onlyOwner {
        _upgradeTierProvider(provider);
    }

    function upgrateReentriesProvider(address provider) external onlyOwner {
        _upgradeReentriesProvider(provider);
    }
    
    function upgrateExtension(address extension) external onlyOwner {
        _setExtension(extension);
    }


    function startGame(uint256 startAt) external onlyAuthorized isInitialized {
        (
            uint256 gameId, uint256 roundId,,,,,,
        ) = _decodeGameState();

        require(gameId == 0 || roundId == BITS+1, "Game not complete");
        _initializeGame(startAt);

        emit GameStarted(gameId+1);
    }

    function drawRound(uint256 tokenId) external whenNotPaused {
        (uint256 gameId,uint256 roundId,,,,,,uint256 roundStartedAt) = _decodeGameState();
        require(gameId != 0, "No game yet");
        require(tokenId == 0 || _ownerOfToken(tokenId) == msg.sender, "Not owner of token");
        require(block.timestamp > roundStartedAt + (roundId == 0 ? 0 : roundDuration), "Round no finished");
        emit RoundRequested(gameId, roundId, msg.sender, tokenId);
        _requestRandomness(gameId, roundId);

        _onRoundRequested(tokenId, msg.sender);
    }

    function reenter(uint256[] calldata tokenIds) external payable whenNotPaused {
        (
            uint256 gameId,
            uint256 roundId,
            uint256 pattern,
            uint256 patternMask,
            uint256 lastPattern,
            uint256 lastPatternMask,
            uint256 lastSymbols,
            uint256 roundStartedAt
        ) = _decodeGameState();
        require(gameId != 0, "No game yet");

        uint256 tokenId;
        (uint256 tier, uint256 reentriesMax) = _getTierAndReentries(msg.sender);
        uint256 fees;

        require(tokenIds.length > 0, "Invalid length");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            tokenId = tokenIds[i];
            fees += _getFees(msg.sender, tokenId, tier);
            lastSymbols = _reenter(tokenId, reentriesMax, gameId, pattern, patternMask, lastPatternMask, lastSymbols);
        }
        require(fees == msg.value, "Invalid fees");

        _encodeGameState(gameId, roundId, pattern, patternMask, lastPattern, lastPatternMask, lastSymbols, roundStartedAt);
    }

    function completeGame() external whenNotPaused {
        (uint256 tokenId, uint256 matches) = _getMatchingTokenTokenIds();
        require(matches == 1, "No winner yet");

        (
            uint256 gameId,
            ,
            uint256 pattern,
            uint256 patternMask,
            uint256 lastPattern,
            uint256 lastPatternMask,
            uint256 lastSymbols,
            uint256 roundStartedAt
        ) = _decodeGameState();
        require(gameId != 0, "No game yet");

        _encodeGameState(gameId, BITS+1, pattern, patternMask, lastPattern, lastPatternMask, lastSymbols, roundStartedAt);

        address winner = _ownerOfToken(tokenId);
        uint256 prize = address(this).balance;
        uint256 fee = prize * feePercent / 100;

        payable(feeWallet).transfer(fee);
        payable(winner).transfer(prize - fee);

        _onGameCompleted(tokenId);

        emit GameComplete(gameId, tokenId, winner, prize-fee);
    }

    // In case of some erronous state, let admin complete the current game.
    function forceCompleteGame() external onlyOwner {
        (
            uint256 gameId,
            ,
            uint256 pattern,
            uint256 patternMask,
            uint256 lastPattern,
            uint256 lastPatternMask,
            uint256 lastSymbols,
            uint256 roundStartedAt
        ) = _decodeGameState();
        require(gameId != 0, "No game yet");

        _encodeGameState(gameId, BITS+1, pattern, patternMask, lastPattern, lastPatternMask, lastSymbols, roundStartedAt);

        _onGameCompleted(0);

        emit GameComplete(gameId, 0, address(0), 0);
    }

    function matchingTokensLeft() external view returns (uint256) {
        (,uint256 matches) = _getMatchingTokenTokenIds();
        return matches;
    }

    function allMatchingTokensLeft() external view returns (uint256[] memory, uint256) {
        return _getAllMatchingTokenTokenIds();
    }

    function nextRoundAt() external view returns (uint256) {
        (,uint256 roundId,,,,,,uint256 roundStartedAt) = _decodeGameState();
        return (roundStartedAt + (roundId == 0 ? 0 : roundDuration));
    }

    function canRequestDraw() external view returns (bool) {
        (uint256 gameId, uint256 roundId,,,,,,uint256 roundStartedAt) = _decodeGameState();
        return block.timestamp > (roundStartedAt + (roundId == 0 ? 0 : roundDuration))
            && roundRequests[gameId][roundId] == 0;
    }

    function drawRequested() external view returns (bool) {
        (uint256 gameId, uint256 roundId,,,,,,) = _decodeGameState();
        return roundRequests[gameId][roundId] != 0;
    }

    function canReenter(address owner, uint256[] calldata tokenIds) external view returns (bool[] memory possible, string[] memory reason, uint256[] memory fees) {
        (
            uint256 gameId,
            ,
            uint256 pattern,
            uint256 patternMask,
            ,
            uint256 lastPatternMask,
            uint256 symbols,
        ) = _decodeGameState();

        uint256 tokenId;
        (uint256 tier, uint256 reentriesMax) = _getTierAndReentries(owner);

        possible = new bool[](tokenIds.length);
        reason = new string[](tokenIds.length);
        fees = new uint256[](tokenIds.length);

        require(tokenIds.length > 0, "Invalid length");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            tokenId = tokenIds[i];
            fees[i] += _getFees(owner, tokenId, tier);
            (bool _canEnter, uint256 _nextSymbols, string memory _reason) = _canReenter(tokenId, reentriesMax, gameId, pattern, patternMask, lastPatternMask, symbols);
            if (_canEnter) {
                symbols = _nextSymbols;
            }
            possible[i] = _canEnter;
            reason[i] = _reason;
        }
    }

    function fulfillRandomWordsFallback(uint256 requestId, uint256[] memory randomWords)
        external
        onlyOwner
    {
        require(randomWords.length == 1, "Invalid length");
        _drawRound(requestId, randomWords[0]);
    }

    function _requestRandomness(uint256 gameId, uint256 roundId) internal {
        require(roundRequests[gameId][roundId] == 0, "Already requested");
        VRFConfig memory vrf = vrfConfig;
        uint256 vrfRequestId = vrfCoordinator.requestRandomWords(
            vrf.keyHash,
            vrf.subscriptionId,
            vrf.requestConfirmations,
            vrf.callbackGasLimit,
            1
        );
        roundRequests[gameId][roundId] = vrfRequestId;
        requestIds[vrfRequestId] = roundId;
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
        require(randomWords.length == 1, "Invalid length");
        _drawRound(requestId, randomWords[0]);
    }

    function _drawRound(uint256 requestId, uint256 random) internal {
        (uint256 gameId, uint256 roundId,,,,,,uint256 roundStartedAt) = _decodeGameState();
        uint256 _roundId = requestIds[requestId];
        require(_roundId == roundId, "round missmatch");
        requestIds[requestId] = 0;
        _round(random, roundStartedAt+roundDuration);
        emit RoundCompleted(gameId, roundId);
    }

    function _ownerOfToken(uint256 tokenId) internal view returns (address) {
        address owner = IERC721(hacked).ownerOf(tokenId);
        return owner == stakingContract ? IERC721(hackedStaked).ownerOf(tokenId) : owner;
    }

    function _getFees(address user, uint256 tokenId, uint256 tier) internal view returns (uint256) {
        address owner = IERC721(hacked).ownerOf(tokenId);
        if (user == owner) {
            return tier == 4 ? feeReenterTier4 : feeReenter;
        } else if (owner == stakingContract && IERC721(hackedStaked).ownerOf(tokenId) == user) {
            return tier == 4 ? feeReenterStakedTier4 : feeReenterStaked;
        }
        revert("Not owner of token");
    }

    function _getTierAndReentries(address owner) internal view returns (uint256 tier, uint256 reentriesMax) {
        tier = getTier(owner);
        reentriesMax = getReentries(owner, tier);
    }
}