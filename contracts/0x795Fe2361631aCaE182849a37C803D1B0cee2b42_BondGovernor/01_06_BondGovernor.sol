// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./interfaces/IBondGovernor.sol";

/// @title BondGovernor
/// @author Bluejay Core Team
/// @notice BondGovernor defines parameters for treasury bond depositories and provide
/// a ramping function for bond control variable changes.
/// @dev This contract only works for reserve assets with 18 decimal places
contract BondGovernor is Ownable, IBondGovernor {
  uint256 private constant WAD = 10**18;
  uint256 private constant RAY = 10**27;

  /// @notice The contract address of the BLU token
  IERC20 public immutable BLU;

  /// @notice Minimum amount of BLU token a bond can have, in WAD
  /// @dev This prevents bonds that are too expensive to claim to be created
  uint256 public minimumSize;

  /// @notice Ratio of BLU token supply that defines the largest bond size, in WAD
  /// @dev This prevents large bonds to be purchased at a fixed low price and allow
  /// bond prices to be updated
  uint256 public maximumRatio;

  /// @notice Ratio of fees to be paid to the fee collector, in WAD
  uint256 public fees;

  /// @notice Mapping of reserve assets collected to their bond policies
  mapping(address => Policy) public policies;

  /// @notice Check if a treasury bond policy exist for a given reserve asset
  modifier policyExist(address asset) {
    require(policies[asset].controlVariable != 0, "Policy not initialized");
    _;
  }

  /// @notice Constructor to initialize the contract
  /// @param _BLU Address of the BLU token
  /// @param _maximumRatio Ratio of BLU token supply that defines the largest bond size, in WAD
  constructor(address _BLU, uint256 _maximumRatio) {
    BLU = IERC20(_BLU);
    minimumSize = WAD / 1000; // 1 thousandth of the token [wad]
    fees = WAD / 5; // 20% of sale proceeds [wad]
    maximumRatio = _maximumRatio;
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Update the control variable of a bond policy
  /// @dev This function uses `getControlVariable(asset)` to determine what is the current
  /// control variable on the ramp.
  function updateControlVariable(address asset) public override {
    uint256 currentControlVariable = getControlVariable(asset);
    uint256 timeElapsed = block.timestamp -
      policies[asset].lastControlVariableUpdate;

    policies[asset].controlVariable = currentControlVariable;
    policies[asset].lastControlVariableUpdate = block.timestamp;
    if (timeElapsed > policies[asset].timeToTargetControlVariable) {
      policies[asset].timeToTargetControlVariable = 0;
    } else {
      unchecked {
        policies[asset].timeToTargetControlVariable -= timeElapsed;
      }
    }
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Initialize a bond policy for a given reserve asset
  /// @param asset Address of the reserve asset
  /// @param controlVariable Initial control variable of the bond policy, in RAY
  /// @param minimumPrice Minimum price of the asset, denominated against the reserve asset
  function initializePolicy(
    address asset,
    uint256 controlVariable,
    uint256 minimumPrice
  ) public override onlyOwner {
    require(
      policies[asset].controlVariable == 0,
      "Policy has been initialized"
    );
    require(controlVariable >= RAY, "Control variable less than 1");
    policies[asset] = Policy({
      controlVariable: controlVariable,
      lastControlVariableUpdate: block.timestamp,
      targetControlVariable: controlVariable,
      timeToTargetControlVariable: 0,
      minimumPrice: minimumPrice
    });
    emit CreatedPolicy(asset, controlVariable, minimumPrice);
  }

  /// @notice Update the control variable and minimum price of a bond
  /// @dev The update for control variable will be ramped up/down according to the
  /// period specified in `timeToTargetControlVariable` to prevent sudden changes.
  /// @param asset Address of the reserve asset
  /// @param targetControlVariable New control variable of the bond policy, in RAY
  /// @param timeToTargetControlVariable Period to ramp the control variable up/down, in seconds
  /// @param minimumPrice Minimum price of the asset, denominated against the reserve asset
  function adjustPolicy(
    address asset,
    uint256 targetControlVariable,
    uint256 timeToTargetControlVariable,
    uint256 minimumPrice
  ) public override onlyOwner {
    require(
      targetControlVariable >= RAY,
      "Target control variable less than 1"
    );
    require(timeToTargetControlVariable != 0, "Time cannot be 0");

    updateControlVariable(asset);
    policies[asset].targetControlVariable = targetControlVariable;
    policies[asset].timeToTargetControlVariable = timeToTargetControlVariable;
    policies[asset].minimumPrice = minimumPrice;
    emit UpdatedPolicy(
      asset,
      targetControlVariable,
      minimumPrice,
      timeToTargetControlVariable
    );
  }

  /// @notice Set the fee collected for bond sales
  /// @param _fees Ratio of fees collected for bond sales, in WAD
  function setFees(uint256 _fees) public override onlyOwner {
    require(_fees <= WAD, "Fees greater than 100%");
    fees = _fees;
    emit UpdatedFees(fees);
  }

  /// @notice Set the minimum bond size
  /// @param _minimumSize Minimum bond size, in WAD
  function setMinimumSize(uint256 _minimumSize) public override onlyOwner {
    minimumSize = _minimumSize;
    emit UpdatedMinimumSize(minimumSize);
  }

  /// @notice Set the maximum bond size ratio
  /// @param _maximumRatio Maximum bond size ratio, in WAD
  function setMaximumRatio(uint256 _maximumRatio) public override onlyOwner {
    require(_maximumRatio <= WAD, "Maximum ratio greater than 100%");
    maximumRatio = _maximumRatio;
    emit UpdatedMaximumRatio(maximumRatio);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Get the current control variable of a bond policy
  /// @param asset Address of the reserve asset
  /// @return controlVariable Current control variable of the bond policy, in RAY
  function getControlVariable(address asset)
    public
    view
    override
    policyExist(asset)
    returns (uint256)
  {
    Policy memory policy = policies[asset];

    // Target control variable is reached
    if (
      policy.lastControlVariableUpdate + policy.timeToTargetControlVariable <=
      block.timestamp
    ) {
      return policy.targetControlVariable;
    }

    // Target control variable is not reached
    unchecked {
      if (policy.controlVariable <= policy.targetControlVariable) {
        return
          policy.controlVariable +
          ((block.timestamp - policy.lastControlVariableUpdate) *
            (policy.targetControlVariable - policy.controlVariable)) /
          policy.timeToTargetControlVariable;
      } else {
        return
          policy.controlVariable -
          ((block.timestamp - policy.lastControlVariableUpdate) *
            (policy.controlVariable - policy.targetControlVariable)) /
          policy.timeToTargetControlVariable;
      }
    }
  }

  /// @notice Get the maximum amount of BLU allowed as principle on a bond
  /// @return maximumSize Maximum amount of BLU allowed, in WAD
  function maximumBondSize()
    public
    view
    override
    returns (uint256 maximumSize)
  {
    maximumSize = (BLU.totalSupply() * maximumRatio) / WAD;
  }

  /// @notice Get all policy parameters for a bond
  /// @param asset Address of the reserve asset
  /// @return controlVariable Current control variable of the bond policy, in RAY
  /// @return minimumPrice Minimum price of the asset, denominated against the reserve asset
  /// @return minimumSize Minumum bond size, in WAD
  /// @return maximumBondSize Maximum bond size, in WAD
  /// @return fees Ratio of sale collected as fee, in WAD
  function getPolicy(address asset)
    public
    view
    override
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      getControlVariable(asset),
      policies[asset].minimumPrice,
      minimumSize,
      maximumBondSize(),
      fees
    );
  }
}