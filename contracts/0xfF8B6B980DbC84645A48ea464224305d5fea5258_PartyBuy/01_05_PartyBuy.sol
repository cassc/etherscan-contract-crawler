// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

contract PartyBuy is Ownable, Pausable, ReentrancyGuard {
  string public constant VERSION = "1.0.0";

  event CreatePlan(uint256 indexed planIndex);

  event Own(uint256 indexed planIndex, address indexed account, uint256 amount, string email);

  struct PartyBuyPlan {
    address payable receiverWallet;
    uint48 totalAmount;
    uint48 amount;
    uint256 price;
    /// @notice startTime unit second
    /// @return startTime unit second
    uint64 startTime;
    /// @notice endTime unit second
    /// @return endTime unit second
    uint64 endTime;
    address[] ownerArr;
    mapping(address => uint48) amountByAddressMapping;
  }

  uint256 public totalPlan;

  mapping(uint256 => PartyBuyPlan) private _partyBuyPlans;

  constructor() {}

  /************************
   * @dev for pause
   */

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /********************
   *
   */

  /// @notice Create new party buy plan
  /// @dev Explain to a developer any extra details
  /// @param receiverWallet_ :
  function createPlan(
    address payable receiverWallet_,
    uint48 totalAmount_,
    uint256 price_,
    uint64 startTime_,
    uint64 endTime_
  ) external onlyOwner {
    require(receiverWallet_ != address(0));

    uint256 currentPlanIndex = totalPlan;

    _partyBuyPlans[currentPlanIndex].receiverWallet = receiverWallet_;
    _partyBuyPlans[currentPlanIndex].totalAmount = totalAmount_;
    _partyBuyPlans[currentPlanIndex].amount = totalAmount_;
    _partyBuyPlans[currentPlanIndex].price = price_;
    _partyBuyPlans[currentPlanIndex].startTime = startTime_;
    _partyBuyPlans[currentPlanIndex].endTime = endTime_;

    totalPlan += 1;

    emit CreatePlan(currentPlanIndex);
  }

  function updatePlanTime(
    uint256 planIndex,
    uint64 startTime_,
    uint64 endTime_
  ) external onlyOwner {
    require(planIndex < totalPlan, "Plan is not existed");

    _partyBuyPlans[planIndex].startTime = startTime_;
    _partyBuyPlans[planIndex].endTime = endTime_;
  }

  function updatePlanReceiverWallet(uint256 planIndex, address payable receiverWallet_) external onlyOwner {
    require(planIndex < totalPlan, "Plan is not existed");
    require(receiverWallet_ != address(0));

    _partyBuyPlans[planIndex].receiverWallet = receiverWallet_;
  }

  function getPlanInfo(uint256 planIndex)
    external
    view
    returns (
      address receiverWallet,
      uint48 totalAmount,
      uint48 amount,
      uint256 price,
      uint64 startTime,
      uint64 endTime,
      uint256 totalOwner
    )
  {
    require(planIndex < totalPlan, "Plan is not existed");
    receiverWallet = _partyBuyPlans[planIndex].receiverWallet;
    totalAmount = _partyBuyPlans[planIndex].totalAmount;
    amount = _partyBuyPlans[planIndex].amount;
    price = _partyBuyPlans[planIndex].price;
    startTime = _partyBuyPlans[planIndex].startTime;
    endTime = _partyBuyPlans[planIndex].endTime;
    totalOwner = _partyBuyPlans[planIndex].ownerArr.length;
  }

  function getOwnersOfPlan(
    uint256 planIndex,
    uint256 skip,
    uint256 limit
  ) external view returns (address[] memory ownerArr, uint48[] memory ownAmountArr) {
    require(planIndex < totalPlan, "Plan is not existed");

    uint256 totalOwner = _partyBuyPlans[planIndex].ownerArr.length;
    uint256 endIndex = totalOwner;
    if (limit > 0 && (skip + limit) < endIndex) {
      endIndex = skip + limit;
    }

    ownerArr = new address[](endIndex - skip);
    ownAmountArr = new uint48[](endIndex - skip);

    for (uint256 index = skip; index < endIndex; index++) {
      ownerArr[index - skip] = _partyBuyPlans[planIndex].ownerArr[index];
      address currentOwner = ownerArr[index - skip];
      ownAmountArr[index - skip] = _partyBuyPlans[planIndex].amountByAddressMapping[currentOwner];
    }
  }

  function getAmountOfOwner(uint256 planIndex, address ownerAddress) external view returns (uint48) {
    require(planIndex < totalPlan, "Plan is not existed");
    return _partyBuyPlans[planIndex].amountByAddressMapping[ownerAddress];
  }

  /// @notice User buy amount in plan
  /// @param planIndex (unit256) :
  /// @param amount (uin48) :
  /// @param email (string) :
  function buy(
    uint256 planIndex,
    uint48 amount,
    string memory email
  ) external payable nonReentrant whenNotPaused {
    require(planIndex < totalPlan, "Plan is not existed");
    require(
      block.timestamp >= _partyBuyPlans[planIndex].startTime && block.timestamp <= _partyBuyPlans[planIndex].endTime,
      "Not active"
    );
    require(amount > 0, "Amount must greater than 0");
    require(amount <= _partyBuyPlans[planIndex].amount, "Do not have enough amount left");
    require(msg.value == (_partyBuyPlans[planIndex].price * amount), "Money is not correct");

    uint48 currentOwn = _partyBuyPlans[planIndex].amountByAddressMapping[msg.sender];

    if (currentOwn == 0) {
      _partyBuyPlans[planIndex].ownerArr.push(msg.sender);
    }

    _partyBuyPlans[planIndex].amountByAddressMapping[msg.sender] += amount;
    _partyBuyPlans[planIndex].amount -= amount;

    // emit event
    emit Own(planIndex, msg.sender, _partyBuyPlans[planIndex].amountByAddressMapping[msg.sender], email);

    // transfer balance to tkxWallet
    // solhint-disable-next-line avoid-low-level-calls
    (bool sent, ) = payable(_partyBuyPlans[planIndex].receiverWallet).call{value: msg.value}("");
    require(sent, "Failed to send Ether");
  }
}