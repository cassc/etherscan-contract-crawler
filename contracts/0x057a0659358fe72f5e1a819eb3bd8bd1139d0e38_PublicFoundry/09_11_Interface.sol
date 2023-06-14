// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../zone/Interface.sol";

import "./appraiser/Interface.sol";
import "./validator/Interface.sol";
import "./guard/Interface.sol";

interface FoundryInterface {
  event IssuanceCreated(uint256 id, ZoneInterface zone, bytes32 parent);
  event Enabled(uint256 issuanceId);
  event Disabled(uint256 issuanceId);
  event BeneficiarySet(uint256 indexed issuanceId, address newBeneficiary);

  event ValidatorAdded(
    uint256 indexed issuanceId,
    FoundryValidatorInterface indexed validatorContract,
    uint256 validatorId
  );
  event ValidatorRemoved(
    uint256 indexed issuanceId,
    FoundryValidatorInterface indexed instance,
    uint256 id
  );

  event GuardSet(
    uint256 issuanceId,
    FoundryGuardInterface instance,
    uint256 id
  );
  event GuardRemoved(uint256 issuanceId);

  event AppraiserSet(
    uint256 indexed issuanceId,
    FoundryAppraiserInterface appraiserContract,
    uint256 appriaserId
  );
  event AppraiserRemoved(uint256 indexed issuanceId);

  event Registered(uint256 issuanceId, address indexed to, bytes32 namehash);

  function createIssuance(ZoneInterface zone) external returns (uint256);

  function enable(uint256 issuanceId) external;

  function disable(uint256 issuanceId) external;

  function addValidator(
    uint256 issuanceId,
    FoundryValidatorInterface instance,
    uint256 id
  ) external;

  function removeValidator(
    uint256 issuanceId,
    FoundryValidatorInterface instance,
    uint256 id
  ) external;

  function validate(uint256 issuanceId, string calldata label)
    external
    view
    returns (bool);

  function setGuard(
    uint256 issuanceId,
    FoundryGuardInterface instance,
    uint256 id
  ) external;

  function removeGuard(uint256 issuanceId) external;

  function authorize(
    uint256 id,
    address wallet,
    string calldata label,
    bytes calldata credentials
  ) external view returns (bool);

  function setAppraiser(
    uint256 issuanceId,
    FoundryAppraiserInterface instance,
    uint256 id
  ) external;

  function removeAppraiser(uint256 issuanceId) external;

  function register(
    address to,
    uint256 issuanceId,
    string memory label,
    bytes memory credentials
  ) external payable returns (bytes32 namehash);
}