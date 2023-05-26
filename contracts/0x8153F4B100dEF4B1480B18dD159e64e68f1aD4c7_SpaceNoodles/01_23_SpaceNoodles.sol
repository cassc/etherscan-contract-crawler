// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./ERC2981.sol";

contract SpaceNoodles is ERC721Enumerable, IERC721Receiver, VRFConsumerBaseV2, ReentrancyGuard, AccessControl, Ownable, ERC2981 {
    IERC721                   public immutable NOODLES;
    VRFCoordinatorV2Interface public immutable COORDINATOR;
    LinkTokenInterface        public immutable LINKTOKEN;

    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
    bytes32 public constant RANK_WRITER_ROLE = keccak256("RANK_WRITER");

    uint64  public s_subscriptionId;
    bytes32 public s_keyHash;
    uint32  public s_callbackGasLimit = 2500000;
    uint16  public s_requestConfirmations = 3;

    function setSubscriptionId(uint64 _subscriptionId) external onlyRole(SUPPORT_ROLE) {
        s_subscriptionId = _subscriptionId;
    }

    function setKeyHash(bytes32 _keyHash) external onlyRole(SUPPORT_ROLE) {
        s_keyHash = _keyHash;
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyRole(SUPPORT_ROLE) {
        s_callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyRole(SUPPORT_ROLE) {
        s_requestConfirmations = _requestConfirmations;
    }

    constructor(
        address _noodles,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) ERC721("Space Noodles", "SNOODLE") VRFConsumerBaseV2(_vrfCoordinator) {
        NOODLES = IERC721(_noodles);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_link);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);

        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
    }

    string private baseURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyRole(SUPPORT_ROLE) {
        baseURI = _uri;
    }

    uint8[] public DICE_ROLL = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,7,7,8];
    uint256 public constant BITS_PER_TRAIT = 8;
    uint256 public constant NUM_TRAITS = 5;
    uint256 public constant VRF_WORD_SIZE = 256;
    uint256 public constant BITS_PER_SEED = BITS_PER_TRAIT * NUM_TRAITS;
    uint256 public constant SEEDS_PER_WORD = VRF_WORD_SIZE / BITS_PER_SEED;
    uint256 public constant SEED_MASK = (1 << BITS_PER_SEED) - 1;

    struct Stats {
        uint8 rank;

        uint8 calories;
        uint8 MSG;
        uint8 spice;
        uint8 noodity;
        uint8 slurp;
    }

    event ChangedStats(
        uint256 indexed _tokenId
    );

    event ProcessBatch(
        uint256 _requestId
    );

    mapping(uint256 => Stats)     public tokenStats;
    mapping(uint256 => uint256[]) public batches; // Each batch has an array of token IDs
    mapping(uint256 => uint256)   public vrfRequestIdToBatchId;
    uint256 public batchCount;
    uint256 public minBatchSize = 15;
    uint256 public maxBatchSize = 30;
    bool public launchingActive;
    bool public dockingActive;

    function setMinBatchSize(uint256 _minBatchSize) external onlyRole(SUPPORT_ROLE) {
        minBatchSize = _minBatchSize;
        if (minBatchSize > maxBatchSize) {
            maxBatchSize = minBatchSize;
        }
    }

    function setMaxBatchSize(uint256 _maxBatchSize) external onlyRole(SUPPORT_ROLE) {
        maxBatchSize = _maxBatchSize;
        if (minBatchSize > maxBatchSize) {
            minBatchSize = maxBatchSize;
        }
    }

    function setLaunchingActive(bool _launchingActive) external onlyRole(SUPPORT_ROLE) {
        launchingActive = _launchingActive;
    }

    function setDockingActive(bool _dockingActive) external onlyRole(SUPPORT_ROLE) {
        dockingActive = _dockingActive;
    }

    function _createSpaceShip(address to, uint256 tokenId) internal {
        batches[batchCount].push(tokenId);

        _safeMint(to, tokenId);
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes memory data) public virtual override nonReentrant returns (bytes4) {
        if (msg.sender == address(NOODLES)) {
            require(launchingActive, "Launching not active.");

            if (!_exists(tokenId)) {
                _createSpaceShip(from, tokenId);
                if ((data.length == 0 && batches[batchCount].length >= minBatchSize) ||
                    batches[batchCount].length >= maxBatchSize) {
                    _processBatch();
                }
            } else {
                _safeTransfer(address(this), from, tokenId, "");
            }
        } else if (msg.sender == address(this)) {
            require(dockingActive, "Docking not active.");
            NOODLES.safeTransferFrom(address(this), from, tokenId);
        } else {
            revert("Noodles and Space Noodles only.");
        }

        return this.onERC721Received.selector;
    }

    function launchMany(uint[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            NOODLES.safeTransferFrom(msg.sender, address(this), tokenIds[i], "skip"); // skip batch check in onERC721Received
        }

        if (batches[batchCount].length >= minBatchSize) {
            _processBatch();
        }
    }

    function dockMany(uint[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    function rescueNoodle(address to, uint256 tokenId) external onlyRole(SUPPORT_ROLE) {
        if (!_exists(tokenId) || ownerOf(tokenId) == address(this)) {
            // Noodle stuck in this contract
            NOODLES.safeTransferFrom(address(this), to, tokenId);
        } else if (ownerOf(tokenId) == address(NOODLES)) {
            // Space Noodle stuck in Noodles contract
            _safeTransfer(address(NOODLES), to, tokenId, "");
        } else {
            revert("Only allowed in rescue scenarios.");
        }
    }

    function _ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        return (a + m - 1) / m;
    }

    function _processBatch() internal returns (uint256) {
        uint32 numWords = uint32(_ceil(batches[batchCount].length, SEEDS_PER_WORD));
        uint256 requestId = COORDINATOR.requestRandomWords(s_keyHash,
                                                           s_subscriptionId,
                                                           s_requestConfirmations,
                                                           s_callbackGasLimit,
                                                           numWords);

        vrfRequestIdToBatchId[requestId] = batchCount;
        batchCount++;

        emit ProcessBatch(requestId);

        return requestId;
    }

    function flushBatch() external nonReentrant onlyRole(SUPPORT_ROLE) returns (uint256) {
        return _processBatch();
    }

    function retryBatch(uint256 batchId) public onlyRole(SUPPORT_ROLE) returns (uint256) {
        uint256 batchSize = batches[batchId].length;

        for (uint256 i; i < batchSize; i++) {
            require(tokenStats[batches[batchId][i]].rank == 0, "Stats have already been set.");
        }

        uint32 numWords = uint32(_ceil(batches[batchId].length, SEEDS_PER_WORD));
        uint256 requestId = COORDINATOR.requestRandomWords(s_keyHash,
                                                           s_subscriptionId,
                                                           s_requestConfirmations,
                                                           s_callbackGasLimit,
                                                           numWords);

        vrfRequestIdToBatchId[requestId] = batchId;
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 batchId = vrfRequestIdToBatchId[requestId];
        uint256 batchSize = batches[batchId].length;

        for (uint256 i; i < batchSize; i++) {
            uint256 j = i / SEEDS_PER_WORD;
            uint256 seed = randomWords[j] & SEED_MASK;
            uint256 tokenId = batches[batchId][i];
            tokenStats[tokenId] = _computeStats(seed);
            emit ChangedStats(tokenId);
            randomWords[j] >>= BITS_PER_SEED;
        }
    }

    function _computeStats(uint256 seed) internal view returns (Stats memory) {
        return Stats({
            rank: 1,
            calories: DICE_ROLL[uint8(seed)],
            MSG: DICE_ROLL[uint8(seed >> BITS_PER_TRAIT)],
            spice: DICE_ROLL[uint8(seed >> (BITS_PER_TRAIT * 2))],
            noodity: DICE_ROLL[uint8(seed >> (BITS_PER_TRAIT * 3))],
            slurp: DICE_ROLL[uint8(seed >> (BITS_PER_TRAIT * 4))]
        });
    }

    function setRank(uint256 tokenId, uint8 _rank) external onlyRole(RANK_WRITER_ROLE) {
        require(_exists(tokenId), "Token does not exist.");

        tokenStats[tokenId].rank = _rank;
        emit ChangedStats(tokenId);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable, ERC2981) returns (bool) {
        return AccessControl.supportsInterface(interfaceId)
            || ERC721Enumerable.supportsInterface(interfaceId)
            || ERC2981.supportsInterface(interfaceId);
    }

    // EIP-2981

    /**
     *  @dev Set the royalties information.
     *  @param recipient Recipient address of the royalties
     *  @param value     Percentage points (10000 = 100%, 250 = 2.5%, 0 = 0%)
     */
    function setRoyalties(address recipient, uint256 value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), "Zero address.");
        _setRoyalties(recipient, value);
    }
}