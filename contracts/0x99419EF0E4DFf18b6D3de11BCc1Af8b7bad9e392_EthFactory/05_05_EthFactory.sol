// SPDX-License-Identifier: MIT

/**
 *
 * ███████╗████████╗██╗  ██╗
 * ██╔════╝╚══██╔══╝██║  ██║
 * █████╗     ██║   ███████║
 * ██╔══╝     ██║   ██╔══██║
 * ███████╗   ██║   ██║  ██║
 * ╚══════╝   ╚═╝   ╚═╝  ╚═╝
 *
 * ███████╗ █████╗  █████╗ ████████╗ █████╗ ██████╗ ██╗   ██╗
 * ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗╚██╗ ██╔╝
 * █████╗  ███████║██║  ╚═╝   ██║   ██║  ██║██████╔╝ ╚████╔╝
 * ██╔══╝  ██╔══██║██║  ██╗   ██║   ██║  ██║██╔══██╗  ╚██╔╝
 * ██║     ██║  ██║╚█████╔╝   ██║   ╚█████╔╝██║  ██║   ██║
 * ╚═╝     ╚═╝  ╚═╝ ╚════╝    ╚═╝    ╚════╝ ╚═╝  ╚═╝   ╚═╝
 *
 */

/**
 * @title A mining contract used for compounding rewards.
 * @notice This contract allows users to create credits with ETH. Credits are then converted into miners which in turn creates more credits. Users may then either cash out credits
 * created by the miners or reinvest to create more credits and compound their returns. Participants may use referral codes to generate credits from other participants depositing funds
 * using their referral address.
 */

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IEthPowerups {
  function calcNftMultiplier(address _address) external view returns (uint);
}

interface IEthFactory {
  function getLastCreated(address _address) external view returns (uint);
}

contract EthFactory is Ownable, ReentrancyGuard {
  constructor(address _feeReceiver, address nftAddress) {
    feeReceiver = payable(_feeReceiver);
    INFT = IEthPowerups(nftAddress);
  }

  receive() external payable {}

  /*|| === STATE VARIABLES === ||*/
  uint private marketValue;
  uint private constant CREDITS_PER_1_MINER = 1080000; /// credits needed to create one miner
  uint public depositFee = 4;
  uint public withdrawFee = 4;
  uint public refPercent = 8;
  uint public minDeposit = 0.05 ether; /// Minimum eth a wallet can deposit
  uint public startingMax = 1 ether; /// Minimum max deposit
  uint public maxInterval = 1 ether; /// Increase by when new step is hit
  uint public stepInterval = 10 ether; /// Step length between each interval
  IEthPowerups public INFT;
  address payable public feeReceiver;
  bool private initialized = false;

  /*|| === MAPPINGS === ||*/
  mapping(address => uint) private createdMiners; /// Miners are used to generate credits
  mapping(address => uint) private claimedCredits; /// credits generated from purchasing and referrals
  mapping(address => uint) private lastCreation; /// Latest timestamp credits were created
  mapping(address => address) public referral; /// Referral address code bound to deposit address
  mapping(address => uint) public investedEth; /// WEI a single wallet has deposited

  /*|| === EXTERNAL FUNCTIONS === ||*/

  function setDepositFee(uint _depositFee) external onlyOwner {
    require(_depositFee < 6, "Too high");
    depositFee = _depositFee;
  }

  function setWithdrawFee(uint _withdrawFee) external onlyOwner {
    require(_withdrawFee < 6, "Too high");
    withdrawFee = _withdrawFee;
  }

  function setRefPercent(uint _refPercent) external onlyOwner {
    require(_refPercent < 20, "Too high");
    refPercent = _refPercent;
  }

  function setMinDeposit(uint _minDeposit) external onlyOwner {
    minDeposit = _minDeposit;
  }

  function setStartingMax(uint _startingMax) external onlyOwner {
    startingMax = _startingMax;
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function setMaxInterval(uint _maxInterval) external onlyOwner {
    maxInterval = _maxInterval;
  }

  function setStepInterval(uint _stepInterval) external onlyOwner {
    stepInterval = _stepInterval;
  }

  function setFeeReceiver(address _feeReceiver) external onlyOwner {
    feeReceiver = payable(_feeReceiver);
  }

  function setNftContract(address _address) external onlyOwner {
    INFT = IEthPowerups(_address);
  }

  function ethRewards(address _address) external view returns (uint) {
    uint credits = getMyCredits(_address);
    uint rewards = calculateRewards(credits);
    return rewards;
  }

  function getMyMiners(address _address) external view returns (uint) {
    return createdMiners[_address];
  }

  function getLastCreated(address _address) external view returns (uint) {
    return lastCreation[_address];
  }

  /*|| === PUBLIC FUNCTIONS === ||*/
  function startFactory() public payable onlyOwner {
    require(marketValue == 0);
    initialized = true;
    marketValue = 108000000000;
  }

  function buyMiners(address ref) public payable {
    require(initialized);
    if (address(this).balance < 100 ether) {
      uint maxDeposit = (address(this).balance / stepInterval) * maxInterval + startingMax;
      require(msg.value + investedEth[msg.sender] <= maxDeposit, "Max deposit");
    }
    require(msg.value + investedEth[msg.sender] >= minDeposit, "Min deposit");

    investedEth[msg.sender] += msg.value;

    /// Calculate miners bought
    uint creditsBought = calculateCredits(msg.value, address(this).balance - msg.value);
    /// Subtract miners bought from deposit fee
    creditsBought -= Math.mulDiv(creditsBought, depositFee, 100);
    /// Calculate fee in WEI and send to the receiver address
    uint fee = Math.mulDiv(msg.value, depositFee, 100);
    feeReceiver.transfer(fee);
    /// Add miners bought to claimed miners to prepare to activate
    claimedCredits[msg.sender] += creditsBought;
    createMiners(ref);
  }

  function createMiners(address ref) public {
    require(initialized);

    if (ref == msg.sender) {
      ref = feeReceiver;
    }

    if (referral[msg.sender] == address(0) && referral[msg.sender] != msg.sender) {
      referral[msg.sender] = ref;
    }

    uint credits = getMyCredits(msg.sender);
    /// Create miners from credits generated and bought
    uint newMiners = credits / CREDITS_PER_1_MINER;
    /// Add created miners to mapping
    createdMiners[msg.sender] += newMiners;
    /// Reset claimed credits
    claimedCredits[msg.sender] = 0;
    /// Reset last created time
    lastCreation[msg.sender] = block.timestamp;
    /// Send profit to referral address
    claimedCredits[referral[msg.sender]] += Math.mulDiv(credits, refPercent, 100);
    /// Boost market to nerf miners hoarding
    marketValue = marketValue + (credits / (5));
  }

  function claimRewards() public nonReentrant {
    require(initialized);
    /// Get current credits
    uint credits = getMyCredits(msg.sender);
    /// Get rewards generated
    uint rewards = calculateRewards(credits);
    require(rewards > 0, "No rewards");
    /// Calculate withdraw fees
    uint fee = Math.mulDiv(rewards, withdrawFee, 100);
    /// Reset claimed credits
    claimedCredits[msg.sender] = 0;
    /// Reset last created time
    lastCreation[msg.sender] = block.timestamp;
    /// Increase market value by the number of credits sold
    marketValue += credits;
    /// Transfer withdraw fee to fee receiver
    feeReceiver.transfer(fee);
    payable(msg.sender).transfer(rewards - fee);
  }

  function calculateRewards(uint rewards) public view returns (uint) {
    return calculateTrade(rewards, marketValue, address(this).balance);
  }

  function calculateCredits(uint eth, uint contractBalance) public view returns (uint) {
    return calculateTrade(eth, contractBalance, marketValue);
  }

  function calculateCreditsSimple(uint eth) public view returns (uint) {
    return calculateCredits(eth, address(this).balance);
  }

  function getMyCredits(address _address) public view returns (uint) {
    uint createdCredits = getCreditsSinceLastCreation(_address);
    return claimedCredits[_address] + createdCredits + Math.mulDiv(createdCredits, INFT.calcNftMultiplier(_address), 100);
  }

  function getCreditsSinceLastCreation(address _address) public view returns (uint) {
    uint secondsPassed = calculateMin(CREDITS_PER_1_MINER, (block.timestamp - lastCreation[_address]));
    return secondsPassed * createdMiners[_address];
  }

  /*|| === PRIVATE FUNCTIONS === ||*/
  function calculateTrade(uint x, uint y, uint z) private pure returns (uint) {
    return (10000 * z) / (5000 + (((10000 * y) + (5000 * x)) / x));
  }

  function calculateMin(uint a, uint b) private pure returns (uint) {
    return a < b ? a : b;
  }
}