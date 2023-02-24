// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./VRFv2Consumer.sol";

import "./interfaces/ISicboNFT.sol";
import "./libraries/Lib.sol";

contract Sicbo is
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable
{
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using AddressUpgradeable for address;

  struct NftHolder {
    uint256 amount;
    uint256 depositRound;
    uint256 accuReward; // Reward debt. See explanation below.
  }
  // If listing existed, seller must != address(0)
  struct Round {
    uint256 holderReceiveAmountPerNft;
    uint256 totalFeeAmount;
  }

  address public gameToken;
  address public devAddress;
  uint256 public devAccAmount;

  uint256 public currentRoundIndex; // round time = 1 day
  uint256 public feePercent; //  * 10, is float number
  uint256[] public prices;

  ISicboNFT public sicboContract;
  VRFv2Consumer public vrfConsumer;

  mapping(uint256 => Round) public rounds;
  mapping(address => NftHolder) public nftHolders;

  event Play(
    address indexed buyer,
    bool predict,
    uint256 betAmount,
    uint256 reward,
    bool result
  );
  event Claim(address indexed user, uint256 reward);

  uint256 public maxAmountPerUser;
  uint256 public soldLimit;
  uint256 public nftPrice;
  uint256 public soldAmount;
  mapping(address => uint256) public amountBought;

  event INO(address buyer, uint256 amount, uint256[] tokenIds);

  receive() external payable {}

  fallback() external payable {}

  modifier onlyNftContract() {
    require(address(sicboContract) == msg.sender, "not nft contract");
    _;
  }

  function initialize(ISicboNFT _sicboContract, VRFv2Consumer _vrfConsumer)
    public
    initializer
  {
    __ReentrancyGuard_init_unchained();
    __Context_init_unchained();
    __Ownable_init_unchained();
    __Pausable_init_unchained();

    sicboContract = _sicboContract;
    vrfConsumer = _vrfConsumer;
    devAddress = msg.sender;
    feePercent = 35;

    currentRoundIndex = 1;

    maxAmountPerUser = 2;
    soldLimit = 888;
    nftPrice = 0.001 ether;
  }

  function configSold(
    uint256 _maxPerUser,
    uint256 _limit,
    uint256 _price
  ) external onlyOwner {
    maxAmountPerUser = _maxPerUser;
    soldLimit = _limit;
    nftPrice = _price;
  }

  function buyNft(uint256 amount) external payable {
    require(
      amountBought[msg.sender] + amount <= maxAmountPerUser,
      "reach limit"
    );
    require(soldAmount + amount <= soldLimit, "out of stock");

    executeFundsTransfer(msg.sender, address(this), nftPrice * amount);

    uint256[] memory tokenIds = sicboContract.mintBatch(msg.sender, amount);

    soldAmount += amount;
    amountBought[msg.sender] += amount;

    emit INO(msg.sender, amount, tokenIds);
  }

  function setNftContract(ISicboNFT _sicboContract) external onlyOwner {
    sicboContract = _sicboContract;
  }

  function setPrices(uint256[] memory _prices) external onlyOwner {
    prices = _prices;
  }

  function setFeePercent(uint256 _feePercent) external onlyOwner {
    feePercent = _feePercent;
  }

  function getRewardBetweenTwoRound(uint256 depositRound)
    public
    view
    returns (uint256)
  {
    if (depositRound == currentRoundIndex) return 0;
    return
      rounds[currentRoundIndex - 1].holderReceiveAmountPerNft -
      rounds[depositRound].holderReceiveAmountPerNft;
  }

  function getCurrentTotalFeeAmount() external view returns (uint256) {
    return rounds[currentRoundIndex].totalFeeAmount;
  }

  function getSicboResult() internal view returns (bool) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            vrfConsumer.s_randomWords(0),
            block.timestamp,
            block.number,
            block.difficulty,
            address(this).balance,
            "1231232"
          )
        )
      ) %
        2 ==
      1;
    // return true;
  }

  function getReward(address holder) public view returns (uint256 reward) {
    NftHolder memory nftHolder = nftHolders[holder];

    reward =
      nftHolder.accuReward +
      nftHolder.amount *
      getRewardBetweenTwoRound(nftHolder.depositRound);
  }

  // withdraw staking
  function tranferNftHolder(address from, address to) external onlyNftContract {
    NftHolder storage fromNftHolder = nftHolders[from];
    NftHolder storage toNftHolder = nftHolders[to];

    if (from == address(0)) {
      toNftHolder.accuReward +=
        toNftHolder.amount *
        getRewardBetweenTwoRound(toNftHolder.depositRound);

      toNftHolder.depositRound = currentRoundIndex - 1;
      toNftHolder.amount++;
    } else if (to == address(0)) {
      fromNftHolder.accuReward +=
        fromNftHolder.amount *
        getRewardBetweenTwoRound(fromNftHolder.depositRound);
      fromNftHolder.depositRound = currentRoundIndex - 1;
      fromNftHolder.amount--;
    } else {
      fromNftHolder.accuReward +=
        fromNftHolder.amount *
        getRewardBetweenTwoRound(fromNftHolder.depositRound);
      toNftHolder.accuReward +=
        toNftHolder.amount *
        getRewardBetweenTwoRound(toNftHolder.depositRound);

      fromNftHolder.depositRound = currentRoundIndex - 1;
      toNftHolder.depositRound = currentRoundIndex - 1;

      fromNftHolder.amount--;
      toNftHolder.amount++;
    }
  }

  function play(bool predict, uint256 priceMark)
    external
    payable
    nonReentrant
    whenNotPaused
  {
    require(priceMark < prices.length, "out of prices");
    uint256 price = prices[priceMark];
    require(msg.value == price, "pay not enough");
    bool result = getSicboResult();
    uint256 reward;
    if (result == predict) {
      reward = (price * (1000 - feePercent)) / 1000;
      executeFundsTransfer(address(this), _msgSender(), reward + price);
    }

    uint256 hoolderReward = (price * feePercent) / 1000;

    rounds[currentRoundIndex].totalFeeAmount += hoolderReward;

    emit Play(msg.sender, predict, price, reward, result == predict);
  }

  function claim() external nonReentrant whenNotPaused {
    NftHolder storage nftHolder = nftHolders[msg.sender];

    uint256 reward = getReward(msg.sender);
    require(reward > 0, "empty reward");

    executeFundsTransfer(address(this), _msgSender(), reward);

    nftHolder.accuReward = 0;
    nftHolder.depositRound = currentRoundIndex - 1;

    emit Claim(msg.sender, reward);
  }


  function endRound(uint256 holderReceivedPercent) external onlyOwner {
    uint256 devAmount = (rounds[currentRoundIndex].totalFeeAmount *
      (feePercent - holderReceivedPercent)) / feePercent;
    devAccAmount += devAmount;

    rounds[currentRoundIndex].holderReceiveAmountPerNft =
      rounds[currentRoundIndex - 1].holderReceiveAmountPerNft +
      (rounds[currentRoundIndex].totalFeeAmount - devAmount) /
      (sicboContract.nextTokenId() - 1);

    currentRoundIndex++;
  }

  function executeFundsTransfer(
    address sender,
    address receiver,
    uint256 amount
  ) internal virtual {
    require(address(sender).balance >= amount, "Not enough native coin");

    if (receiver != address(this)) {
      (bool sendToSeller, bytes memory data) = payable(receiver).call{
        value: amount
      }("");
      require(sendToSeller, "Failed to send BNB to seller");
    }
  }
}