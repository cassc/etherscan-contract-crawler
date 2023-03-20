// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DefaultOperatorFilterer} from "./filter/DefaultOperatorFilterer.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./ERC721A.sol";

contract xyz224 is Ownable, ERC721A, ReentrancyGuard, VRFConsumerBaseV2, DefaultOperatorFilterer {
    
    //chainlink VRF
    event RequestSent(uint256 requestId);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    uint256[] public requestIds;
    uint256 public lastRequestId;
    bytes32 keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;
    uint256 public rand1;
    uint256 public rand2;

    constructor(
        string memory name,
        string memory symbol,
        uint64 subscriptionId
    )
        ERC721A(name, symbol)
        VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
        );
        // s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRands() external view returns (uint256[] memory randomWords) {
        RequestStatus memory request = s_requests[lastRequestId];
        return request.randomWords;
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    // main contract variables
    uint256 public MAX_SUPPLY = 5555;
    uint8 public totalTraitIds = 100;
    uint256 public traitPrice = 0.02 ether;
    uint256 public currentChosenTrait;
    uint256 public eliminationCount;
    uint256 public numWinners;
    bool public gameEnded;
    bool public gameHasStarted;

    uint256 public jackpot;
    uint256 public teamBalance;
    mapping(uint256 => bool) public tokenHasClaimedPrize;

    // tokenId => traitId
    mapping(uint256 => uint256) public headgearForToken;
    mapping(uint256 => uint256) public outfitForToken;
    mapping(uint256 => uint256) public upgradeCountPerToken;
    mapping(uint256 => bool) public traitIsEliminated;
    // quantity of outfit and headgear traits (traits get zeroed out with elimination in traitAmountCounter)
    // 0-4 are headgear base traits, 5-14 are outfit base traits
    uint256[] public traitAmountCounter = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 50, 50, 50, 250, 125, 200, 50, 125, 125, 50, 50, 125, 50, 50, 250, 125, 250, 250, 125, 125, 250, 250, 250, 125, 250, 50, 40, 125, 40, 125, 40, 125, 40, 250, 125, 125, 125, 200, 50, 100, 100, 50, 50, 200, 40, 200, 200, 50, 200, 200, 100, 100, 50, 200, 50, 100, 100, 40, 100, 100, 50, 200, 200, 100, 50, 40, 50, 200, 50, 200, 200, 50, 40, 50, 100, 40, 100, 200, 200, 100, 40, 200, 50, 200 ];
    uint256[] public purchaseTraitCounter = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 50, 50, 50, 250, 125, 200, 50, 125, 125, 50, 50, 125, 50, 50, 250, 125, 250, 250, 125, 125, 250, 250, 250, 125, 250, 50, 40, 125, 40, 125, 40, 125, 40, 250, 125, 125, 125, 200, 50, 100, 100, 50, 50, 200, 40, 200, 200, 50, 200, 200, 100, 100, 50, 200, 50, 100, 100, 40, 100, 100, 50, 200, 200, 100, 50, 40, 50, 200, 50, 200, 200, 50, 40, 50, 100, 40, 100, 200, 200, 100, 40, 200, 50, 200 ];
    // total across the two categories
    uint256 public totalTraits = 10150;

    receive() external payable {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setGameHasStarted(bool isActive) external onlyOwner {
        gameHasStarted = isActive;
    }

    function setGameEnded(uint256 totalWinners) external onlyOwner {
        // numWinners can be read from the contract, however it must be set manually here due to memory caps for functions
        numWinners = totalWinners;
        gameEnded = true;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setTraitPrice(uint256 _price) external onlyOwner {
        traitPrice = _price;
    }

    function getTraitQuantities() public view returns (uint256[] memory) {
        return traitAmountCounter;
    }

    function getPurchaseTraitQuantities()
        public
        view
        returns (uint256[] memory)
    {
        return purchaseTraitCounter;
    }

    function getTraitsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256[2] memory)
    {
        return [headgearForToken[tokenId], outfitForToken[tokenId]];
    }

    function getAllTokenInfo(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "{'headgear':",
                    Strings.toString(headgearForToken[tokenId]),
                    ",'headgearElim':",
                    traitIsEliminated[headgearForToken[tokenId]]
                        ? "true"
                        : "false",
                    ",'outfit':",
                    Strings.toString(outfitForToken[tokenId]),
                    ",'outfitElim':",
                    traitIsEliminated[outfitForToken[tokenId]]
                        ? "true"
                        : "false",
                    ",'completelyElim':",
                    isEliminated(tokenId) ? "true" : "false",
                    ",'hasClaimedPrize':",
                    tokenHasClaimedPrize[tokenId] ? "true" : "false",
                    ",'upgradeCount':",
                    Strings.toString(upgradeCountPerToken[tokenId]),
                    "}"
                )
            );
    }

    // airdrop to holders
    function airdrop(address[] calldata to) external onlyOwner nonReentrant {
        require(
            totalSupply() + to.length <= MAX_SUPPLY,
            "would exceed max supply"
        );
        for (uint256 i = 0; i < to.length; i++) {
            // assign base traits to token at time of int
            uint256 outfit = randomOutfits();
            uint256 headgear = randomHeadgear();
            outfitForToken[totalSupply()] = outfit;
            headgearForToken[totalSupply()] = headgear;
            traitAmountCounter[outfit] = traitAmountCounter[outfit] + 1;
            traitAmountCounter[headgear] = traitAmountCounter[headgear] + 1;
            totalTraits += 2;
            _safeMint(to[i], 1);
        }
    }

    // pseudorandom for base headgear between 0 and 4
    function randomHeadgear() internal view returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, totalSupply()))
        ) % 5;
        return randomnumber;
    }

    // pseudorandom for base outfits between 5 and 14
    function randomOutfits() internal view returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, totalSupply()))
        ) % 10;
        randomnumber = randomnumber + 5;
        return randomnumber;
    }

    // metadata URI
    string private _baseTokenURI;

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // manually add money to jackpot from team wallet
    function addToJackpot() external payable onlyOwner {
        require(msg.value > 0, "Must send more than 0 ETH");
        jackpot += msg.value;
    }

    // RPC only due to memory issue in looping (no internal calls)
    function totalEliminated() public view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < totalSupply(); i++) {
            if (isEliminated(i)) {
                count++;
            }
        }
        return count;
    }

    function isEliminated(uint256 tokenId) public view returns (bool) {
        if (
            traitIsEliminated[headgearForToken[tokenId]] == false ||
            traitIsEliminated[outfitForToken[tokenId]] == false
        ) {
            return false;
        } else {
            return true;
        }
    }

    function eliminateTrait() external onlyOwner returns (uint256) {
        require(gameHasStarted == true, "game has not started yet");
        require(gameEnded == false, "game has ended");
        // // pick a random index to start at, then loop through until we land on the random number counting as we go 
        // uint256[] memory rands = this.getRands();
        // uint256 randomIndex = rands[0] % traitAmountCounter.length;
        // // get a random number between 0 and totalTraits
        // uint256 randomNumber = rands[1] % totalTraits;
        
        // non chainlink version
        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, totalSupply()))
        ) % traitAmountCounter.length;

        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, totalSupply()))
        ) % totalTraits;

        uint256 currentIndex = randomIndex;
        uint256 sumCounter = traitAmountCounter[currentIndex];

        while (sumCounter < randomNumber) {
            if (currentIndex == traitAmountCounter.length - 1) {
                currentIndex = 0;
            } else {
                currentIndex++;
            }
            sumCounter = sumCounter + traitAmountCounter[currentIndex];
        }
        totalTraits = totalTraits - traitAmountCounter[currentIndex];
        traitAmountCounter[currentIndex] = 0;
        traitIsEliminated[currentIndex] = true;
        currentChosenTrait = currentIndex;
        eliminationCount++;
        return currentIndex;
    }

    // buy trait
    function buyTrait(uint256 traitId, uint256 tokenId)
        external
        payable
        nonReentrant
    {
        require(gameHasStarted == true, "game has not started");
        require(gameEnded == false, "game has endeed");
        require(msg.sender == ownerOf(tokenId), "Must be token owner");
        require(msg.value == traitPrice, "Incorrect amount sent");
        require(traitIsEliminated[traitId] == false, "Trait is eliminated");
        require(purchaseTraitCounter[traitId] > 0, "Trait is sold out");
        require(isEliminated(tokenId) == false, "Token is eliminated");
        require(traitId > 14, "Cannot buy base traits");

        purchaseTraitCounter[traitId]--;
        // separate headgear from outfit
        if (traitId < 54) {
            outfitForToken[tokenId] = traitId;
        } else {
            headgearForToken[tokenId] = traitId;
        }

        jackpot += (msg.value * 7) / 10;
        teamBalance += (msg.value * 3) / 10;
        upgradeCountPerToken[tokenId]++;
    }

    function claimPrize(uint256 tokenId) external nonReentrant {
        require(msg.sender == ownerOf(tokenId), "Must be token owner");
        require(isEliminated(tokenId) == false, "Token is eliminated");
        require(
            tokenHasClaimedPrize[tokenId] == false,
            "Token has claimed prize already"
        );
        require(gameEnded == true, "Game is still in action");
        require(numWinners != 0, "No winners");
        tokenHasClaimedPrize[tokenId] = true;
        uint256 prize = jackpot / numWinners;
        payable(msg.sender).transfer(prize);
    }

    // withdrawl team earnings
    function teamWithdraw() external onlyOwner {
        require(gameEnded == true, "Game is still in action");
        require(teamBalance > 0, "No funds to withdraw");
        payable(msg.sender).transfer(teamBalance);
        teamBalance = 0;
    }

    // OperatorFilter
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}