// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

contract POAPSale is Pausable {
  using Counters for Counters.Counter;

  address immutable public admin;
  address immutable public deployer;
  address payable immutable public fundsReceiver;
  uint256 immutable public dropId;
  uint256 immutable public price;
  uint256 immutable public quantity;
  uint256 immutable public startTimestamp;
  uint256 immutable public endTimestamp;

  bool public finished;

  Counters.Counter private _received;
  address[] public buyers;
  mapping(address => bool) private _buyers;

  uint256 public rejectedCount;
  address[] public rejected;
  mapping(address => bool) private _rejected;
  mapping(address => bool) private _refunded;
  mapping(address => bool) private _finished;

  event Sold(address indexed buyer, uint256 indexed position);
  event Buyer(address indexed buyer, uint8 indexed accepted);
  event SaleFinished(uint256 indexed earned, uint256 indexed refunded);
  event Refunded(address indexed target);

  constructor(
    address _admin,
    address payable _deployer,
    address payable _fundsReceiver,
    uint256 _dropId,
    uint256 _price,
    uint256 _quantity,
    uint256 _startTimestamp,
    uint256 _endTimestamp
  ) {
    admin = _admin;
    deployer = _deployer;
    fundsReceiver = _fundsReceiver;
    dropId = _dropId;
    price = _price;
    quantity = _quantity;
    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
  }

  function pause() public {
    require(msg.sender == admin, "POAPSale: not admin");
    _pause();
  }

  function unpause() public {
    require(msg.sender == admin, "POAPSale: not admin");
    _unpause();
  }

  function received() public view returns (uint256) {
    return _received.current();
  }

  function isRefunded(address target) public view returns (bool) {
    return _refunded[target];
  }

  function refund(address target) public {
    require(finished, "POAPSale: not finished");
    require(_rejected[target], "POAPSale: not rejected");
    _refunded[target] = true;
    payable(target).transfer(price);
    emit Refunded(target);
  }

  function cancel() public {
    require(msg.sender == admin, "POAPSale: not admin");
    require(!finished, "POAPSale: already finished");
    for (uint256 i = 0; i < buyers.length; i++) {
      _rejected[buyers[i]] = true;
      rejected.push(buyers[i]);
    }
    rejectedCount = buyers.length;
    finished = true;
    emit SaleFinished(0, buyers.length);
  }

  function finish(
    address[] memory finishAccepted,
    address[] memory finishRejected
  ) public {
    require(msg.sender == admin, "POAPSale: not admin");
    require(!finished, "POAPSale: already finished");
    require(block.timestamp >= endTimestamp, "POAPSale: not ended");
    require(finishAccepted.length + finishRejected.length == _received.current(), "POAPSale: invalid results");

    for (uint256 a = 0; a < finishAccepted.length; a++) {
      require(_buyers[finishAccepted[a]], "POAPSale: accepted not a buyer");
      require(!_finished[finishAccepted[a]], "POAPSale: duplicate address");
      _finished[finishAccepted[a]] = true;
      emit Buyer(finishAccepted[a], 1);
    }
    for (uint256 b = 0; b < finishRejected.length; b++) {
      require(_buyers[finishRejected[b]], "POAPSale: rejected not a buyer");
      require(!_finished[finishRejected[b]], "POAPSale: duplicate address");
      _finished[finishRejected[b]] = true;
      _rejected[finishRejected[b]] = true;
      rejected.push(finishRejected[b]);
      emit Buyer(finishRejected[b], 0);
    }
    rejectedCount = finishRejected.length;
    finished = true;
    emit SaleFinished(finishAccepted.length, rejectedCount);
    fundsReceiver.transfer(finishAccepted.length * price);
  }

  receive() external payable {
    require(!finished, "POAPSale: finished");
    _requireNotPaused();
    require(msg.value == price, "POAPSale: not value");
    require(_received.current() < quantity, "POAPSale: maximum reached");
    require(block.timestamp >= startTimestamp, "POAPSale: not started");
    require(block.timestamp < endTimestamp, "POAPSale: ended");
    require(!_buyers[msg.sender], "POAPSale: already bought one");
    buyers.push(msg.sender);
    _buyers[msg.sender] = true;
    _received.increment();
    emit Sold(msg.sender, _received.current());
  }
}