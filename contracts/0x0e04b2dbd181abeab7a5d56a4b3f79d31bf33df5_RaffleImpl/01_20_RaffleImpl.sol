// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/Raffle.sol";
import "./Ticket.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract RaffleImpl is Ownable, Raffle, VRFConsumerBaseV2 {
    /* Raffle Variables */
    Ticket public immutable ticketNft;
    uint256 public entranceFee = 0.033 ether;
    uint256 public ticketsLeft;
    uint256 private ticketsLeftToFulfill;
    uint256[] private amounts;
    uint256[] public sums;
    bool public isOpen;
    mapping (address => address) refferalToRefferer;
    uint256 constant private FLOOR = 1_000;
    uint256 public reffererShare = 100;

    /* Chainlink Variables */
    AggregatorV3Interface private priceFeed;
    VRFCoordinatorV2Interface private vrfCoordinator;
    uint32 public constant numWords = 1;
    uint16 public immutable requestConfirmations;
    uint32 public constant callbackGasLimit = 400000;
    bytes32 public keyHash;
    uint64 public subscriptionId;
    mapping (uint256 => address) public playerByRequestId;

    modifier opened() {
        require(isOpen, "RaffleImpl: raffle is closed");
        _;
    }

    constructor(
        uint256[] memory _amounts,
        uint256[] memory _sums,
        address _priceFeed,
        address _ticketNft,
        address _vffCoordinatorV2,
        uint16 _requestConfirmations,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vffCoordinatorV2) {
        require(
            _amounts.length == _sums.length && _amounts.length != 0,
            "RaffleImpl: invalid arguments"
        );
        require(_priceFeed != address(0), "RaffleImpl: invalid arguments");
        require(_ticketNft != address(0), "RaffleImpl: invalid arguments");
        require(_vffCoordinatorV2 != address(0), "RaffleImpl: invalid arguments");
        require(_keyHash != bytes32(0), "RaffleImpl: invalid arguments");
        require(_requestConfirmations != 0, "RaffleImpl: invalid arguments");
        require(_subscriptionId != 0, "RaffleImpl: invalid arguments");

        priceFeed = AggregatorV3Interface(_priceFeed);
        vrfCoordinator = VRFCoordinatorV2Interface(_vffCoordinatorV2);
        requestConfirmations = _requestConfirmations;
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        sums = _sums;

        amounts = _amounts;

        ticketsLeft = 11999;
        ticketsLeftToFulfill = 11999;

        ticketNft = Ticket(_ticketNft);
    }

    function setSubscriptionId(uint64 newId) external onlyOwner {
        require(newId != 0, "RaffleImpl: invalid arguments");
        subscriptionId = newId;
    }

    function setKeyHash(bytes32 newKeyHash) external onlyOwner {
        require(newKeyHash != bytes32(0), "RaffleImpl: invalid arguments");
        keyHash = newKeyHash;
    }

    function openRaffle() external override onlyOwner {
        isOpen = true;
    }

    function stopRaffle() external override onlyOwner {
        isOpen = false;
    }

    function setEntranceFee(uint256 newEntranceFee) external onlyOwner {
        require(newEntranceFee != 0, "RaffleImpl: invalid arguments");
        entranceFee = newEntranceFee;
    }

    function setPriceFeed(address newPriceFeed) external onlyOwner {
        require(newPriceFeed != address(0), "RaffleImpl: invalid arguments");
        priceFeed = AggregatorV3Interface(newPriceFeed);
    }

    function setReffererShare(uint256 newShare) external onlyOwner {
        require (newShare < FLOOR, "RaffleImpl: too big share");
        reffererShare = newShare;
    }

    function finalGame() external view returns (address[20] memory) {
        require(isOpen == false, "RaffleImpl: raffle not stopped");
        return getTopPlayers();
    }

    function pay(
        address target,
        uint256 amountInUsdt
    ) external override onlyOwner {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        uint256 amount = amountInUsdt * uint256(answer);

        (bool success, ) = payable(target).call{value: amount}("");
        require(success, "RaffleImpl: Transfer failed");
    }

    function sendEther(address target, uint256 amount) external override onlyOwner {
        (bool success,) = payable(target).call{value: amount}("");
        require(success, "RaffleImpl: Transfer failed");
    }

    function enterRaffle(address refferer) external payable override opened {
        require(msg.value >= entranceFee, "RaffleImpl: not enough ether sent");
        require(ticketsLeft > 0, "RaffleImpl: All positions are closed");
        require(refferer != msg.sender, "RaffleImpl: Refferer is msg.sender");

        if (refferalToRefferer[msg.sender] == address(0) && refferer != address(0)) {
            refferalToRefferer[msg.sender] = refferer;
        }

        if (refferalToRefferer[msg.sender] != address(0)) {
            // don't check return value because we should not revert on failure
            (bool success,) = refferalToRefferer[msg.sender].call{value: entranceFee * reffererShare / FLOOR}("");
            if (success) {
                emit ReffererPaid(block.timestamp, refferalToRefferer[msg.sender], msg.sender, entranceFee, entranceFee * reffererShare / FLOOR);
            }
        }
        
        --ticketsLeft;
        uint256 requestId = vrfCoordinator.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);
        playerByRequestId[requestId] = msg.sender;

        if (msg.value > entranceFee) {
            (bool success,) = payable(msg.sender).call{value: msg.value - entranceFee}("");
            require(success, "RaffleImpl: Transfer failed");
        }
        emit Requested(msg.sender, requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 randomNumber = randomWords[0] % ticketsLeftToFulfill;
        --ticketsLeftToFulfill;
        address player = playerByRequestId[requestId];

        uint256 winningIndex = _chooseWinTicket(randomNumber);

        uint256 sumOfTicket = sums[winningIndex];

        uint256 tokenId = ticketNft.mint(player, sumOfTicket);
        emit WinnerChosen(player, sumOfTicket, tokenId);
    }

    function _chooseWinTicket(uint256 randomNumber) internal returns (uint256) {
        uint256 length = amounts.length;
        uint256 winningIndex = length - 1;

        for (uint256 i = 0; i < length; i++) {
            if (amounts[i] == 0) {
                continue;
            }

            if (amounts[i] < randomNumber) {
                randomNumber -= amounts[i];
            } else {
                winningIndex = i;
                amounts[i]--;
                break;
            }
        }
        return winningIndex;
    }

    function getTicketsLeftBySum(uint256 sum) external view returns (uint256) {
        for (uint256 i = 0; i < sums.length; i++) {
            if (sums[i] == sum) {
                return amounts[i];
            }
        }

        return 0;
    }

    function getTicketsLeft() external view returns (uint256[] memory) {
        return amounts;
    }

    function getTopPlayers() public view returns (address[20] memory) {
        return ticketNft.getTopPlayers();
    }

    receive() external payable {}
}