// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//This contract is a work in progress for research and development purposes only.

//Pipoca

// Defining custom errors for better error handling
error NoValueSent();
error InsufficientFundsInContract(uint256 requested, uint256 available);
error NoFundsInContract();
error NoActiveFlowForCreator(address creator);
error InsufficientInFlow(uint256 requested, uint256 available);
error EtherSendingFailed(address recipient);
error LengthsMismatch();
error CapCannotBeZero();
error InvalidCreatorAddress();
error CreatorAlreadyExists();
error ContractIsStopped();
error MaxCreatorsReached();
error AccessDenied();

contract YourContract is AccessControl, ReentrancyGuard {
  // Fixed cycle and max creators
  uint256 immutable CYCLE = 30 days;
  uint256 immutable MAXCREATORS = 25;

  // Emergency mode variable
  bool public stopped = false;

  // Defining admin role for the contract using AccessControl
  bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

  // Primary admin for remaining balances
  address private primaryAdmin;

  // Modifier to check for admin permissions
  modifier onlyAdmin() {
    if (!hasRole(ADMIN_ROLE, msg.sender)) revert AccessDenied();
    _;
  }

  // Constructor to setup admin role
  constructor(address _primaryAdmin) {
    _setupRole(DEFAULT_ADMIN_ROLE, _primaryAdmin);
    primaryAdmin = _primaryAdmin;
  }

  // Function to modify admin roles
  function modifyAdminRole(address adminAddress, bool shouldGrant) public onlyAdmin {
    if (shouldGrant) {
      grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
    } else {
      revokeRole(DEFAULT_ADMIN_ROLE, adminAddress);
    }
  }

  // Struct to store information about creator's flow
  struct CreatorFlowInfo {
    uint256 cap; // Maximum amount of funds that can be withdrawn in a cycle (in wei)
    uint256 last; // The timestamp of the last withdrawal
  }

  // Mapping to store the flow info of each creator
  mapping(address => CreatorFlowInfo) public flowingCreators;
  // Mapping to store the index of each creator in the activeCreators array
  mapping(address => uint256) public creatorIndex;
  // Array to store the addresses of all active creators
  address[] public activeCreators;

  // Declare events to log various activities
  event FundsReceived(address indexed from, uint256 amount);
  event Withdrawn(address indexed to, uint256 amount, string reason);
  event CreatorAdded(address indexed to, uint256 amount, uint256 cycle);
  event CreatorUpdated(address indexed to, uint256 amount, uint256 cycle);
  event CreatorRemoved(address indexed to);
  event AgreementDrained(address indexed to, uint256 amount);

  // Check if a flow for a creator is active
  modifier isFlowActive(address _creator) {
    if (flowingCreators[_creator].cap == 0) revert NoActiveFlowForCreator(_creator);
    _;
  }

  // Check if the contract is stopped
  modifier stopInEmergency() {
    if (stopped) revert ContractIsStopped();
    _;
  }

  //Fund contract
  function fundContract() public payable {
    if (msg.value == 0) revert NoValueSent();
    emit FundsReceived(msg.sender, msg.value);
  }

  // Enable or disable emergency mode
  function emergencyMode(bool _enable) public onlyAdmin {
    stopped = _enable;
  }

  // Get all creators' data.
  function allCreatorsData(address[] calldata _creators) public view returns (CreatorFlowInfo[] memory) {
    uint256 creatorLength = _creators.length;
    CreatorFlowInfo[] memory result = new CreatorFlowInfo[](creatorLength);
    for (uint256 i = 0; i < creatorLength; ++i) {
      address creatorAddress = _creators[i];
      result[i] = flowingCreators[creatorAddress];
    }
    return result;
  }

  // Get the available amount for a creator.
  function availableCreatorAmount(address _creator) public view isFlowActive(_creator) returns (uint256) {
    CreatorFlowInfo memory creatorFlow = flowingCreators[_creator];
    uint256 timePassed = block.timestamp - creatorFlow.last;
    uint256 cycleDuration = CYCLE;

    if (timePassed < cycleDuration) {
      uint256 availableAmount = (timePassed * creatorFlow.cap) / cycleDuration;
      return availableAmount;
    } else {
      return creatorFlow.cap;
    }
  }

  // Add a new creator's flow. No more than 25 creators are allowed.
  function addCreatorFlow(address payable _creator, uint256 _cap) public onlyAdmin {
    // Check for maximum creators.

    if (activeCreators.length >= MAXCREATORS) revert MaxCreatorsReached();

    validateCreatorInput(_creator, _cap);
    flowingCreators[_creator] = CreatorFlowInfo(_cap, block.timestamp);
    activeCreators.push(_creator);
    creatorIndex[_creator] = activeCreators.length - 1;
    emit CreatorAdded(_creator, _cap, CYCLE);
  }

  // Validate the input for a creator.
  function validateCreatorInput(address payable _creator, uint256 _cap) internal view {
    if (_creator == address(0)) revert InvalidCreatorAddress();
    if (_cap == 0) revert CapCannotBeZero();
    if (flowingCreators[_creator].cap > 0) revert CreatorAlreadyExists();
  }

  // Add a batch of creators.
  function addBatch(address[] memory _creators, uint256[] memory _caps) public onlyAdmin {
    uint256 cLength = _creators.length;
    if (cLength != _caps.length) revert LengthsMismatch();
    for (uint256 i = 0; i < cLength; ) {
      addCreatorFlow(payable(_creators[i]), _caps[i]);
      unchecked {
        ++i;
      }
    }
  }

  // Update a creator's flow cap and cycle.
  function updateCreatorFlowCapCycle(
    address payable _creator,
    uint256 _newCap
  ) public onlyAdmin isFlowActive(_creator) {
    if (_newCap == 0) revert CapCannotBeZero();

    CreatorFlowInfo storage creatorFlow = flowingCreators[_creator];

    // Set the new cap without calculating the used portion in the current cycle
    creatorFlow.cap = _newCap;

    uint256 timestamp = block.timestamp;
    uint256 timePassed = timestamp - creatorFlow.last;

    // Only change the cycle start timestamp if the new cycle is less than the time passed since the last withdrawal
    if (CYCLE < timePassed) {
      creatorFlow.last = timestamp - (CYCLE);
    }

    emit CreatorUpdated(_creator, _newCap, CYCLE);
  }

  function removeCreatorFlow(address _creator) public onlyAdmin isFlowActive(_creator) {
    uint256 creatorIndexToRemove = creatorIndex[_creator];
    address lastCreator = activeCreators[activeCreators.length - 1];

    // Check if the creator to be removed is the last one in the list
    if (_creator != lastCreator) {
      activeCreators[creatorIndexToRemove] = lastCreator;
      creatorIndex[lastCreator] = creatorIndexToRemove;
    }

    activeCreators.pop();

    delete flowingCreators[_creator];
    delete creatorIndex[_creator];

    emit CreatorRemoved(_creator);
  }

  // Creator withdraws funds.
  function flowWithdraw(
    uint256 _amount,
    string memory _reason
  ) public isFlowActive(msg.sender) nonReentrant stopInEmergency {
    CreatorFlowInfo storage creatorFlow = flowingCreators[msg.sender];

    uint256 totalAmountCanWithdraw = availableCreatorAmount(msg.sender);
    if (totalAmountCanWithdraw < _amount) revert InsufficientInFlow(_amount, totalAmountCanWithdraw);

    uint256 creatorflowLast = creatorFlow.last;
    uint256 timestamp = block.timestamp;
    uint256 cappedLast = timestamp - CYCLE;
    if (creatorflowLast < cappedLast) {
      creatorflowLast = cappedLast;
    }

    uint256 contractFunds = address(this).balance;
    if (contractFunds < _amount) revert InsufficientFundsInContract(_amount, contractFunds);

    (bool sent, ) = msg.sender.call{value: _amount, gas: 21000}(""); // Considered reasonable amount of gas limit for simple eth transfers, assuming recipient is an EOA
    if (!sent) revert EtherSendingFailed(msg.sender);

    creatorFlow.last = creatorflowLast + (((timestamp - creatorflowLast) * _amount) / totalAmountCanWithdraw);

    emit Withdrawn(msg.sender, _amount, _reason);
  }

  // Drain the agreement to the current primary admin
  function drainAgreement() public onlyAdmin nonReentrant {
    uint256 remainingBalance = address(this).balance;
    if (remainingBalance == 0) revert NoFundsInContract();

    (bool sent, ) = primaryAdmin.call{value: remainingBalance}(""); // No gas limit imposed here in case deployer is a smart contract that executes additional logic upon receiving eth. Also considered that this function would be rarely called
    if (!sent) revert EtherSendingFailed(primaryAdmin);

    emit AgreementDrained(primaryAdmin, remainingBalance);
  }

  // Fallback function to receive ether
  receive() external payable {}
}