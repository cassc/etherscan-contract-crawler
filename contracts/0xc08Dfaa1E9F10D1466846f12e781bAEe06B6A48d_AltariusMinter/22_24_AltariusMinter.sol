// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./AltariusCards.sol";
import "./AltariusMinterStorage.sol";

contract AltariusMinter is VRFConsumerBaseV2, AccessControl, Pausable {
    struct RequestStatus {
        address sender;
        bool exists;
        bool fulfilled;
        bool minted;
        uint256 randomWord;
        uint256 edition;
    }

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    mapping(uint256 => RequestStatus) public vrfRequests; // requestId => requestStatus
    mapping(address => uint256) public pendingVrfRequestIds; // sender => requestId

    bytes32 public vrfKeyHash;
    uint64 public vrfSubscriptionId;
    uint32 public vrfCallbackGasLimit;
    uint16 public vrfRequestConfirmations;

    AltariusCards public altariusCards;
    AltariusMinterStorage public s;
    VRFCoordinatorV2Interface public vrfCoordinator;

    event RequestSent(address indexed sender, uint256 indexed requestId);
    event RequestFulfilled(
        address indexed sender,
        uint256 indexed requestId,
        uint256 randomWord
    );
    event PackMinted(address indexed minter, uint256 edition, uint256[] ids);

    constructor(
        AltariusCards _altariusCards,
        AltariusMinterStorage _altariusMinterStorage,
        address _vrfCoordinator,
        bytes32 _vrfKeyHash,
        uint64 _vrfSubscriptionId,
        uint32 _vrfCallbackGasLimit,
        uint16 _vrfRequestConfirmations
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        altariusCards = _altariusCards;
        s = _altariusMinterStorage;
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfKeyHash = _vrfKeyHash;
        vrfSubscriptionId = _vrfSubscriptionId;
        vrfCallbackGasLimit = _vrfCallbackGasLimit;
        vrfRequestConfirmations = _vrfRequestConfirmations;
    }

    receive() external payable {}

    function withdraw(uint256 amount) external onlyRole(WITHDRAWER_ROLE) {
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function pause() external onlyRole(CONFIGURATOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(CONFIGURATOR_ROLE) {
        _unpause();
    }

    function setVrfCoordinator(
        address _vrfCoordinator
    ) external onlyRole(CONFIGURATOR_ROLE) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    function setVrfKeyHash(
        bytes32 _vrfKeyHash
    ) external onlyRole(CONFIGURATOR_ROLE) {
        vrfKeyHash = _vrfKeyHash;
    }

    function setVrfSubscriptionId(
        uint64 _vrfSubscriptionId
    ) external onlyRole(CONFIGURATOR_ROLE) {
        vrfSubscriptionId = _vrfSubscriptionId;
    }

    function setCallbackGasLimit(
        uint32 _callbackGasLimit
    ) external onlyRole(CONFIGURATOR_ROLE) {
        vrfCallbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(
        uint16 _requestConfirmations
    ) external onlyRole(CONFIGURATOR_ROLE) {
        vrfRequestConfirmations = _requestConfirmations;
    }

    function mintFreePack(
        uint256 edition,
        bytes32[] memory proof
    ) external whenNotPaused {
        AltariusMinterStorage.PackMetadata memory packMetadata = s
            .getPackMetadata(edition);
        uint256 freePacksClaimed = s.getFreePacksClaimed(edition, msg.sender);
        require(!packMetadata.paused, "Pack paused");
        require(packMetadata.freePacksAvailable > 0, "No free packs left");
        require(
            freePacksClaimed < packMetadata.maxFreePacksPerAddress,
            "Max free packs minted"
        );
        if (packMetadata.onlyWhitelisted) {
            bytes32 leaf = keccak256(
                bytes.concat(keccak256(abi.encode(msg.sender)))
            );
            require(
                MerkleProof.verify(proof, packMetadata.merkleRoot, leaf),
                "Invalid proof"
            );
        }

        s.setFreePacksAvailable(edition, packMetadata.freePacksAvailable - 1);
        s.setFreePacksClaimed(edition, msg.sender, freePacksClaimed + 1);

        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.coinbase,
                    block.difficulty,
                    block.gaslimit,
                    block.timestamp
                )
            )
        );
        mintPack(edition, random);
    }

    function requestPack(
        uint256 edition,
        bytes32[] memory proof
    ) external payable whenNotPaused returns (uint256 requestId) {
        AltariusMinterStorage.PackMetadata memory packMetadata = s
            .getPackMetadata(edition);
        require(!packMetadata.paused, "Pack paused");
        require(packMetadata.payablePacksAvailable > 0, "No packs left");
        require(msg.value == packMetadata.price, "Incorrect amount");
        require(
            pendingVrfRequestIds[msg.sender] == 0,
            "Request already pending"
        );
        if (packMetadata.onlyWhitelisted) {
            bytes32 leaf = keccak256(
                bytes.concat(keccak256(abi.encode(msg.sender)))
            );
            require(
                MerkleProof.verify(proof, packMetadata.merkleRoot, leaf),
                "Invalid proof"
            );
        }

        s.setPayablePacksAvailable(edition, packMetadata.payablePacksAvailable - 1);

        requestId = vrfCoordinator.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            vrfRequestConfirmations,
            vrfCallbackGasLimit,
            1
        );
        vrfRequests[requestId] = RequestStatus({
            sender: msg.sender,
            exists: true,
            fulfilled: false,
            minted: false,
            randomWord: 0,
            edition: edition
        });
        pendingVrfRequestIds[msg.sender] = requestId;
        emit RequestSent(msg.sender, requestId);
        return requestId;
    }

    function mintPayablePack() external whenNotPaused {
        require(pendingVrfRequestIds[msg.sender] != 0, "No pending request");
        uint256 requestId = pendingVrfRequestIds[msg.sender];
        RequestStatus memory request = vrfRequests[requestId];
        require(request.fulfilled, "Request not fulfilled");
        request.minted = true;
        pendingVrfRequestIds[msg.sender] = 0;
        mintPack(request.edition, request.randomWord);
    }

    function getPackMetadata(
        uint256 edition
    ) external view returns (AltariusMinterStorage.PackMetadata memory) {
        return s.getPackMetadata(edition);
    }

    function getFreePacksClaimed(
        uint256 edition,
        address user
    ) external view returns (uint256) {
        return s.getFreePacksClaimed(edition, user);
    }

    function getCardIds(
        uint256 edition,
        uint256 cardType,
        uint256 level,
        uint256 rarity,
        bool holographic
    ) external view returns (uint256[] memory) {
        return s.getCardIds(edition, cardType, level, rarity, holographic);
    }

    function getPackMerkleTreeCid(
        uint256 edition
    ) external view returns (string memory) {
        return s.getPackMerkleTreeCid(edition);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(vrfRequests[_requestId].exists, "request not found");
        vrfRequests[_requestId].fulfilled = true;
        vrfRequests[_requestId].randomWord = _randomWords[0];
        emit RequestFulfilled(
            vrfRequests[_requestId].sender,
            _requestId,
            _randomWords[0]
        );
    }

    function mintPack(uint256 edition, uint256 random) internal {
        uint256[] memory mintableCardIds = new uint256[](3);
        uint256[] memory randomWords = expand(random, 12);

        // Armor
        mintableCardIds[0] = getRandomCard(
            edition,
            0,
            randomWords[0],
            randomWords[1],
            randomWords[2],
            randomWords[3]
        );

        // Hero
        mintableCardIds[1] = getRandomCard(
            edition,
            1,
            randomWords[4],
            randomWords[5],
            randomWords[6],
            randomWords[7]
        );

        // Weapon
        mintableCardIds[2] = getRandomCard(
            edition,
            2,
            randomWords[8],
            randomWords[9],
            randomWords[10],
            randomWords[11]
        );

        uint256[] memory mintableCardAmounts = new uint256[](3);
        mintableCardAmounts[0] = 1;
        mintableCardAmounts[1] = 1;
        mintableCardAmounts[2] = 1;

        altariusCards.mintBatch(
            msg.sender,
            mintableCardIds,
            mintableCardAmounts,
            ""
        );
        emit PackMinted(msg.sender, edition, mintableCardIds);
    }

    function getRandomCard(
        uint256 edition,
        uint256 cardType,
        uint256 randomWordLevel,
        uint256 randomWordRarity,
        uint256 randomWordHolographic,
        uint256 randomWordCard
    ) internal view returns (uint256) {
        uint256 level = getRandomLevel(randomWordLevel);
        uint256 rarity = getRandomRarity(randomWordRarity);
        bool holographic = getRandomHolographic(randomWordHolographic);
        if (
            s
                .getCardIds(edition, cardType, level, rarity, holographic)
                .length == 0
        ) {
            holographic = false;
        }
        uint256[] memory randomCardIds = s.getCardIds(
            edition,
            cardType,
            level,
            rarity,
            holographic
        );
        return randomCardIds[randomWordCard % randomCardIds.length];
    }

    function getRandomLevel(uint256 n) internal pure returns (uint256) {
        uint256 probability = n % 10000;
        if (probability < 7395) {
            return 1;
        } else if (probability < 9945) {
            return 2;
        } else if (probability < 9995) {
            return 3;
        } else {
            return 4;
        }
    }

    function getRandomRarity(uint256 n) internal pure returns (uint256) {
        uint256 probability = n % 10000;
        if (probability < 4800) {
            return 0;
        } else if (probability < 7300) {
            return 1;
        } else if (probability < 9400) {
            return 2;
        } else {
            return 3;
        }
    }

    function getRandomHolographic(uint256 n) internal pure returns (bool) {
        return n % 100 == 1;
    }

    function expand(
        uint256 randomValue,
        uint256 n
    ) internal pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }
}