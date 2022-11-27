// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';

import './Drawing.sol';
import './TicketIndex.sol';
import './TicketSet.sol';
import './UserTickets.sol';


// This is in USD cents, so it's $1.50
uint constant BASE_TICKET_PRICE_USD = 150;

// ChainLink USD price feed (8 decimals)
address constant USD_PRICE_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

// Width of the weekly drawing window.
uint constant DRAWING_WINDOW_WIDTH = 4 hours;


contract Lottery is UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable,
    PullPaymentUpgradeable, ReentrancyGuardUpgradeable
{
  using AddressUpgradeable for address payable;
  using UserTickets for TicketData[];
  using TicketSet for uint64[];
  using TicketIndex for uint64[][90];

  enum State {OPEN, DRAWING, DRAWN, CLOSING}

  VRFCoordinatorV2Interface private _vrfCoordinator;

  uint256 public baseTicketPrice;

  uint64 public nextTicketId;
  uint64 public currentRound;

  State public state;
  uint public nextDrawTime;

  mapping (address => TicketData[]) public ticketsByPlayer;

  address payable[] public playersByTicket;
  uint64[][90][] public ticketsByNumber;
  DrawData[] public draws;

  event NewTicketPrice(uint indexed round, uint256 price);
  event Ticket(uint indexed round, address indexed player, uint8[] numbers);
  event VRFRequest(uint indexed round, uint256 requestId);
  event Draw(uint indexed round, uint8[6] numbers, uint256 currentBalance);
  event CloseRound(uint indexed round, uint256 currentBalance);

  // Accept funds from ICO and possibly other sources in the future.
  receive() external payable {}

  function initialize(address vrfCoordinator) public initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
    __Pausable_init();
    __PullPayment_init();
    __ReentrancyGuard_init();
    _vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
    _updateTicketPrice();
    nextTicketId = 0;
    currentRound = 0;
    ticketsByNumber.push();
    draws.push();
    state = State.OPEN;
    nextDrawTime = Drawing.nextDrawTime();
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function _updateTicketPrice() private {
    AggregatorV3Interface priceFeed = AggregatorV3Interface(USD_PRICE_FEED);
    (, int256 price, , , ) = priceFeed.latestRoundData();
    baseTicketPrice = BASE_TICKET_PRICE_USD *
        uint256(10 ** (16 + priceFeed.decimals())) / uint256(price);
    emit NewTicketPrice(currentRound, baseTicketPrice);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function getTicketPrice(uint8[] calldata playerNumbers) public view returns (uint256) {
    require(state == State.OPEN, 'please wait for the next round');
    require(playerNumbers.length >= 6, 'too few numbers');
    require(playerNumbers.length <= 90, 'too many numbers');
    for (uint i = 0; i < playerNumbers.length; i++) {
      require(playerNumbers[i] > 0 && playerNumbers[i] <= 90, 'invalid numbers');
      for (uint j = i + 1; j < playerNumbers.length; j++) {
        require(playerNumbers[i] != playerNumbers[j], 'duplicate numbers');
      }
    }
    return baseTicketPrice * Drawing.choose(playerNumbers.length, 6);
  }

  function buyTicket(uint8[] calldata playerNumbers) public payable whenNotPaused nonReentrant {
    uint256 ticketPrice = getTicketPrice(playerNumbers);
    require(msg.value == ticketPrice, 'incorrect value, please check the price of your ticket');
    uint64 ticketId = nextTicketId++;
    ticketsByPlayer[msg.sender].push(TicketData({
      id: ticketId,
      round: currentRound,
      timestamp: uint64(block.timestamp),
      cardinality: uint64(playerNumbers.length)
    }));
    playersByTicket.push(payable(msg.sender));
    for (uint i = 0; i < playerNumbers.length; i++) {
      ticketsByNumber[currentRound][playerNumbers[i] - 1].push(ticketId);
    }
    emit Ticket(currentRound, msg.sender, playerNumbers);
    payable(owner()).sendValue(msg.value / 10);
  }

  function getTickets(address player, uint64 round) public view returns (uint64[] memory ids) {
    return ticketsByPlayer[player].getTickets(round);
  }

  function getTicket(uint64 round, uint64 ticketId)
      public view returns (address player, uint256 timestamp, uint8[] memory numbers)
  {
    player = playersByTicket[ticketId];
    require(player != address(0), 'invalid ticket');
    TicketData storage ticket = ticketsByPlayer[player].getTicket(ticketId);
    timestamp = ticket.timestamp;
    uint8[90] memory temp;
    uint count = 0;
    for (uint8 number = 0; number < 90; number++) {
      if (ticketsByNumber[round][number].contains(ticketId)) {
        temp[count++] = number + 1;
      }
    }
    numbers = new uint8[](count);
    for (uint i = 0; i < count; i++) {
      numbers[i] = temp[i];
    }
  }

  function canDraw() public view returns (bool) {
    if (block.timestamp < nextDrawTime) {
      return false;
    } else {
      return block.timestamp < Drawing.getCurrentDrawingWindow() + DRAWING_WINDOW_WIDTH;
    }
  }

  function draw(uint64 vrfSubscriptionId, bytes32 vrfKeyHash, uint32 callbackGasLimit)
      public onlyOwner
  {
    require(state == State.OPEN, 'invalid state');
    require(canDraw(), 'the next drawing window has not started yet');
    state = State.DRAWING;
    nextDrawTime += 7 days;
    uint256 vrfRequestId = _vrfCoordinator.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        /*requestConfirmations=*/10,
        callbackGasLimit,
        /*numWords=*/1);
    emit VRFRequest(currentRound, vrfRequestId);
  }

  function rawFulfillRandomWords(uint256, uint256[] memory randomWords) external whenNotPaused {
    require(msg.sender == address(_vrfCoordinator), 'permission denied');
    require(state == State.DRAWING, 'invalid state');
    draws[currentRound].numbers = Drawing.sortNumbersByTicketCount(
        ticketsByNumber[currentRound],
        Drawing.getRandomNumbersWithoutRepetitions(randomWords[0]));
    state = State.DRAWN;
    emit Draw(currentRound, draws[currentRound].numbers, address(this).balance);
  }

  function getDrawData(uint64 round)
      public view returns (uint256 blockNumber, uint8[6] memory numbers, uint64[][5] memory winners)
  {
    require(round < draws.length, 'invalid round number');
    require(round < draws.length - 1 || state > State.DRAWING, 'invalid state');
    DrawData storage data = draws[round];
    return (data.blockNumber, data.numbers, data.winners);
  }

  function findWinners() public onlyOwner {
    require(state == State.DRAWN, 'please call draw() first');
    draws[currentRound].winners = ticketsByNumber[currentRound].findWinningTickets(
        draws[currentRound].numbers);
    state = State.CLOSING;
  }

  function _getTicket(uint64 id) private view returns (TicketData storage) {
    return ticketsByPlayer[playersByTicket[id]].getTicket(id);
  }

  function _calculatePrizes(uint64[][5] storage winners) private view returns (PrizeData[] memory) {
    PrizeData[][5] memory prizes;
    uint count = 0;
    for (int i = 4; i >= 0; i--) {
      count += winners[uint(i)].length;
      prizes[uint(i)] = new PrizeData[](count);
    }
    uint offset = 0;
    for (int i = 4; i >= 0; i--) {
      uint ui = uint(i);
      uint maxMatches = ui + 2;
      for (uint j = 0; j < winners[ui].length; j++) {
        TicketData storage ticket = _getTicket(winners[ui][j]);
        for (int k = i; k >= 0; k--) {
          uint matches = uint(k) + 2;
          prizes[ui][offset + j] = PrizeData({
            ticket: winners[ui][j],
            prize: Drawing.choose(maxMatches, matches) *
                Drawing.choose(ticket.cardinality - maxMatches, 6 - matches)
          });
        }
      }
      offset += winners[ui].length;
    }
    uint256 jackpot = address(this).balance;
    for (uint i = 0; i < prizes.length; i++) {
      uint totalWeight = 0;
      for (uint j = 0; j < prizes[i].length; j++) {
        totalWeight += prizes[i][j].prize;
      }
      if (totalWeight > 0) {
        for (uint j = 0; j < prizes[i].length; j++) {
          uint weight = prizes[i][j].prize;
          prizes[i][j].prize = jackpot * weight * 18 / (totalWeight * 100);
        }
      } else {
        for (uint j = 0; j < prizes[i].length; j++) {
          prizes[i][j].prize = 0;
        }
      }
    }
    for (uint i = prizes.length - 1; i > 0; i--) {
      for (uint j = 0; j < prizes[i].length; j++) {
        prizes[0][j].prize += prizes[i][j].prize;
      }
    }
    return prizes[0];
  }

  function _reset() private {
    currentRound++;
    ticketsByNumber.push();
    draws.push();
    state = State.OPEN;
    _updateTicketPrice();
  }

  function closeRound() public onlyOwner {
    require(state == State.CLOSING, 'please call findWinners() first');
    uint256 jackpot = address(this).balance;
    PrizeData[] memory prizes = _calculatePrizes(draws[currentRound].winners);
    for (uint i = 0; i < prizes.length; i++) {
      _asyncTransfer(playersByTicket[prizes[i].ticket], prizes[i].prize);
    }
    emit CloseRound(currentRound, jackpot);
    delete prizes;
    _reset();
  }
}