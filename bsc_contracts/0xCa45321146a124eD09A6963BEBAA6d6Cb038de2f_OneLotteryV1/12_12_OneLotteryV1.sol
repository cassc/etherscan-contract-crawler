// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OneLotteryV1 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    error OnlyCoordinatorCanFulfill(address have, address want);

    event ListGame(
        uint indexed gameId, 
        uint startTime, 
        uint endTime, 
        uint priceInUsdt, 
        uint maxAmountPerBuying, 
        uint maxAmountPerAddress,
        uint totalSupply, 
        uint targetQuantity
    );
    event PauseGame(uint indexed gameId, Status status);
    event RestartGame(uint indexed gameId, Status status);
    event PlayGame(
        address indexed player,
        uint indexed gameId,
        bytes32 indexed orderId,
        uint purchaseAmount, 
        uint fromIndex
    );
    event CloseGameAndCallChainlinkCoordinator(uint indexed gameId, uint requestId);
    event FulfillWinner(uint indexed gameId, uint winnerIndex);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint[] randomWords;
    }

    struct GameInfo {
        uint startTime;
        uint endTime;
        uint priceInUsdt;
        uint maxAmountPerBuying;
        uint maxAmountPerAddress;
        uint totalSupply;
        uint targetQuantity; // The prize will only be given when the target quantity is reached.
    }

    struct GameState {
        Status status;
        uint purchaserCount;
        uint finalWinnerNumber; // final winner number 
    }

    mapping(uint => GameInfo) public idToGameInfo; // game ID => game info
    mapping(uint => GameState) public idToGameState;
    mapping(uint => uint) public requestIdToGameId; // request ID => game ID
    mapping(uint => uint) public gameIdToRequestId; // game ID => request ID
    mapping(uint => mapping(address => uint)) gameIdToAddressPurchaseQuantity;
    mapping(address => uint) public winningPrizes; // owner -> winning game ID
    mapping(uint => RequestStatus) public s_requests; 

    enum Status {Empty, Start, Pause, Close, DrawFinalNumber}
    IERC20Upgradeable public receiveToken;
    // VRF variable
    address public vrfCoordinator;
    VRFCoordinatorV2Interface COORDINATOR;
    uint[] public requestIds;
    uint public lastRequestId;
    uint64 s_subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit; // max callback gas limit 
    uint16 requestConfirmations;
    // can customize request id 
    // uint64 public TRANSFER_REQUEST_ID = 1;

    mapping(address => bool) public whitelist;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "Access denied");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize (
        address _vrfCoordinator, 
        bytes32 _keyHash, 
        uint64 _subscriptionId,
        IERC20Upgradeable _receiveToken,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    )
        public
        initializer
    {
        vrfCoordinator = _vrfCoordinator;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        receiveToken = _receiveToken;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**************************/
    /****  Game Functions  ****/
    /**************************/

    function listGame(
        uint gameId,
        uint startTime,
        uint endTime,
        uint priceInUsdt,
        uint maxAmountPerBuying,
        uint maxAmountPerAddress,
        uint totalSupply,
        uint targetQuantity
    ) external onlyWhitelisted {
        require(idToGameState[gameId].status == Status.Empty, "Game id already exists");
        require(startTime >= block.timestamp, "Start time is before current time");
        require(endTime > startTime, "End time must be after start time");
        require(priceInUsdt > 0, "Price must be greater than zero");
        require(maxAmountPerBuying <= totalSupply, "Max amount per buying cannot exceed total supply");
        require(maxAmountPerBuying > 0, "Max amount per buying must be greater than zero");
        require(maxAmountPerAddress <= totalSupply, "Max amount per address cannot exceed total supply");
        require(maxAmountPerAddress > 0, "Max amount per address must be greater than zero");
        // require(totalSupply > 0, "Total supply must be greater than zero");
        require(targetQuantity > 0, "Target quantity must be greater than zero");
        require(targetQuantity <= totalSupply, "Target quantity cannot exceed total supply");

        idToGameInfo[gameId] = GameInfo(
            startTime,
            endTime,
            priceInUsdt,
            maxAmountPerBuying,
            maxAmountPerAddress,
            totalSupply,
            targetQuantity
        );
        idToGameState[gameId] = GameState(
            Status.Start,
            0,
            0
        );

        emit ListGame(
            gameId, 
            startTime, 
            endTime, 
            priceInUsdt, 
            maxAmountPerBuying, 
            maxAmountPerAddress, 
            totalSupply, 
            targetQuantity
        );
    }

    function pauseGame (uint gameId) external onlyWhitelisted {
        Status status = idToGameState[gameId].status;
        require(status == Status.Start, "Game status is not start");

        idToGameState[gameId].status = Status.Pause;

        emit PauseGame(gameId, Status.Pause);
    }

    function restartGame (uint gameId) external onlyWhitelisted {
        Status status = idToGameState[gameId].status;
        require(status == Status.Pause, "Game status is not pause");

        idToGameState[gameId].status = Status.Start;

        emit RestartGame(gameId, Status.Start);
    }

    function closeGameAndCallChainlinkCoordinator(
        uint gameId
    ) external onlyWhitelisted {
        require(block.timestamp >= idToGameInfo[gameId].endTime, "Game has not ended yet");
        uint playerCount = idToGameState[gameId].purchaserCount;
        uint target = idToGameInfo[gameId].targetQuantity;
        require(playerCount >= target, "Target fail");
        
        idToGameState[gameId].status = Status.Close;
        uint requestId = requestRandomWords(1);
        requestIdToGameId[requestId] = gameId;
        gameIdToRequestId[gameId] = requestId;

        emit CloseGameAndCallChainlinkCoordinator(gameId, requestId);
    }

    /****************************/
    /****  Player Functions  ****/
    /****************************/

    function playGame(
        address player, 
        uint gameId, 
        uint purchaseAmount, 
        bytes32 orderId
    )
        external 
        nonReentrant
    {
        GameInfo memory gameInfo = idToGameInfo[gameId];
        GameState storage gameState = idToGameState[gameId];
        uint cost = gameInfo.priceInUsdt * purchaseAmount;
        uint playerTotalPurchaseAmount = purchaseAmount + gameIdToAddressPurchaseQuantity[gameId][player];
        
        require(idToGameState[gameId].status == Status.Start, "Game status is not start");
        require(block.timestamp >= gameInfo.startTime, "Game has not started yet");
        require(block.timestamp < gameInfo.endTime, "Game has ended");
        require(receiveToken.balanceOf(msg.sender) >= cost, "Insufficient player balance");
        require(
            receiveToken.allowance(msg.sender, address(this)) >= cost, 
            "Insufficient authorization amount"
        );
        require(
            playerTotalPurchaseAmount <= gameInfo.maxAmountPerAddress, 
            "Cannot exceed maximum purchase limit for a single address in this game"
        );
        require(
            purchaseAmount <= gameInfo.maxAmountPerBuying, 
            "Cannot exceed maximum purchase limit per transaction for this game"
        );
        require(
            gameState.purchaserCount + purchaseAmount <= gameInfo.totalSupply, 
            "Exceeds maximum supply for this game"
        );
        require(
            receiveToken.transferFrom(msg.sender, address(this), cost), 
            "Transfer error"
        );

        uint fromIndex = gameState.purchaserCount + 1;
        gameState.purchaserCount += purchaseAmount;
        gameIdToAddressPurchaseQuantity[gameId][player] += purchaseAmount;

        emit PlayGame(player, gameId, orderId, purchaseAmount, fromIndex);
    }

    /****************************/
    /***  Internal Functions  ***/
    /****************************/

    function requestRandomWords(uint8 numWords)
        internal
        returns (uint requestId)
    {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        return requestId;
    }

    function fulfillRandomWords(
        uint _requestId,
        uint[] memory _randomWords
    ) internal {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        uint count = idToGameState[requestIdToGameId[_requestId]].purchaserCount;
        uint finalWinner = _randomWords[0]%count + 1;
        idToGameState[requestIdToGameId[_requestId]].finalWinnerNumber = 
            finalWinner;
        idToGameState[requestIdToGameId[_requestId]].status = 
            Status.DrawFinalNumber;
        emit FulfillWinner(requestIdToGameId[_requestId], finalWinner);
    }

    /***************************/
    /****  Admin Functions  ****/
    /***************************/

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) public onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    /**************************/
    /***  Status Functions  ***/
    /**************************/

    function getRequestStatus(
        uint _requestId
    ) external view returns (bool fulfilled, uint[] memory randomWords) {
        require(s_requests[_requestId].exists, "Request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function getGameFinalWinnerAddress (uint gameId) external view returns (uint) {
        GameState memory gameState = idToGameState[gameId];
        require(s_requests[gameIdToRequestId[gameId]].exists, "Request not found");
        require(
            gameState.status == Status.DrawFinalNumber, 
            "Final number not draw yet"
        );
        return gameState.finalWinnerNumber;
    }

    function getBlocktime () external view returns (uint) {
        return block.timestamp;
    }

    /***************************/
    /***  Utility Functions  ***/
    /***************************/
    
    function getReceiveToken() external onlyWhitelisted {
        uint balanceOfReceiveToken = receiveToken.balanceOf(address(this));
        receiveToken.transfer(msg.sender, balanceOfReceiveToken);
    }

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        if (msg.sender != vrfCoordinator) {
        revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}