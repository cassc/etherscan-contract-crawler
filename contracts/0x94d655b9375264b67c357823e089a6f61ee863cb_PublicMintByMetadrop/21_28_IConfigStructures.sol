// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title IConfigStructures.sol. Interface for common config structures used accross the platform
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

interface IConfigStructures {
  enum DropStatus {
    approved,
    deployed,
    cancelled
  }

  enum TemplateStatus {
    live,
    terminated
  }

  enum TokenAllocationMethod {
    sequential,
    random
  }

  // The current status of the mint:
  //   - notEnabled: This type of mint is not part of this drop
  //   - notYetOpen: This type of mint is part of the drop, but it hasn't started yet
  //   - open: it's ready for ya, get in there.
  //   - finished: been and gone.
  //   - unknown: theoretically impossible.
  enum MintStatus {
    notEnabled,
    notYetOpen,
    open,
    finished,
    unknown
  }

  struct SubListConfig {
    uint256 start;
    uint256 end;
    uint256 phaseMaxSupply;
  }

  struct PrimarySaleModuleInstance {
    address instanceAddress;
    string instanceDescription;
  }

  struct NFTModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct PrimarySaleModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct VestingModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct RoyaltySplitterModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct InLifeModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct InLifeModules {
    InLifeModuleConfig[] modules;
  }

  struct NFTConfig {
    uint256 supply;
    uint256 mintingMethod;
    bytes32 name;
    bytes32 symbol;
    bytes32 dropId;
    bytes32 positionProof;
  }

  struct DropApproval {
    DropStatus status;
    uint32 lastChangedDate;
    address dropOwnerAddress;
    bytes32 configHash;
  }

  struct Template {
    TemplateStatus status;
    uint16 templateNumber;
    uint32 loadedDate;
    address payable templateAddress;
    string templateDescription;
  }

  struct NumericOverride {
    bool isSet;
    uint248 overrideValue;
  }
}