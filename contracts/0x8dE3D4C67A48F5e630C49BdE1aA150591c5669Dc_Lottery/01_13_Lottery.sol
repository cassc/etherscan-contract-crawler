pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

//Lottery Inu Lottery Contract.

contract Lottery is VRFConsumerBaseV2, Ownable {
    using SafeMath for uint256;
    VRFCoordinatorV2Interface COORDINATOR;

    //VRF values
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 callbackGasLimit = 600000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint256 public s_requestId;

    //Game Values
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING_WINNER }
    LOTTERY_STATE public lottery_state;
    address payable[] public players;
    uint256 public lotteryId;
    uint public lotteryStartDate;
    uint public lotteryEndDate;
    uint256 ticketCost = 100 * 1e18;

    //Player info
    struct player{
        uint256 ticketsBought;
        uint256 gamesWon;
    }

    mapping(address => player) public playerStats;

    //events
    event LotteryOpen(uint256 _lotteryId);
    event LotteryClose(uint256 _lotteryId);
    event LotteryWinner(
        uint256 _lotteryId,
        uint256 _randomness,
        uint256 _index,
        address indexed _from,
        uint256 _amount
    );
    event PlayerJoined(uint256 _lotteryId, address indexed _from);

    //Lottery Inu Token
    IERC20 lottoToken;

    //modifier to check state of game
    modifier atState(LOTTERY_STATE _state) {
        require(lottery_state == _state, "Function cannot be called at this time.");
        _;
    }

    //constructor
    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
    lotteryId = 1;
    lottery_state = LOTTERY_STATE.CLOSED;
  }

  receive() external payable {}

  function UpdateTokenUsedToPay(address token) public onlyOwner{
    lottoToken = IERC20(token);
  }

  function setLotteryTicketPrice(uint256 ticketPrice) public onlyOwner{
    uint256 totalSuypply = lottoToken.totalSupply();
    require(ticketPrice < ( totalSuypply* 5) / 1000, "Set a reasonable price ticket cost has to be lower then .5%");
    ticketCost = ticketPrice;
  }

  function startLottery() public onlyOwner {
    require(lottery_state == LOTTERY_STATE.CLOSED, "can't start a new lottery yet");
    players = new address payable[](0);
    lotteryStartDate = block.timestamp;
    lottery_state = LOTTERY_STATE.OPEN;
    emit LotteryOpen(lotteryId);
  }

  function getAmountOfTicketsOwned(address _address) public view returns(uint256 amountOfTickets){
        uint256 amount = players.length;
        uint256 tickets = 0;
        for (uint i=0; i < amount; i++) {
          if(players[i] == _address){
            tickets += 1;
          }
        }

        return tickets;
  }

  function PickWinner() public onlyOwner {
    require(lottery_state == LOTTERY_STATE.OPEN);
    lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
    requestRandomWords();
  }

  function Withdraw() public onlyOwner{
    bool success;
    (success, ) = address(msg.sender).call{value: address(this).balance}("");
  }

  function buyTicket() public payable atState(LOTTERY_STATE.OPEN) {
        uint256 balance = lottoToken.balanceOf(msg.sender);
        require(balance >= ticketCost, "You must pay the proper amount for ticket");
        uint256 allowance = lottoToken.allowance(msg.sender, address(this));
        require(allowance >= ticketCost, "Check token allowance");

        lottoToken.transferFrom(msg.sender, address(0xdead), ticketCost);

        //add player and set info
        players.push(payable(msg.sender));
        playerStats[msg.sender].ticketsBought +=1;
        emit PlayerJoined(lotteryId, msg.sender);
    }

 function buyTickets(uint256 numberOfTickets) public payable atState(LOTTERY_STATE.OPEN) {
        uint256 balance = lottoToken.balanceOf(msg.sender);
        uint256 amount = ticketCost * numberOfTickets;
        require(balance >= amount, "You must pay the proper amount for ticket");
        uint256 allowance = lottoToken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check token allowance");

        lottoToken.transferFrom(msg.sender, address(0xdead), amount);

        //add player and set info
        for (uint i=1; i <= numberOfTickets; i++) {
            players.push(payable(msg.sender));
            playerStats[msg.sender].ticketsBought +=1;
        }

        emit PlayerJoined(lotteryId, msg.sender);
    }



    //gets random number
    function requestRandomWords() private {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
      //pick winner
      uint256 index = randomWords[0] % players.length;
      uint256 winnings = address(this).balance / 2;
      address winner = players[index];
      //pay winner
       bool success;
      (success, ) = address(winner).call{value: winnings}("");

      lottery_state = LOTTERY_STATE.CLOSED;
      
      emit LotteryWinner(lotteryId, randomWords[0], index, winner, winnings);
      emit LotteryClose(lotteryId);

      lotteryId = lotteryId + 1;

    }
}