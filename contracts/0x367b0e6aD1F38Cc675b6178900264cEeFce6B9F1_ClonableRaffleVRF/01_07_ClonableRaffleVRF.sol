//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "../interfaces/IRandomNumberConsumer.sol";

contract ClonableRaffleVRF is OwnableUpgradeable {

  event RaffleEntry(address indexed entrant);
  event RaffleExit(address indexed exiter);

  // Controlled variables
  bool private isInitialized;
  bool public isRandomnessRequested;
  bytes32 public randomNumberRequestId;
  uint256 public vrfResult;
  mapping(address => bool) public entrantToStatus;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  CountersUpgradeable.Counter private _entryCounter;

  // Config variables
  address public vrfProvider;
  string public snapshotLink;
  uint256 public snapshotBlock;
  uint256 public snapshotLength;
  uint256 public raffleStartTimeUnix;
  uint256 public raffleEndTimeUnix;
  bool public useSnapshotBlockAsEndTime;

  function initialize(
    address _vrfProvider,
    uint256 _snapshotBlock,
    address _admin,
    uint256 _raffleStartTimeUnix,
    uint256 _raffleEndTimeUnix,
    bool _useSnapshotBlockAsEndTime
  ) external {
    require(!isInitialized, "ALREADY_INITIALIZED");
    isInitialized = true;
    vrfProvider = _vrfProvider;
    snapshotBlock = _snapshotBlock;
    raffleStartTimeUnix = _raffleStartTimeUnix;
    raffleEndTimeUnix = _raffleEndTimeUnix;
    useSnapshotBlockAsEndTime = _useSnapshotBlockAsEndTime;
    _transferOwnership(_admin);
  }

  function enterRaffle() external {
    if(useSnapshotBlockAsEndTime) {
      require(block.number <= snapshotBlock, "RAFFLE_ENTRY_CLOSED");
    } else {
      require(block.timestamp <= raffleEndTimeUnix, "RAFFLE_ENTRY_CLOSED");
    }
    require(raffleStartTimeUnix <= block.timestamp, "RAFFLE_ENTRY_NOT_STARTED");
    require(entrantToStatus[msg.sender] == false, "ALREADY_ENTERED_RAFFLE");
    entrantToStatus[msg.sender] = true;
    _entryCounter.increment();
    // Since this function simply signals that an address would like to be part of a raffle...
    // ...we don't actually need to check any token balances, emitting an event signals inclusion in snapshot
    // A snapshot should be taken at the snapshotBlock and all addresses *without* RaffleEntry events should be filtered out
    // The snapshot itself serves as the logical check as to whether or not an entry should be kept in the raffle entry list
    // Any addresses which have entered the raffle via this function without holding any underlying tokens entitling them to the raffle... 
    // ... will be excluded from the list by virtue of not coming up in the snapshot
    emit RaffleEntry(msg.sender);
  }

  function exitRaffle() external {
    if(useSnapshotBlockAsEndTime) {
      require(block.number <= snapshotBlock, "RAFFLE_CLOSED");
    } else {
      require(block.timestamp <= raffleEndTimeUnix, "RAFFLE_CLOSED");
    }
    require(entrantToStatus[msg.sender] == false, "NOT_ENTERED");
    _entryCounter.decrement();
    entrantToStatus[msg.sender] = false;
    emit RaffleExit(msg.sender);
  }

  function raffleEntrantCount() external view returns (uint256) {
    return _entryCounter.current();
  }

  function setSnapshotBlock(
    uint256 _snapshotBlock
  ) external onlyOwner {
    require(isRandomnessRequested == false, "VRF_ALREADY_INITIATED");
    snapshotBlock = _snapshotBlock;
  }

  function setRaffleStartTimeUnix(
    uint256 _raffleStartTimeUnix
  ) external onlyOwner {
    require(isRandomnessRequested == false, "VRF_ALREADY_INITIATED");
    raffleStartTimeUnix = _raffleStartTimeUnix;
  }

  function setRaffleEndTimeUnix(
    uint256 _raffleEndTimeUnix
  ) external onlyOwner {
    require(isRandomnessRequested == false, "VRF_ALREADY_INITIATED");
    raffleEndTimeUnix = _raffleEndTimeUnix;
  }

  function setSnapshotLinkAndLength(
    string memory _snapshotLink,
    uint256 _snapshotLength
  ) external onlyOwner {
    require(isRandomnessRequested == false, "VRF_ALREADY_INITIATED");
    snapshotLink = _snapshotLink;
    snapshotLength = _snapshotLength;
  }

  function initiateRandomDraw() external onlyOwner {
    require(isRandomnessRequested == false, "VRF_ALREADY_INITIATED");
    require(snapshotBlock > 0, "SNAPSHOT_BLOCK_NOT_SET");
    require(keccak256(bytes(snapshotLink)) != keccak256(bytes("")), "SNAPSHOT_LINK_NOT_SET");
    require(snapshotLength > 0, "SNAPSHOT_LENGTH_NOT_SET");
    IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
    randomNumberRequestId = randomNumberConsumer.getRandomNumber();
    isRandomnessRequested = true;
  }

  function commitRandomDraw() external {
    require(isRandomnessRequested == true, "VRF_NOT_INITIATED");
    IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
    uint256 result = randomNumberConsumer.readFulfilledRandomness(randomNumberRequestId);
    require(result > 0, "VRF_NOT_FULFILLED");
    vrfResult = result;
  }

  function winnerIndex() external view returns (uint256) {
    if(vrfResult > 0) {
      return vrfResult % snapshotLength;
    } else {
      return 0;
    }
  }
  
}