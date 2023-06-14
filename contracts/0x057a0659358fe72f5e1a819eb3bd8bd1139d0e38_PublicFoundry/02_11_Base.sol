// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../zone/Interface.sol";

import "./appraiser/Interface.sol";
import "./validator/Interface.sol";
import "./guard/Interface.sol";
import "./Interface.sol";

contract BaseFoundry is FoundryInterface {
  using SafeMath for uint256;

  uint256 public constant MAX_ITEMS = 256;

  struct Validator {
    FoundryValidatorInterface instance;
    uint256 id;
  }

  struct Guard {
    FoundryGuardInterface instance;
    uint256 id;
  }

  struct Appraiser {
    FoundryAppraiserInterface instance;
    uint256 id;
  }

  struct Issuance {
    ZoneInterface zone;
    bytes32 parent;
    bool enabled;
    Guard guard;
    Appraiser appraiser;
    address beneficiary;
  }

  Issuance[] public issuances;
  mapping(uint256 => Validator[]) public validators;
  mapping(uint256 => mapping(FoundryValidatorInterface => mapping(uint256 => uint256)))
    public validatorLookup;

  modifier onlyOwnerOfParent(uint256 issuanceId) {
    Issuance memory issuance = issuances[issuanceId];
    require(_isParentOwner(issuance.zone, issuance.parent), "Not the owner.");
    _;
  }

  function _isParentOwner(ZoneInterface zone, bytes32 parent)
    internal
    view
    returns (bool)
  {
    return IERC721(address(zone)).ownerOf(uint256(parent)) == msg.sender;
  }

  function _createIssuance(ZoneInterface zone, bytes32 parent)
    internal
    returns (uint256)
  {
    require(_isParentOwner(zone, parent), "Not the owner.");

    issuances.push(
      Issuance(
        zone,
        parent,
        false,
        Guard(FoundryGuardInterface(address(0)), 0),
        Appraiser(FoundryAppraiserInterface(address(0)), 0),
        address(0)
      )
    );

    uint256 id = issuances.length.sub(1);
    emit IssuanceCreated(id, zone, parent);
    return id;
  }

  function createIssuance(ZoneInterface zone)
    public
    override
    returns (uint256)
  {
    return _createIssuance(zone, zone.getOrigin());
  }

  function createSubIssuance(ZoneInterface zone, bytes32 parent)
    public
    returns (uint256)
  {
    return _createIssuance(zone, parent);
  }

  function enable(uint256 issuanceId)
    public
    override
    onlyOwnerOfParent(issuanceId)
  {
    Issuance storage issuance = issuances[issuanceId];
    issuance.enabled = true;
    emit Enabled(issuanceId);
  }

  function disable(uint256 issuanceId)
    public
    override
    onlyOwnerOfParent(issuanceId)
  {
    Issuance storage issuance = issuances[issuanceId];
    issuance.enabled = false;
    emit Disabled(issuanceId);
  }

  // New function to set the beneficiary
  function setBeneficiary(uint256 issuanceId, address newBeneficiary)
    public
    onlyOwnerOfParent(issuanceId)
  {
    issuances[issuanceId].beneficiary = newBeneficiary;
    emit BeneficiarySet(issuanceId, newBeneficiary);
  }

  function addValidator(
    uint256 issuanceId,
    FoundryValidatorInterface instance,
    uint256 id
  ) public override onlyOwnerOfParent(issuanceId) {
    require(
      validators[issuanceId].length < MAX_ITEMS,
      "Max validators reached."
    );
    validators[issuanceId].push(Validator(instance, id));
    validatorLookup[issuanceId][instance][id] = validators[issuanceId]
      .length
      .sub(1);
    emit ValidatorAdded(issuanceId, instance, id);
  }

  function removeValidator(
    uint256 issuanceId,
    FoundryValidatorInterface instance,
    uint256 id
  ) public override onlyOwnerOfParent(issuanceId) {
    uint256 validatorIndex = validatorLookup[issuanceId][instance][id];
    require(
      validatorIndex < validators[issuanceId].length,
      "Validator does not exist."
    );

    uint256 lastValidatorIndex = validators[issuanceId].length.sub(1);

    // Swap the validator to remove with the last validator in the array
    Validator storage validatorToRemove = validators[issuanceId][
      validatorIndex
    ];
    Validator storage lastValidator = validators[issuanceId][
      lastValidatorIndex
    ];

    validators[issuanceId][validatorIndex] = lastValidator;
    validators[issuanceId][lastValidatorIndex] = validatorToRemove;

    // Update the index of the last validator
    validatorLookup[issuanceId][lastValidator.instance][
      lastValidator.id
    ] = validatorIndex;

    // Remove the last validator from the array
    validators[issuanceId].pop();

    // Remove the validator from the index mapping
    delete validatorLookup[issuanceId][instance][id];

    emit ValidatorRemoved(issuanceId, instance, id);
  }

  function listValidators(uint256 issuanceId)
    public
    view
    returns (Validator[] memory)
  {
    return validators[issuanceId];
  }

  function validate(uint256 issuanceId, string memory label)
    public
    view
    override
    returns (bool)
  {
    Validator[] storage validatorArray = validators[issuanceId];
    for (uint256 i = 0; i < validatorArray.length; i++) {
      if (!validatorArray[i].instance.validate(validatorArray[i].id, label)) {
        return false;
      }
    }
    return true;
  }

  function setGuard(
    uint256 issuanceId,
    FoundryGuardInterface instance,
    uint256 id
  ) public override onlyOwnerOfParent(issuanceId) {
    Issuance storage issuance = issuances[issuanceId];
    issuance.guard = Guard(instance, id);
    emit GuardSet(issuanceId, instance, id);
  }

  function removeGuard(uint256 issuanceId)
    public
    override
    onlyOwnerOfParent(issuanceId)
  {
    Issuance storage issuance = issuances[issuanceId];
    issuance.guard = Guard(FoundryGuardInterface(address(0)), 0);
    emit GuardRemoved(issuanceId);
  }

  function authorize(
    uint256 id,
    address wallet,
    string calldata label,
    bytes calldata credentials
  ) external view override returns (bool) {
    require(id < issuances.length, "Issuance does not exist.");
    Issuance storage issuance = issuances[id];

    if (validate(id, label)) {
      // If a guard is set, check its authorization, otherwise just return true.
      if (issuance.guard.id != 0) {
        return
          issuance.guard.instance.authorize(
            issuance.guard.id,
            wallet,
            label,
            credentials
          );
      }
      return true;
    }
    return false;
  }

  function setAppraiser(
    uint256 issuanceId,
    FoundryAppraiserInterface instance,
    uint256 id
  ) public override onlyOwnerOfParent(issuanceId) {
    Issuance storage issuance = issuances[issuanceId];
    issuance.appraiser = Appraiser(instance, id);
    emit AppraiserSet(issuanceId, instance, id);
  }

  function removeAppraiser(uint256 issuanceId)
    public
    override
    onlyOwnerOfParent(issuanceId)
  {
    Issuance storage issuance = issuances[issuanceId];
    issuance.appraiser = Appraiser(FoundryAppraiserInterface(address(0)), 0);
    emit AppraiserRemoved(issuanceId);
  }

  function appraise(uint256 issuanceId, string memory label)
    public
    view
    returns (uint256, IERC20)
  {
    require(issuanceId < issuances.length, "Issuance does not exist.");
    Issuance storage issuance = issuances[issuanceId];

    // Default return values for when there's no Appraiser set
    uint256 amount = 0;
    IERC20 token = IERC20(address(0));

    if (issuance.appraiser.instance != FoundryAppraiserInterface(address(0))) {
      (amount, token) = issuance.appraiser.instance.appraise(
        issuance.appraiser.id,
        label
      );
    }

    return (amount, token);
  }

  function register(
    address to,
    uint256 issuanceId,
    string memory label,
    bytes memory credentials
  ) public payable override returns (bytes32 namehash) {
    require(issuanceId < issuances.length, "Issuance does not exist.");
    Issuance storage issuance = issuances[issuanceId];
    require(issuances[issuanceId].enabled, "Issuance is not enabled.");

    // check authorization
    require(
      this.authorize(issuanceId, to, label, credentials),
      "Authorization failed."
    );

    // get price and token
    (uint256 price, IERC20 token) = this.appraise(issuanceId, label);

    // Determine the recipient of the tokens
    address recipient = issuance.beneficiary != address(0)
      ? issuance.beneficiary
      : issuance.zone.owner();

    // check the user's balance and allowance then transfer the tokens or native ETH
    if (token == IERC20(address(0))) {
      require(msg.value >= price, "Insufficient balance.");
      (bool success, ) = recipient.call{value: price}("");
      require(success, "Transfer failed.");
    } else {
      require(token.balanceOf(msg.sender) >= price, "Insufficient balance.");
      require(
        token.allowance(msg.sender, address(this)) >= price,
        "Insufficient allowance."
      );
      require(
        token.transferFrom(msg.sender, recipient, price),
        "Transfer failed."
      );
    }

    // register label
    namehash = issuance.zone.register(to, issuance.parent, label);

    // Emit the event
    emit Registered(issuanceId, to, namehash);
  }
}