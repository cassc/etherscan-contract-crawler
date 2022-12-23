// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "openzeppelin-contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/utils/StringsUpgradeable.sol";

import "solady/utils/LibBitmap.sol";

contract WhiteWhale is
    ERC721Upgradeable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable
{
    string baseURI;

    struct Gift {
        uint256 tokenId;
        address collection;
        address depositor;
        uint8 stealCounter;
    }

    // the pool of gifts that have been deposited
    Gift[] public gifts;

    // Bitmap from giftPoolIndex to unwrapped status
    LibBitmap.Bitmap isClaimed;

    // maps tokenId to giftPoolIndex + 1
    mapping(uint256 => uint256) public claimedGifts;

    struct TurnState {
        uint120 currentTurn;
        uint120 currentSteal;
        uint8 stealCounter;
    }

    TurnState public turnState;

    enum GameState {
        NOT_STARTED,
        IN_PROGRESS,
        COMPLETED,
        BORKED
    }

    GameState public gameState;

    event GameStarted();
    event GameEnded();
    event GiftDeposited(address depositor, address collection, uint256 tokenId);
    event GiftClaimed(address claimer, uint256 giftIndex);
    event GiftStolen(address stealer, address victim, uint256 giftIndex);
    event GiftWithdrawn(
        address withdrawer,
        address collection,
        uint256 tokenId
    );

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        address owner
    ) public initializer {
        __ERC721_init(name, symbol);
        _transferOwnership(owner);
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    baseURI,
                    StringsUpgradeable.toHexString(address(this)),
                    "/"
                )
            );
    }

    // deposit
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        require(gameState == GameState.NOT_STARTED, "Game has already started");
        require(balanceOf(from) == 0, "Already deposited gift");

        gifts.push(Gift(tokenId, msg.sender, from, 0));

        _safeMint(from, gifts.length);

        emit GiftDeposited(from, msg.sender, tokenId);

        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        if (from != address(0)) {
            require(
                gameState == GameState.COMPLETED,
                "Tokens are locked until game is over"
            );
        }

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    // start game
    function start() public onlyOwner {
        require(gameState == GameState.NOT_STARTED, "Game already started");

        turnState.currentTurn = 1;
        gameState = GameState.IN_PROGRESS;

        emit GameStarted();
    }

    // end game
    function end() public onlyOwner {
        require(gameState == GameState.IN_PROGRESS, "Game is not in progress");
        require(
            turnState.currentTurn == gifts.length + 1,
            "Game has not been completed"
        );

        gameState = GameState.COMPLETED;
        emit GameEnded();
    }

    function bork() public onlyOwner {
        gameState = GameState.COMPLETED;

        for (uint256 i = 0; i < gifts.length; i++) {
            setGiftIndex(i + 1, i);
        }
    }

    // withdraw token
    function withdraw(uint256 tokenId) external {
        require(gameState == GameState.COMPLETED, "Game is not finished");

        uint256 giftIndex = claimedGifts[tokenId] - 1;

        Gift memory gift = gifts[giftIndex];

        IERC721Upgradeable(gift.collection).safeTransferFrom(
            address(this),
            ownerOf(tokenId),
            gift.tokenId
        );

        emit GiftWithdrawn(ownerOf(tokenId), gift.collection, gift.tokenId);
    }

    function getCurrentTurn() public view returns (uint256 tokenId) {
        if (turnState.currentSteal > 0) {
            return turnState.currentSteal;
        }

        return turnState.currentTurn;
    }

    function getAllGifts() public view returns (Gift[] memory) {
        return gifts;
    }

    function getIsClaimedByIndex(uint256 giftIndex) public view returns (bool) {
        return LibBitmap.get(isClaimed, giftIndex);
    }

    function getGiftByIndex(uint256 giftIndex)
        public
        view
        returns (Gift memory)
    {
        return gifts[giftIndex];
    }

    function getGiftByTokenId(uint256 tokenId)
        public
        view
        returns (Gift memory)
    {
        if (!hasClaimedGift(tokenId)) return Gift(0, address(0), address(0), 0);
        uint256 giftIndex = getGiftIndex(tokenId);
        return gifts[giftIndex];
    }

    function getTokenIdByGiftIndex(uint256 giftIndex)
        public
        view
        returns (uint256)
    {
        for (uint256 tokenId = 1; tokenId < gifts.length + 1; tokenId++) {
            if (giftIndex == getGiftIndex(tokenId)) {
                return tokenId;
            }
        }

        return 0;
    }

    function hasClaimedGift(uint256 tokenId) public view returns (bool) {
        return claimedGifts[tokenId] != 0;
    }

    function getGiftIndex(uint256 tokenId) public view returns (uint256) {
        if (claimedGifts[tokenId] == 0) return 0;
        return claimedGifts[tokenId] - 1;
    }

    function setGiftIndex(uint256 tokenId, uint256 giftIndex) internal {
        claimedGifts[tokenId] = giftIndex + 1;
    }

    // claimGift
    function claimGift(uint256 tokenId, uint256 targetGiftIndex) external {
        require(gameState == GameState.IN_PROGRESS, "Game is not in progress");
        require(!hasClaimedGift(tokenId), "Already unwrapped gift");
        require(ownerOf(tokenId) == msg.sender, "Not your token");
        require(tokenId == getCurrentTurn(), "Not your turn");
        require(
            !LibBitmap.get(isClaimed, targetGiftIndex),
            "Gift has already been claimed"
        );
        require(
            getGiftByIndex(targetGiftIndex).depositor != msg.sender,
            "Cannot claim your own gift"
        );

        setGiftIndex(tokenId, targetGiftIndex);
        LibBitmap.set(isClaimed, targetGiftIndex);

        turnState = TurnState(turnState.currentTurn + 1, 0, 0);

        emit GiftClaimed(msg.sender, targetGiftIndex);
    }

    // stealGift
    function stealGift(uint256 tokenId, uint256 targetTokenId) external {
        require(gameState == GameState.IN_PROGRESS, "Game is not in progress");
        require(!hasClaimedGift(tokenId), "Already unwrapped gift");
        require(
            turnState.stealCounter < 3,
            "Cannot steal more than three times in a row"
        );

        address giftHolder = ownerOf(targetTokenId);
        uint256 targetGiftIndex = getGiftIndex(targetTokenId);

        require(giftHolder != msg.sender, "Cannot steal gift from yourself");
        require(hasClaimedGift(targetTokenId), "No gift to steal");
        require(
            gifts[targetGiftIndex].stealCounter < 3,
            "Gift cannot be stolen more than three times"
        );
        require(
            gifts[targetGiftIndex].depositor != msg.sender,
            "Cannot steal your own gift"
        );
        require(ownerOf(tokenId) == msg.sender, "Not your turn");
        require(tokenId == getCurrentTurn(), "Not your turn");

        uint256 giftIndex = getGiftIndex(targetTokenId);
        setGiftIndex(tokenId, giftIndex);
        delete claimedGifts[targetTokenId];

        gifts[giftIndex].stealCounter += 1;

        turnState = TurnState(
            turnState.currentTurn,
            uint120(targetTokenId),
            turnState.stealCounter + 1
        );

        emit GiftStolen(msg.sender, giftHolder, giftIndex);
    }
}