// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./DepositDistributor.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TheBullionGame is
    VRFConsumerBaseV2,
    ReentrancyGuard,
    Ownable,
    AutomationCompatibleInterface,
    AccessControl
{ 
    using Address for address payable;

    address private upkeepAddress;
    address payable[] private players;
    address payable private commission;
    address payable private daoPayments;
    uint private gameId;
    mapping(uint => address payable) private gameHistory;
    mapping(uint256 => bool) public requestIdMap;
    uint public randomResult;

    address payable private depositDistributorAddress;
    mapping(uint256 => uint256) private deposits;
    uint256 private depositCount;
    mapping(uint256 => address payable) requestIdToWinner;

    enum GAME_STATE {
        CLOSED,
        OPEN,
        CALCULATING_WINNER,
        PAYING_WINNER,
        WINNER_PAID,
        PAYING_RUNNERS_UP,
        RUNNERS_UP_PAID,
        PAYING_DAO
    }

    GAME_STATE private game_state;

    bytes32 private keyHash;
    uint32 private callbackGasLimit;
    uint16 private requestConfirmations;
    uint16 private numWords;
    uint64 public subscriptionId;
    address private vrfCoordinatorV2Address;
    VRFCoordinatorV2Interface public vrfCoordinatorV2;

    AggregatorV3Interface internal priceFeed;
    uint256 private entryFeeInUSD;
    uint256 private constant PERCENT_DIVISOR = 100;
    uint256 private commissionPercentage;

    bytes32 public constant UPKEEP_ROLE = keccak256("UPKEEP_ROLE");
    bytes32 public constant SETTINGS_ROLE = keccak256("SETTINGS_ROLE");

    uint public immutable interval;
    uint private lastTimeStamp;

    bool private upkeepPerformed;
    bool private performedUpkeep;

    event WinnerDeclared(address indexed winner, uint256 amount);
    event RunnerUpDeclared(address indexed runnerUp, uint256 amount);
    event BalanceTransferredToDAO(
        address indexed daoAddress,
        uint256 membersDepositAmount,
        uint256 amount
    );
    event UpkeepPerformed(uint256 indexed gameId);
    event randomRequested(uint256 requesRandomId);
    event DepositRecorded(uint256 indexed depositCount, uint256 depositAmount);
    event DepositMade(uint256 amount);

    constructor(
        address _daoPayments,
        address _commission,
        uint _updateInterval,
        address _depositDistributorAddress,
        address _priceFeed,
        address _upkeepAddress,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint16 _numWords,
        uint64 _subscriptionId,
        address _vrfCoordinatorV2Address
    ) VRFConsumerBaseV2(_vrfCoordinatorV2Address) {
        require(_daoPayments != address(0), "Invalid DAO payments address");
        require(
            _commission != address(0),
            "Invalid transaction commission address"
        );
        upkeepAddress = _upkeepAddress;
        gameId = 1;
        commission = payable(_commission);
        daoPayments = payable(_daoPayments);
        game_state = GAME_STATE.CLOSED;
        upkeepPerformed = false;

        performedUpkeep = false;
        interval = _updateInterval;
        lastTimeStamp = block.timestamp;
        priceFeed = AggregatorV3Interface(_priceFeed);
        entryFeeInUSD = 3.33 * 1e18;
        commissionPercentage = 10;
        depositDistributorAddress = payable(_depositDistributorAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SETTINGS_ROLE, msg.sender);
        _setupRole(UPKEEP_ROLE, upkeepAddress);

        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
        subscriptionId = _subscriptionId;
        vrfCoordinatorV2Address = _vrfCoordinatorV2Address;
        vrfCoordinatorV2 = VRFCoordinatorV2Interface(_vrfCoordinatorV2Address);
    }

    modifier onlyUpkeep() {
        require(msg.sender == upkeepAddress);
        _;
    }

    function updateEntryFee(
        uint256 _entryFeeInUSD
    ) external onlyRole(SETTINGS_ROLE) {
        entryFeeInUSD = _entryFeeInUSD;
    }

    function grantUpkeepRole(
        address chainlinkNodeAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(UPKEEP_ROLE, chainlinkNodeAddress);
    }

    function grantSettingsRole(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(SETTINGS_ROLE, account);
    }

    function revokeUpkeepRole(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(UPKEEP_ROLE, account);
    }

    function revokeSettingsRole(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(SETTINGS_ROLE, account);
    }

    function setUpkeepAddress(
        address _upkeepAddress
    ) public onlyOwner returns (address) {
        upkeepAddress = _upkeepAddress;
        return upkeepAddress;
    }

    function updatePriceFeed(
        address newPriceFeed
    ) external onlyRole(SETTINGS_ROLE) {
        priceFeed = AggregatorV3Interface(newPriceFeed);
    }

    function getWinnerByLottery(
        uint game
    ) public view returns (address payable) {
        return gameHistory[game];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function resetTimer() public onlyOwner {
        lastTimeStamp = block.timestamp;
    }

    function getTimeLeft() public view returns (uint) {
        return block.timestamp - lastTimeStamp;
    }

    function getDepositDistributorAddress() public view returns (address) {
        return depositDistributorAddress;
    }

    function getDAOPaymentsAddress() public view returns (address) {
        return daoPayments;
    }

    function getGameState() public view returns (GAME_STATE) {
        return game_state;
    }

    function getCommissionPercentage() public view returns (uint256) {
        return commissionPercentage;
    }

    function getEntryFeeInUsd() public view returns (uint256) {
        return entryFeeInUSD;
    }

    function getGameId() public view returns (uint256) {
        return gameId;
    }

    function updateCallbackGasLimit(
        uint32 _callbackGasLimit
    ) external onlyRole(SETTINGS_ROLE) {
        callbackGasLimit = _callbackGasLimit;
    }

    function updateKeyHash(bytes32 _keyHash) external onlyRole(SETTINGS_ROLE) {
        keyHash = _keyHash;
    }

    function updateRequestConfirmations(
        uint16 _requestConfirmations
    ) external onlyRole(SETTINGS_ROLE) {
        requestConfirmations = _requestConfirmations;
    }

    function updateNumWords(uint16 _numWords) external onlyRole(SETTINGS_ROLE) {
        numWords = _numWords;
    }

    function updateSubscriptionId(
        uint64 _subscriptionId
    ) external onlyRole(SETTINGS_ROLE) {
        subscriptionId = _subscriptionId;
    }

    function updateVrfCoordinatorV2Address(
        address _vrfCoordinatorV2Address
    ) external onlyRole(SETTINGS_ROLE) {
        vrfCoordinatorV2Address = _vrfCoordinatorV2Address;
        vrfCoordinatorV2 = VRFCoordinatorV2Interface(_vrfCoordinatorV2Address);
    }

    function startGame() public {
        require(game_state == GAME_STATE.CLOSED);
        game_state = GAME_STATE.OPEN;
        lastTimeStamp = block.timestamp;
    }

    function endGame() public onlyOwner {
        require(game_state == GAME_STATE.OPEN);
        performedUpkeep = true;
        requestRandomWords();
    }

    function checkUpkeep(
        bytes calldata checkData
    )
        external
        view
        override
        onlyRole(UPKEEP_ROLE)
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (
            (game_state == GAME_STATE.OPEN) &&
            keccak256(checkData) == keccak256(hex"01")
        ) {
            upkeepNeeded = (block.timestamp - lastTimeStamp) >= interval;
            performData = checkData;
        }
    }

    function performUpkeep(
        bytes calldata performData
    ) external override onlyRole(UPKEEP_ROLE) {
        // We highly recommend revalidating the upkeep in the performUpkeep function
        require(
            (block.timestamp - lastTimeStamp) >= interval,
            "Only VRFCoordinatorV2 can fulfill"
        );

        if (keccak256(performData) == keccak256(hex"01")) {
            upkeepPerformed = true;
            checkPlayersTrue();
        }
    }

    function checkPlayersTrue() internal {
        require(upkeepPerformed == true, "Upkeep not performed");

        if ((address(this).balance < .3 ether)) {
            upkeepPerformed = false;
            lastTimeStamp = block.timestamp;
        } else {
            upkeepPerformed = false;
            performedUpkeep = true;
            requestRandomWords();
        }
    }

    function requestRandomWords()
        private
        nonReentrant
        returns (uint256 requestId)
    {
        require(performedUpkeep == true, "Upkeep not performed");
        performedUpkeep = false;
        game_state = GAME_STATE.CALCULATING_WINNER;

        requestId = vrfCoordinatorV2.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestIdMap[requestId] = true;
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(
            game_state == GAME_STATE.CALCULATING_WINNER,
            "Game state not CALCULATING_WINNER"
        );
        require(
            msg.sender == vrfCoordinatorV2Address,
            "Only VRFCoordinatorV2 can fulfill"
        );
        // require(_requestId > 0, "Invalid requestId");
        require(_randomWords.length > 0, "Invalid randomWords");
        require(requestIdMap[_requestId], "Invalid request ID");

        game_state = GAME_STATE.PAYING_WINNER;
        uint256 index = _randomWords[0] % players.length;
        delete requestIdMap[_requestId];
        address payable winnerAddress = payable(players[index]);
        requestIdToWinner[_requestId] = winnerAddress; // Store the winner's address for the given request ID
        declareWinner(_requestId, winnerAddress, _randomWords);
    }

    function declareWinner(
        uint256 _requestId,
        address payable winner,
        uint256[] memory _randomWords
    ) private {
        require(
            game_state == GAME_STATE.PAYING_WINNER,
            "Game must be in Paying winner state"
        );
        require(
            winner != address(0) && winner != address(this),
            "Invalid winner address "
        );
        require(
            requestIdToWinner[_requestId] == winner,
            "Winner does not match requestIdToWinner mapping"
        );
        game_state = GAME_STATE.WINNER_PAID;
        uint256 winnerShares = address(this).balance / 2;
        winner.sendValue(winnerShares);
        gameHistory[gameId] = winner;
        emit WinnerDeclared(winner, winnerShares);
        declareRunnerUps(winner, _randomWords);
    }

    function declareRunnerUps(
        address payable winner,
        uint256[] memory _randomWords
    ) private {
        require(
            game_state == GAME_STATE.WINNER_PAID,
            "Game must be in Closed state"
        );

        game_state = GAME_STATE.PAYING_RUNNERS_UP;
        uint256 index = 0;
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == winner) {
                index = i;
                break;
            }
        }

        uint256 runnersUpShare = (address(this).balance * 2) / 5;
        uint256 numRunnersUp = players.length - 1;
        uint256 iterations = numRunnersUp <= 20 ? numRunnersUp : 20;
        uint256[] memory runnerIndices = new uint256[](iterations);

        if (numRunnersUp > 0) {
            for (uint256 j = 0; j < iterations; j++) {
                uint256 randomIndex = _randomWords[j + 1] % (numRunnersUp - j);
                runnerIndices[j] = index != 0
                    ? (randomIndex >= index ? randomIndex + 1 : randomIndex)
                    : randomIndex;
                if (runnerIndices[j] == index) runnerIndices[j]++;
                if (randomIndex < numRunnersUp - j - 1)
                    _randomWords[randomIndex + 1] = _randomWords[
                        numRunnersUp - j
                    ];
            }
        }

        uint256 runnersUpSharePerPlayer = runnersUpShare / numRunnersUp;
        for (uint256 j = 0; j < players.length; j++) {
            if (j != index) {
                address payable runner = payable(players[j]);
                require(
                    runner != address(0) && runner != address(this),
                    "Invalid runner-up address"
                );
                runner.sendValue(runnersUpSharePerPlayer);
                emit RunnerUpDeclared(players[j], runnersUpSharePerPlayer);
            }
        }

        game_state = GAME_STATE.RUNNERS_UP_PAID;
        transferBalanceToDAO();
    }

    function transferBalanceToDAO() private {
        require(
            game_state == GAME_STATE.RUNNERS_UP_PAID,
            "Game must be in Runersup Paid state"
        );

        game_state = GAME_STATE.PAYING_DAO;
        uint256 balance = address(this).balance;
        uint256 depositAmount = (balance * 3) / 10; // Calculate 30% of the balance
        uint256 remainingBalance = balance - depositAmount;

        // Store deposit amount for later withdrawal
        deposits[depositCount] = depositAmount;
        depositCount++;

        emit DepositRecorded(depositCount, depositAmount);
        (bool success, ) = daoPayments.call{value: remainingBalance}("");
        require(success, "Transfer to DAO failed");

        emit BalanceTransferredToDAO(
            daoPayments,
            depositAmount,
            remainingBalance
        );

        gameId++;
        players = new address payable[](0);

        game_state = GAME_STATE.CLOSED;
        startGame();
    }

    // Deposit the specified amount to the deposit distributor contract
    function depositToDistributor(uint256 amount) private {
        require(amount > 0, "Amount must be greater than zero");

        DepositDistributor depositDistributorInstance = DepositDistributor(
            depositDistributorAddress
        );

        depositDistributorInstance.deposit{value: amount}(amount);

        emit DepositMade(amount);
    }

    function withdrawDeposits() external onlyOwner {
        for (uint256 i = 0; i < depositCount; i++) {
            uint256 amount = deposits[i];
            deposits[i] = 0;
            depositToDistributor(amount);
        }
    }

    function getLatestBNBUsdPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) / 1e8;
        uint256 entryFee = entryFeeInUSD / adjustedPrice;
        // uint256 adjustedForDifference = entryFee + (entryFee * 1 / 100)
        return entryFee;
    }

    function enter() public payable nonReentrant {
        require(game_state == GAME_STATE.OPEN, "Game state not OPEN");
        require(msg.sender != owner(), "Owner cannot enter");

        require(msg.value >= getLatestBNBUsdPrice(), "Entry fee too low");

        uint256 commissionInWei = (msg.value * commissionPercentage) /
            PERCENT_DIVISOR;

        players.push(payable(msg.sender));
        commission.transfer(commissionInWei);
    }
}