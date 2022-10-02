pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

//Rocket Raffle Contract

contract RocketRaffle is VRFConsumerBaseV2, Ownable {
    using SafeMath for uint256;
    VRFCoordinatorV2Interface COORDINATOR;

    //VRF values
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 callbackGasLimit = 1000000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint256 public s_requestId;

    //Game Values
    enum RAFFLE_STATE { OPEN, CLOSED, CALCULATING_WINNER }
    RAFFLE_STATE public raffle_state;
    address payable[] public players;
    uint256 public raffleId;
    uint public raffleStartDate;
    uint public raffleEndDate;
    uint256 ticketCostRKTN = 10_000 * 1e18;
    uint256 ticketCostRKFL = 100_000 * 1e18;
    uint256 MaxRaffleAmount = 5 *1e18;

    //Player info
    struct player{
        uint256 ticketsBought;
        uint256 gamesWon;
    }

    mapping(address => player) public playerStats;

    //events
    event RaffleOpen(uint256 _raffleId);
    event RaffleClose(uint256 _raffleId);
    event RaffleWinner(
        uint256 _raffleId,
        uint256 _randomness,
        uint256 _index,
        address indexed _from,
        uint256 _amount
    );
    event PlayerJoined(uint256 _raffleId, address indexed _from);
    event TicketsRewarded(address _address, uint256 _amountRewarded);

    //Rocket Token and Rocket Fuel
    IUniswapV2Router02 public immutable uniswapV2Router;
    IERC20 rocketToken;
    IERC20 rocketFuel;

    //modifier to check state of game
    modifier atState(RAFFLE_STATE _state) {
        require(raffle_state == _state, "Function cannot be called at this time.");
        _;
    }

    //constructor
    constructor(uint64 subscriptionId, address _rocketToken, address _rocketFuel) VRFConsumerBaseV2(vrfCoordinator) {

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uniswapV2Router = _uniswapV2Router;

    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
    raffleId = 1;
    raffle_state = RAFFLE_STATE.CLOSED;
    rocketToken  = IERC20(_rocketToken);
    rocketFuel = IERC20(_rocketFuel);

  }

  receive() external payable {}

    function setethRaffleMaxWin(uint256 _eth) public onlyOwner{
    require(_eth*1e18 > 1 *1e18, "max winner must be bigger than 1 eth");
    MaxRaffleAmount = _eth *1e18;
  }


  function setethRaffleTicketPriceRKTN(uint256 ticketPrice) public onlyOwner{
    uint256 totalSuypply = rocketToken.totalSupply();
    require(ticketPrice < ( totalSuypply* 5) / 1000, "Set a reasonable price ticket cost has to be lower then .5%");
    ticketCostRKTN = ticketPrice;
  }

    function setethRaffleTicketPriceRKFL(uint256 ticketPrice) public onlyOwner{
    uint256 totalSuypply = rocketFuel.totalSupply();
    require(ticketPrice < ( totalSuypply* 5) / 1000, "Set a reasonable price ticket cost has to be lower then .5%");
    ticketCostRKFL = ticketPrice;
  }

  function starRaffle() public onlyOwner {
    require(raffle_state == RAFFLE_STATE.CLOSED, "can't start a new raffle yet");
    players = new address payable[](0);
    raffleStartDate = block.timestamp;
    raffle_state = RAFFLE_STATE.OPEN;
    emit RaffleOpen(raffleId);
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

  function getTotalTicketsPurchased() public view returns(uint256 amountOfTickets){
        uint256 amount = players.length;
        return amount;
  }

    function getWinnings() public view returns(uint256 winnings){
      uint256 contractBalance = address(this).balance;
      if(contractBalance < MaxRaffleAmount){
        return (contractBalance / 2);
      }
      else {
        return MaxRaffleAmount;
      }
  }

  //calls chainlink vrf to select winner of raffle
  function PickWinner() public onlyOwner {
    require(raffle_state == RAFFLE_STATE.OPEN);
    raffle_state = RAFFLE_STATE.CALCULATING_WINNER;
    requestRandomWords();
  }

  //for upgrading raffle contract or emergency
  function Withdraw() public onlyOwner{
    bool success;
    (success, ) = address(msg.sender).call{value: address(this).balance}("");
  }

  //reward up to 10 raffle tickets 
  function rewardTickets(address _address, uint256 _amount) public onlyOwner {
    require(_amount <= 10, "cannot rewrd more than 10 tickets");

    for (uint i=1; i <= _amount; i++) {
        players.push(payable(_address));
        playerStats[_address].ticketsBought +=1;
    }

    emit TicketsRewarded(_address, _amount);

  }

//buy raffle tickets
 function buyTickets(uint256 numberOfTickets, uint256 _token) public payable atState(RAFFLE_STATE.OPEN) {
        require(_token == 0 || _token == 1, "invalid token selection");
        if(_token == 0){

          uint256 balance = rocketToken.balanceOf(msg.sender);
          uint256 amount = ticketCostRKTN * numberOfTickets;
          require(balance >= amount, "You must pay the proper amount for ticket");
          uint256 allowance = rocketToken.allowance(msg.sender, address(this));
          require(allowance >= amount, "Check token allowance");
          rocketToken.transferFrom(msg.sender, address(0xdead), amount);
        }
        else if(_token == 1){
          uint256 balance = rocketFuel.balanceOf(msg.sender);
          uint256 amount = ticketCostRKFL * numberOfTickets;
          require(balance >= amount, "You must pay the proper amount for ticket");
          uint256 allowance = rocketFuel.allowance(msg.sender, address(this));
          require(allowance >= amount, "Check token allowance");
          rocketFuel.transferFrom(msg.sender, address(0xdead), amount);
        }

        //add player and set info
        for (uint i=1; i <= numberOfTickets; i++) {
            players.push(payable(msg.sender));
            playerStats[msg.sender].ticketsBought +=1;
        }

        emit PlayerJoined(raffleId, msg.sender);
    }

  //buy back RKTN with 10% of raffle winnings
  function swapEthForTokens(address token, uint256 ethAmount) private {
        // generate the uniswap pair path of weth -> token
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = token;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function BuyBack() private{
      
      uint256 amount = getWinnings() * 10 / 100;
      swapEthForTokens(address(rocketToken), amount / 2);

      uint256 rocketTokenBalance = rocketToken.balanceOf(address(this));

      rocketToken.transfer(address(0xdead), rocketTokenBalance);

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
  
  //pays winner closes game and does buyback
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
      //pick winner
      uint256 index = randomWords[0] % players.length;
      uint256 winnings = getWinnings() * 90 / 100;
      BuyBack();
      address winner = players[index];
      //pay winner
       bool success;
      (success, ) = address(winner).call{value: winnings}("");

      raffle_state = RAFFLE_STATE.CLOSED;
      
      emit RaffleWinner(raffleId, randomWords[0], index, winner, winnings);
      emit RaffleClose(raffleId);

      raffleId = raffleId + 1;

    }
}