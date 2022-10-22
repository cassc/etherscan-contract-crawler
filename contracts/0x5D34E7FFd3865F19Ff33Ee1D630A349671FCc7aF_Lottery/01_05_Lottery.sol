// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error Lottery__NotEnoughETHEntered();
error Lottery__TransfearFailed();
error Lottery__NotOpen();
error Lottery__NotEnoughPlayers();
error Lottery__NoLinkBalance();
error Lottery__AlreadyEntered(string message);
error Lottery__Full();

contract Lottery is VRFConsumerBaseV2 {
    LinkTokenInterface LINKTOKEN;
    address link_token_contract = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    enum LotteryState {
        OPEN,
        CALCULATING
    }

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionID;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    address private s_recentWinner;
    LotteryState private s_lotteryState;
    AggregatorV3Interface internal priceFeed;

    event LotteryEnter(address indexed player);
    event RequestedLotteryWinner(uint256 indexed requestID);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subID,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        i_gasLane = gasLane;
        i_subscriptionID = subID;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = LotteryState.OPEN;
        priceFeed = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
    }

    function enterLottery() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughETHEntered();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__NotOpen();
        }
        if (s_players.length >= 10) {
            revert Lottery__Full();
        }
        //Copy s_players to memory to save gas
        address payable[] memory l_players = s_players;
        for (uint256 i = 0; i < l_players.length; i++) {
            if (l_players[i] == payable(msg.sender)) {
                revert Lottery__AlreadyEntered("Lottery already entered");
            }
        }
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    function requestRandomWinner() external {
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__NotOpen();
        }
        if (s_players.length < 2) {
            revert Lottery__NotEnoughPlayers();
        }
        if (s_players.length > 10) {
            revert Lottery__Full();
        }

        s_lotteryState = LotteryState.CALCULATING;

        uint256 requestID = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionID,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedLotteryWinner(requestID);
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function linkToVRF(uint256 amount) public {
        LINKTOKEN.transferAndCall(address(i_vrfCoordinator), amount, abi.encode(i_subscriptionID));
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        address payable[] memory l_players = s_players;
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_lotteryState = LotteryState.OPEN;
        s_players = new address payable[](0);
        (bool success, ) = recentWinner.call{value: address(this).balance / 2}("");
        if (!success) {
            revert Lottery__TransfearFailed();
        }

        uint256 lesserPrize = address(this).balance / (l_players.length - 1);
        for (uint256 i = 0; i < l_players.length; i++) {
            if (l_players[i] != recentWinner) {
                (bool works, ) = l_players[i].call{value: lesserPrize}("");
                if (!works) {
                    revert Lottery__TransfearFailed();
                }
            }
        }
        emit WinnerPicked(recentWinner);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return s_players;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getSub()
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        )
    {
        return i_vrfCoordinator.getSubscription(i_subscriptionID);
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumberOfPlayer() public view returns (uint256) {
        return s_players.length;
    }
}