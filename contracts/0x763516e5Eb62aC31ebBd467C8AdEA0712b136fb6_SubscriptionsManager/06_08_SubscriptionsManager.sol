// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../../libraries/interfaces/ISubscriptions.sol';
import '../../libraries/interfaces/ISubscriptionsManager.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @title Redlion Subscription Manager
/// @author Gui "Qruz" Rodrigues
/// @notice Management of payments and info of subcriptions
/// @dev Portal contract to all subscriptions tokens of REDLION
/*
  Each user is allowed to have a single subscription active,
  It is not possible to have a normal subscription and a super subscription simultaneously
  The following features are locked when the user is subscribed :
    - Transfer from (if subscription is SUPER)
      => The user is still allowed to burn their token
        Doing so will invalidate the subscription and every feature that comes the associated token
    - Transfer to 
    - Subscrption via contract
  Users still mainting 100% ownership of their tokens, they can sell them or give them
  but not hold multiple subscription tokens.

  
  Subscribed status : User is defined as subscribed whenever he holds a subscription token.
*/

contract SubscriptionsManager is
  Ownable,
  ReentrancyGuard,
  ISubscriptionsManager
{
  using Strings for uint256;
  using ECDSA for bytes32;

  mapping(SubType => uint256) PRICE;

  address SIGNER;

  address RED_ADDRESS;
  address GOLD_ADDRESS;

  /// @notice Construtor function defining basic parameters
  /// @dev subscription contract addresses can be null
  /// @param _red Super subscription contract address
  /// @param _gold Normal Subscroption contract address
  constructor(address _red, address _gold) {
    RED_ADDRESS = _red;
    GOLD_ADDRESS = _gold;
    setSubPrice(SubType.NORMAL, 99900);
    setSubPrice(SubType.SUPER, 299900);
  }

  /*///////////////////////////////////////////////////////////////
                             EVENTS
  ///////////////////////////////////////////////////////////////*/

  /// @notice Event emited when a user subscribes to a SuperSubscription
  /// @param to the subscriber address
  /// @param subType the type of subscription
  event Subscribe(address indexed to, SubType indexed subType);

  /*///////////////////////////////////////////////////////////////
                          SUBSCRIPTIONS
  ///////////////////////////////////////////////////////////////*/

  /// @notice Function subscribing the user depending on params
  /// @dev Internal function
  /// @param to target address
  /// @param subType Type of subscription
  function _subscribe(address to, SubType subType) internal {
    require(isSubscribed(to) == false, 'WALLET_ALREADY_SUBSCRIBED');
    if (subType == SubType.SUPER) {
      ISubscriptions(RED_ADDRESS).subscribe(to);
    } else if (subType == SubType.NORMAL) {
      ISubscriptions(GOLD_ADDRESS).subscribe(to);
    } else {
      revert('INVALID_SUB_TYPE');
    }

    emit Subscribe(to, subType);
  }

  /**
    This function was created with the intent of setting the price off chain.

    Although there's a PRICE mapping for each subscription type, these are only used as a signle source of truth
    that can be verified by the user. We're allowed to create discounts by changing the price in the signature.

    The price value in the signature should match the value of the transaction.

    Signature structure :
      - target address
      - contract address (in case we deploy a different subscription manager or use same signer in the future for different contract using the same logic)
      - Susbcription type (number id of enum)
      - Value (ethers price)
      - Timestamp of signature creation (seconds)

    @dev The signature contains data validating : price, valdiity (time) and contract address (contract) to avoid exploits
    @param subType the type of subscription
    @param timestamp the timestamp (seconds) when the signature was created
    @param signature the signature validating the subscription
     */

  function subscribe(
    SubType subType,
    uint256 timestamp,
    bytes memory signature
  ) public payable nonReentrant {
    require(block.timestamp < timestamp + 10 minutes, 'INVALID_TIMESTAMP');
    // Validate signature
    bytes32 inputHash = keccak256(
      abi.encodePacked(
        msg.sender,
        address(this),
        uint256(subType),
        msg.value,
        timestamp
      )
    );
    require(_validSignature(signature, inputHash), 'BAD_SIGNATURE');

    _subscribe(msg.sender, subType);
  }

  /*///////////////////////////////////////////////////////////////
                            SUB STATE
  ///////////////////////////////////////////////////////////////*/

  function isSubscribed(
    address target
  ) public view override(ISubscriptionsManager) returns (bool) {
    return
      ISubscriptions(RED_ADDRESS).isSubscribed(target) ||
      ISubscriptions(GOLD_ADDRESS).isSubscribed(target);
  }

  function whichType(address target) public view returns (SubType) {
    if (ISubscriptions(RED_ADDRESS).isSubscribed(target)) return SubType.SUPER;
    else if (ISubscriptions(GOLD_ADDRESS).isSubscribed(target))
      return SubType.NORMAL;
    return SubType.NONE;
  }

  function subscriptionInfo(
    address target
  ) public view override(ISubscriptionsManager) returns (SubInfo memory) {
    SubInfo memory info = SubInfo(false, SubType.NONE, 0, '');

    ISubscriptions superSubs = ISubscriptions(RED_ADDRESS);
    ISubscriptions normalSubs = ISubscriptions(GOLD_ADDRESS);

    if (normalSubs.isSubscribed(target)) {
      info.timestamp = normalSubs.when(target);
      info.subscribed = true;
      info.subType = SubType.NORMAL;
      info.subId = normalSubs.subscriptionId(target);
    } else if (superSubs.isSubscribed(target)) {
      info.timestamp = superSubs.when(target);
      info.subscribed = true;
      info.subType = SubType.SUPER;
      info.subId = superSubs.subscriptionId(target);
    }
    return info;
  }

  /*///////////////////////////////////////////////////////////////
                          OWNER FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /// @notice Owner subscription function
  /// @dev Bypasses signature verification (owner only)
  /// @param to the target address
  /// @param subType the subscription type
  function ownerSubscribe(address to, SubType subType) public onlyOwner {
    _subscribe(to, subType);
  }

  /*///////////////////////////////////////////////////////////////
                              UTILITY
  ///////////////////////////////////////////////////////////////*/

  function _isValidSubType(SubType _subType) internal pure {
    require(
      _subType == SubType.NORMAL || _subType == SubType.SUPER,
      'INVALID_SUB_TYPE'
    );
  }

  /// @notice Sets the new signer address
  /// @dev this function is used when the current signer address has been compromised or access lost
  /// @param _address the new signer address
  function setSigner(address _address) public onlyOwner {
    SIGNER = _address;
  }

  /// @notice Set normal subscriptions contract address
  /// @param _contractAddress the new contract adddress
  function setSubscriptions(address _contractAddress) public onlyOwner {
    GOLD_ADDRESS = _contractAddress;
  }

  /// @notice Set super subscriptions contract address
  /// @param _contractAddress the new contract adddress
  function setSuperSubscriptions(address _contractAddress) public onlyOwner {
    RED_ADDRESS = _contractAddress;
  }

  /// @notice Set price for a specific subscription type
  /// @param _subType the subscription type
  /// @param _price the new price
  function setSubPrice(SubType _subType, uint256 _price) public onlyOwner {
    _isValidSubType(_subType);
    PRICE[_subType] = _price;
  }

  /// @notice Getter for a specific subscription type price
  /// @param _subType the subscription type id
  /// @return uint256 the subcription's price
  function getPrice(SubType _subType) external view returns (uint256) {
    _isValidSubType(_subType);
    return PRICE[_subType];
  }

  function _validSignature(
    bytes memory signature,
    bytes32 msgHash
  ) internal view returns (bool) {
    return msgHash.toEthSignedMessageHash().recover(signature) == SIGNER;
  }
}