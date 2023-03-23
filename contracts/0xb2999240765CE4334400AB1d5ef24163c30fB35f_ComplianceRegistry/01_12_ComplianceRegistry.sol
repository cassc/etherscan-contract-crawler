/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity 0.6.2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../interfaces/IComplianceRegistry.sol";
import "../interfaces/IPriceable.sol";
import "../interfaces/IGovernable.sol";
import "../interfaces/IERC20Detailed.sol";
import "../access/Operator.sol";


/**
 * @title ComplianceRegistry
 * @dev The Compliance Registry stores user related attributes for multiple compliance authorities (named trusted intermediaries)
 *
 * Error messages
 * UR01: UserId is invalid
 * UR02: Address is already attached
 * UR03: Users length does not match with addresses length
 * UR04: Address is not attached
 * UR05: Attribute keys length does not match with attribute values length
 * UR06: Transfer and transfer decisions must have the same length
 * UR07: Only originator can cancel transfer
 * UR08: Unsuccessful transfer
 * UR09: Only on hold transfers can be canceled
*/
contract ComplianceRegistry is Initializable, IComplianceRegistry, Operator {
  using SafeMath for uint256;

  uint256 public constant VERSION = 3;

  uint256 constant internal MONTH = 31 days;
  uint8 constant internal TRANSFER_ONHOLD = 0;
  uint8 constant internal TRANSFER_APPROVE = 1;
  uint8 constant internal TRANSFER_REJECT = 2;
  uint8 constant internal TRANSFER_CANCEL = 3;
  uint8 constant internal MAX_DECIMALS = 20;
  string constant internal REF_CURRENCY = "CHF";

  struct MonthlyTransfers {
    uint256 in_;
    uint256 out_;
  } 

  struct OnHoldTransfer {
    address token;
    uint8 decision;
    address from;
    address to;
    uint256 amount;
  }

  mapping(address => uint256) public userCount;
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) internal userAttributes;
  mapping(address => mapping(uint256 => address[])) internal userAddresses;
  mapping(address => mapping(address => uint256)) internal addressUsers;
  mapping(address => mapping(uint256 => OnHoldTransfer)) internal onHoldTransfers;
  mapping(address => uint256) public onHoldMinBoundary;
  mapping(address => uint256) public onHoldMaxBoundary;
  mapping(address => mapping(address => mapping(uint256 => MonthlyTransfers))) internal addressTransfers;

  uint256 internal constant USER_VALID_UNTIL_KEY = 0;

  /**
  * @dev Initializer (replaces constructor when contract is upgradable)
  * @param owner the final owner of the contract
  */
  function initialize(address owner) public override initializer {
    Operator.initialize(owner);
  }

  /**
   * @dev fetch the userId associated to the provided address registered by trusted intermediaries
   * @dev The algorithm loops through each trusted intermediary and returns the first userId found 
   * @dev even if the user exists for next trusted intermediaries
   * @param _trustedIntermediaries array of trusted intermediaries to look the address for
   * @param _address address to look for
   * @return userId the user id found, 0 if not found
   * @return the address of the first trusted intermediary for which the user was found, 0x0 if no user was found
   */
  function userId(
    address[] calldata _trustedIntermediaries, 
    address _address
  ) 
    external override view returns (uint256, address) 
  {
    return _getUser(_trustedIntermediaries, _address);
  }

  /**
   * @dev returns the date at which user validity ends (UNIX timestamp)
   * @param _trustedIntermediary the reference trusted intermediary of the user
   * @param _userId the userId for which the validity date has to be returned
   * @return the date at which user validity ends (UNIX timestamp)
   */
  function validUntil(address _trustedIntermediary, uint256 _userId) public override view returns (uint256) {
    return userAttributes[_trustedIntermediary][_userId][USER_VALID_UNTIL_KEY];
  }

  /**
   * @dev get one user attribute
   * @param _trustedIntermediary the reference trusted intermediary of the user
   * @param _userId the userId for which the attribute has to be returned
   * @param _key the key of the attribute to return
   * @return the attribute value for the pair (_userId, _key), defaults to 0 if _key or _userId not found
   */
  function attribute(address _trustedIntermediary, uint256 _userId, uint256 _key)
    public override view returns (uint256)
  {
    return userAttributes[_trustedIntermediary][_userId][_key];
  }
  
  /**
  * @dev access to multiple user attributes at once
  * @param _trustedIntermediary the reference trusted intermediary of the user
  * @param _userId the userId for which attributes have to be returned
  * @param _keys array of keys of attributes to return
  * @return the attribute values for each pair (_userId, _key), defaults to 0 if _key or _userId not found
  **/
  function attributes(address _trustedIntermediary, uint256 _userId, uint256[] calldata _keys) 
    external override view returns (uint256[] memory)
  {
    uint256[] memory values = new uint256[](_keys.length);
    for (uint256 i = 0; i < _keys.length; i++) {
      values[i] = userAttributes[_trustedIntermediary][_userId][_keys[i]];
    }
    return values;
  }

  /**
   * @dev Get the validaty of an address for trusted intermediaries
   * @param _trustedIntermediaries array of trusted intermediaries to look the address for
   * @param _address address to look for
   * @return true if a user corresponding to the address was found for a trusted intermediary and is not expired, false otherwise
   */
  function isAddressValid(address[] calldata _trustedIntermediaries, address _address) external override view returns (bool) {
    uint256 _userId;
    address _trustedIntermediary;
    (_userId, _trustedIntermediary) = _getUser(_trustedIntermediaries, _address);
    return _isValid(_trustedIntermediary, _userId);
  }

  /**
   * @dev checks if the user id passed in parameter is not expired
   * @param _trustedIntermediary the reference trusted intermediary of the user
   * @param _userId the userId to be checked
   * @return true if a user was found for the trusted intermediary and is not expired, false otherwise
   */
  function isValid(address _trustedIntermediary, uint256 _userId) public override view returns (bool) {
    return _isValid(_trustedIntermediary, _userId);
  }

  /**
   * @dev Registers a new user corresponding to an address and sets its initial attributes
   * @dev Intended to be called from a trusted intermediary key
   * @dev Throws UR05 if _attributeKeys length is not the same as _attributeValues length
   * @dev Throws UR02 if address is already registered to a user
   * @dev Emits AddressAttached event
   * @param _address the address to register
   * @param _attributeKeys array of keys of attributes to set
   * @param _attributeValues array of values of attributes to set
   */
  function registerUser(address _address, uint256[] calldata _attributeKeys, uint256[] calldata _attributeValues)
    external override
  {
    require(_attributeKeys.length == _attributeValues.length, "UR05");
    require(addressUsers[_msgSender()][_address] == 0, "UR02");
    _registerUser(_address, _attributeKeys, _attributeValues);
  }

  /**
   * @dev Registers multiple users corresponding to addresses and sets their initial attributes
   * @dev Intended to be called from a trusted intermediary key
   * @dev Ignores already registered addresses
   * @dev Throws UR05 if _attributeKeys length is not the same as _attributeValues length
   * @dev Emits multiple AddressAttached events
   * @param _addresses the array of addresses to register
   * @param _attributeKeys array of keys of attributes to set
   * @param _attributeValues array of values of attributes to set
   */
  function registerUsers(
    address[] calldata _addresses, 
    uint256[] calldata _attributeKeys, 
    uint256[] calldata _attributeValues
  ) 
    external override
  {
    require(_attributeKeys.length == _attributeValues.length, "UR05");
    for (uint256 i = 0; i < _addresses.length; i++) {
      if (addressUsers[_msgSender()][_addresses[i]] == 0) {
        _registerUser(_addresses[i], _attributeKeys, _attributeValues);
      }
    }
  }

  /**
   * @dev Attach an address to an existing user
   * @dev Intended to be called from a trusted intermediary key
   * @dev Throws UR01 if user does not exist
   * @dev Throws UR02 if address is already attached
   * @dev Emits AddressAttached event
   * @param _userId the user id to which the address will be attached
   * @param _address the address to attach
   */
  function attachAddress(uint256 _userId, address _address)
    public override
  {
    require(_userId > 0 && _userId <= userCount[_msgSender()], "UR01");
    _attachAddress(_userId, _address);
  }

  /**
   * @dev Attach addresses to existing users
   * @dev Intended to be called from a trusted intermediary key
   * @dev Throws UR03 if _addresses length does not match _userIds length
   * @dev Throws UR02 if an address is already attached
   * @dev Throws UR01 if user does not exist
   * @dev Emits multiple AddressAttached events
   * @param _userIds array of user ids to which an address will be attached
   * @param _addresses array of addresses to attach
   */
  function attachAddresses(uint256[] calldata _userIds, address[] calldata _addresses)
    external override
  {
    require(_addresses.length == _userIds.length, "UR03");
    uint256 _userCount = userCount[_msgSender()];
    for (uint256 i = 0; i < _addresses.length; i++) {
      require(_userIds[i] > 0 && _userIds[i] <= _userCount, "UR01");
      _attachAddress(_userIds[i], _addresses[i]);
    }
  }

  /**
   * @dev Detach an address from a user
   * @dev Intended to be called from a trusted intermediary key
   * @dev Throws UR04 if the address is not attached
   * @dev Emits AddressDetached event
   * @param _address address to detach
   */
  function detachAddress(address _address) public override {
    _detachAddress(_address);
  }

  /**
   * @dev Detach addresses from their respective user
   * @dev Intended to be called from a trusted intermediary key
   * @dev Throws UR04 if an address is not attached
   * @dev Emits multiple AddressDetached events
   * @param _addresses array of addresses to detach
   */
  function detachAddresses(address[] calldata _addresses) external override {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _detachAddress(_addresses[i]);
    }
  }

  /**
   * @dev Updates attributes for a user
   * @dev Intended to be called from a trusted intermediary key
   * @dev Throws UR05 if _attributeKeys length is not the same as _attributeValues length
   * @dev Throws UR01 user is not found
   * @param _userId the user id for which the attributes are updated
   * @param _attributeKeys array of keys of attributes to set
   * @param _attributeValues array of values of attributes to set
   */
  function updateUserAttributes(
    uint256 _userId, 
    uint256[] calldata _attributeKeys, 
    uint256[] calldata _attributeValues
  )
    external override
  {
    require(_attributeKeys.length == _attributeValues.length, "UR05");
    require(_userId > 0 && _userId <= userCount[_msgSender()], "UR01");
    _updateUserAttributes(_userId, _attributeKeys, _attributeValues);
  }

  /**
   * @dev Updates attributes for many users
   * @dev Intended to be called from a trusted intermediary key
   * @dev Throws UR05 if _attributeKeys length is not the same as _attributeValues length
   * @dev Ignores not found users
   * @param _userIds the user ids for which the attributes are updated
   * @param _attributeKeys array of keys of attributes to set
   * @param _attributeValues array of values of attributes to set
   */
  function updateUsersAttributes(
    uint256[] calldata _userIds,
    uint256[] calldata _attributeKeys, 
    uint256[] calldata _attributeValues
  ) external override
  {
    require(_attributeKeys.length == _attributeValues.length, "UR05");
    uint256 _userCount = userCount[_msgSender()];
    for (uint256 i = 0; i < _userIds.length; i++) {
      if (_userIds[i] > 0 && _userIds[i] <= _userCount) {
        _updateUserAttributes(_userIds[i], _attributeKeys, _attributeValues);
      }
    }
  }

  /**
  * @dev Updates the transfer registry
  * @dev Intended to ba called by transfer computing rules that has been granted the operator right
  * @param _realm the realm (group) of the exchanged token
  * @param _from the sender of the tokens
  * @param _to the receiver of the tokens
  * @param _value transfered tokens value converted in CHF
  */
  function updateTransfers(
    address _realm, 
    address _from, 
    address _to, 
    uint256 _value
  ) 
    public override onlyOperator
  {
    return _updateTransfers(_realm, _from, _to, _value);
  }

  /**
  * @dev Returns the CHF amount transfered (IN and OUT) by an address for a 31 days period for a specific realm
  * @param _realm the realm for which we want the amount to be returned
  * @param _trustedIntermediaries array of trustedIntermediaries in which we lookup the address
  * @param _address address to lookup
  * @return the CHF amount transfered (IN and OUT) by an address for the period for a specific realm 
  */
  function monthlyTransfers(
    address _realm, 
    address[] calldata _trustedIntermediaries, 
    address _address
  ) 
    external override view returns (uint256) 
  {
    return _monthlyInTransfers(_realm, _trustedIntermediaries, _address) + 
      _monthlyOutTransfers(_realm, _trustedIntermediaries, _address);
  }

  /**
  * @dev Returns the CHF amount transfered (IN and OUT) by an address for a 12 months period for a specific realm
  * @param _realm the realm for which we want the amount to be returned
  * @param _trustedIntermediaries array of trustedIntermediaries in which we lookup the address
  * @param _address address to lookup
  * @return the CHF amount transfered (IN and OUT) by an address for the period for a specific realm 
  */
  function yearlyTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries, 
    address _address
  ) 
    external override view returns (uint256) 
  {
    return _yearlyInTransfers(_realm, _trustedIntermediaries, _address) + 
      _yearlyOutTransfers(_realm, _trustedIntermediaries, _address);
  }

  /**
  * @dev Returns the CHF amount transfered (IN) by an address for a 31 days period for a specific realm
  * @param _realm the realm for which we want the amount to be returned
  * @param _trustedIntermediaries array of trustedIntermediaries in which we lookup the address
  * @param _address address to lookup
  * @return the CHF amount transfered (IN) by an address for the period for a specific realm 
  */
  function monthlyInTransfers(    
    address _realm,
    address[] calldata _trustedIntermediaries, 
    address _address
  ) 
    external override view returns (uint256) 
  {
    return _monthlyInTransfers(_realm, _trustedIntermediaries, _address);
  }

  /**
  * @dev Returns the CHF amount transfered (IN) by an address for a 12 months period for a specific realm
  * @param _realm the realm for which we want the amount to be returned
  * @param _trustedIntermediaries array of trustedIntermediaries in which we lookup the address
  * @param _address address to lookup
  * @return the CHF amount transfered (IN) by an address for the period for a specific realm 
  */
  function yearlyInTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries, 
    address _address
  ) 
    external override view returns (uint256) 
  {
    return _yearlyInTransfers(_realm, _trustedIntermediaries, _address);
  }

  /**
  * @dev Returns the CHF amount transfered (OUT) by an address for a 31 days period for a specific realm
  * @param _realm the realm for which we want the amount to be returned
  * @param _trustedIntermediaries array of trustedIntermediaries in which we lookup the address
  * @param _address address to lookup
  * @return the CHF amount transfered (OUT) by an address for the period for a specific realm 
  */
  function monthlyOutTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries, 
    address _address
  ) 
    external override view returns (uint256) 
  {
    return _monthlyOutTransfers(_realm, _trustedIntermediaries, _address);
  }

  /**
  * @dev Returns the CHF amount transfered (OUT) by an address for a 12 months period for a specific realm
  * @param _realm the realm for which we want the amount to be returned
  * @param _trustedIntermediaries array of trustedIntermediaries in which we lookup the address
  * @param _address address to lookup
  * @return the CHF amount transfered (OUT) by an address for the period for a specific realm 
  */
  function yearlyOutTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries, 
    address _address
  ) 
    external override view returns (uint256) 
  {
    return _yearlyOutTransfers(_realm, _trustedIntermediaries, _address);
  }

  /**
  * @dev Adds a transfer to the on hold queue that will be processed by the trusted intermediary
  * @dev Intended to ba called by transfer computing rules that has been granted the operator right
  * @dev Emits a TransferOnHold event that can be listened by wallets for improved UX experience
  * @param trustedIntermediary the trusted intermediary for which the transfer is placed on hold
  * @param token the transfered token address
  * @param from the sender of the transfered tokens
  * @param to the receiver of the transfered tokens
  * @param amount the amount of transfered tokens
  */
  function addOnHoldTransfer(
    address trustedIntermediary,
    address token,
    address from, 
    address to, 
    uint256 amount
  )
    public override onlyOperator
  {
    uint256 maxBoundary = onHoldMaxBoundary[trustedIntermediary]++;
    onHoldTransfers[trustedIntermediary][maxBoundary] = OnHoldTransfer(
      token, TRANSFER_ONHOLD, from, to, amount
    );
    emit TransferOnHold(
      trustedIntermediary,
      address(token), 
      from, 
      to, 
      amount
    );
  }

  /**
  * @dev Fetch on hold transfers to be processed by a specific trusted intermediary
  * @param trustedIntermediary the trusted intermediary for which on hold transfers will be fetched
  * @return length the number of on hold transfers
  * @return id the array of ids for on hold transfers
  * @return token the array of token addresses for on hold transfers
  * @return from the array of sender addresses for on hold transfers
  * @return to the array of receiver addresses for on hold transfers
  * @return amount the array of amounts for on hold transfers
  */
  function getOnHoldTransfers(address trustedIntermediary)
    public override view returns (
      uint256 length,
      uint256[] memory id,
      address[] memory token, 
      address[] memory from, 
      address[] memory to, 
      uint256[] memory amount
    ) 
  {
    uint256 minBoundary = onHoldMinBoundary[trustedIntermediary];
    uint256 maxBoundary = onHoldMaxBoundary[trustedIntermediary];
    uint256 initLength = maxBoundary-minBoundary;
    id = new uint256[](initLength);
    token = new address[](initLength);
    from = new address[](initLength);
    to = new address[](initLength);
    amount = new uint256[](initLength);
    for (uint256 i = minBoundary; i < maxBoundary; i++) {
      OnHoldTransfer memory transfer = onHoldTransfers[trustedIntermediary][i];
      if (transfer.decision == TRANSFER_ONHOLD) {
        /* because of local variable number limitation, length is used as an index */
        id[length] = i;
        token[length] = transfer.token;
        from[length] = transfer.from;
        to[length] = transfer.to;
        amount[length] = transfer.amount;
        length++;
      }
    }
    return (length, id, token, from, to, amount);
  }

  /**
  * @dev Processes on hold transfers
  * @dev Intended to be called from a trusted intermediary key
  * @dev Transfer decision: 1 = Approve, 2 = Reject
  * @dev Emits either a TransferApproved or a TransferRejected event that can be listened by wallets for improved UX experience
  * @dev When transfer is approved, tokens are transfered to the receiver of the tokens
  * @dev When transfer is rejected, tokens are transfered back to the sender of the tokens
  * @dev If transfer is not on-hold, it will be ignored without notification
  * @param transfers array of transfer ids to process
  * @param transferDecisions array of transfer decisions applied to transfers
  * @param skipMinBoundaryUpdate whether to skip the minBoundary update or not. Updating minBoundary can result in out of gas exception.
  * Skipping the update will process the transfers and the user will be able to update minBoundary by calling the updateOnHoldMinBoundary multiple times
  */
  function processOnHoldTransfers(uint256[] calldata transfers, uint8[] calldata transferDecisions, bool skipMinBoundaryUpdate) external override {
    require(transfers.length == transferDecisions.length, "UR06");
    uint256 minBoundary = onHoldMinBoundary[_msgSender()];
    uint256 maxBoundary = onHoldMaxBoundary[_msgSender()];
    for (uint256 i = 0; i < transfers.length; i++) {
      /* Only process on-hold transfers, other statuses are ignored */
      if (onHoldTransfers[_msgSender()][transfers[i]].decision == TRANSFER_ONHOLD) {
        if (transferDecisions[i] == TRANSFER_APPROVE) {
          onHoldTransfers[_msgSender()][transfers[i]].decision = TRANSFER_APPROVE;
          _approveOnHoldTransfer(transfers[i]);
        } else {
          onHoldTransfers[_msgSender()][transfers[i]].decision = TRANSFER_REJECT;
          _rejectOnHoldTransfer(transfers[i]);
        }
      }
    }
    if (!skipMinBoundaryUpdate) {
      _updateOnHoldMinBoundary(_msgSender(), minBoundary, maxBoundary);
    }
  }

  /**
  * @dev Updates the minBoundary index but limiting iterations to avoid out of gas exceptions
  * @dev Intended to be called from a trusted intermediary key
  * @param maxIterations number of iterations allowed for the loop
  */
  function updateOnHoldMinBoundary(uint256 maxIterations) public override {
    uint256 minBoundary = onHoldMinBoundary[_msgSender()];
    uint256 maxBoundary = onHoldMaxBoundary[_msgSender()];
    if (minBoundary + maxIterations < maxBoundary) {
      maxBoundary = minBoundary + maxIterations;
    }
    _updateOnHoldMinBoundary(_msgSender(), minBoundary, maxBoundary);
  }

  /**
  * @dev Called by user to cancel transfers for a specific trusted intermediary and get his tokens back
  * @dev Throws UR07 if any of the transfer does not have user address as the sender
  * @dev Emits a TransferCancelled event that can be listened by wallets for improved UX experience
  * @param trustedIntermediary the trusted intermediary address for which the transfers are on hold
  * @param transfers array of transfer ids on hold with the trusted intermediary
  * @param skipMinBoundaryUpdate whether to skip the minBoundary update or not. Updating minBoundary can result in out of gas exception.
  * Skipping the update will process the transfers and the user will be able to update minBoundary by calling the updateOnHoldMinBoundary multiple times
  */
  function cancelOnHoldTransfers(address trustedIntermediary, uint256[] calldata transfers, bool skipMinBoundaryUpdate) external {
    uint256 minBoundary = onHoldMinBoundary[trustedIntermediary];
    uint256 maxBoundary = onHoldMaxBoundary[trustedIntermediary];
    for (uint256 i = 0; i < transfers.length; i++) {
      OnHoldTransfer memory transfer = onHoldTransfers[trustedIntermediary][transfers[i]];
      require(transfer.from == _msgSender(), "UR07");
      require(onHoldTransfers[trustedIntermediary][transfers[i]].decision == TRANSFER_ONHOLD, "UR09");
      onHoldTransfers[trustedIntermediary][transfers[i]].decision = TRANSFER_CANCEL;
      require(IERC20Detailed(transfer.token).transfer(transfer.from, transfer.amount), "UR08");
      emit TransferCancelled(
        trustedIntermediary, 
        address(transfer.token), 
        transfer.from, 
        transfer.to, 
        transfer.amount
      );
    }
    if (!skipMinBoundaryUpdate) {
      _updateOnHoldMinBoundary(trustedIntermediary, minBoundary, maxBoundary);
    }
  }

  /**
  * @dev Approves on hold transfer
  * @dev Throws UR08 if token transfer is not successful
  * @param transferIndex the id of the transfer to approve
  */
  function _approveOnHoldTransfer(uint256 transferIndex) internal {
    /* Send the token to the transfer recipient */
    OnHoldTransfer memory transfer = onHoldTransfers[_msgSender()][transferIndex];
    _updateTransfers(
      IGovernable(transfer.token).realm(),
      transfer.from, 
      transfer.to, 
      IPriceable(transfer.token).convertTo(transfer.amount, REF_CURRENCY, MAX_DECIMALS)
    );
    require(IERC20Detailed(transfer.token).transfer(transfer.to, transfer.amount), "UR08");
    emit TransferApproved(
      _msgSender(), 
      address(transfer.token), 
      transfer.from, 
      transfer.to, 
      transfer.amount
    );
  }

  /**
  * @dev Rejects on hold transfer
  * @dev Throws UR08 if token transfer is not successful
  * @param transferIndex the id of the transfer to reject
  */
  function _rejectOnHoldTransfer(uint256 transferIndex) internal {
    /* Send the tokens back to the transfer originator */
    OnHoldTransfer memory transfer = onHoldTransfers[_msgSender()][transferIndex];
    require(IERC20Detailed(transfer.token).transfer(transfer.from, transfer.amount), "UR08");
    emit TransferRejected(
      _msgSender(), 
      address(transfer.token), 
      transfer.from, 
      transfer.to, 
      transfer.amount
    );
  }

  /**
  * @dev Updates transfer history registries
  * @param _realm the realm (group) of the exchanged token
  * @param _from the sender of the tokens
  * @param _to the receiver of the tokens
  * @param _value transfered tokens value converted in CHF
  */
  function _updateTransfers(
    address _realm, 
    address _from, 
    address _to, 
    uint256 _value
  ) 
    internal
  {
    uint256 month = _getMonth(0);
    
    /* Current contract is not bound by transfer rules */
    if (_from != address(this) && _to != address(this)) {
      if (_from != address(0)) {
        addressTransfers[_realm][_from][month].out_ = addressTransfers[_realm][_from][month].out_.add(_value);
      }
      if (_to != address(0)) { 
        addressTransfers[_realm][_to][month].in_ = addressTransfers[_realm][_to][month].in_.add(_value);
      }
    }
  }

  /**
   * @dev Registers a new user corresponding to an address and sets its initial attributes
   * @param _address the address to register
   * @param _attributeKeys array of keys of attributes to set
   * @param _attributeValues array of values of attributes to set
   */
  function _registerUser(address _address, uint256[] memory _attributeKeys, uint256[] memory _attributeValues)
    internal
  {
    uint256 _userCount = userCount[_msgSender()] + 1;
    addressUsers[_msgSender()][_address] = _userCount;
    userAddresses[_msgSender()][_userCount].push(_address);
    userCount[_msgSender()] = _userCount;

    emit AddressAttached(_msgSender(), _userCount, _address);
    _updateUserAttributes(_userCount, _attributeKeys, _attributeValues);
  }

  /**
   * @dev Updates attributes for a user
   * @param _userId the user id for which the attributes are updated
   * @param _attributeKeys array of keys of attributes to set
   * @param _attributeValues array of values of attributes to set
   */
  function _updateUserAttributes(uint256 _userId, uint256[] memory _attributeKeys, uint256[] memory _attributeValues) 
    internal 
  {
    for (uint256 i = 0; i < _attributeKeys.length; i++) {
      userAttributes[_msgSender()][_userId][_attributeKeys[i]] = _attributeValues[i];
    }
    emit UpdatedUserAttributes(_msgSender(), _userId, _attributeKeys, _attributeValues);
  }

  /**
   * @dev Attach an address to an existing user
   * @param _userId the user id to which the address will be attached
   * @param _address the address to attach
   */
  function _attachAddress(uint256 _userId, address _address) internal {
    require(addressUsers[_msgSender()][_address] == 0, "UR02");
    addressUsers[_msgSender()][_address] = _userId;
    userAddresses[_msgSender()][_userId].push(_address);

    emit AddressAttached(_msgSender(), _userId, _address);
  }

  /**
   * @dev Detach an address from a user
   * @param _address address to detach
   */
  function _detachAddress(address _address) internal {
    uint256 addressUserId = addressUsers[_msgSender()][_address];
    require(addressUserId != 0, "UR04");
    delete addressUsers[_msgSender()][_address];
    uint256 userAddressesLength = userAddresses[_msgSender()][addressUserId].length;
    for (uint256 i = 0; i < userAddressesLength; i++) {
      if (userAddresses[_msgSender()][addressUserId][i] == _address) {
        /* For gas efficiency, we only delete the slot and accept that address 0x0 can be present */
        delete userAddresses[_msgSender()][addressUserId][i];
        break;
      }
    }
    emit AddressDetached(_msgSender(), addressUserId, _address);
  }

  /**
   * @dev Checks if the user id passed in parameter is not expired
   * @param _trustedIntermediary the reference trusted intermediary of the user
   * @param _userId the userId to be checked
   * @return true if a user was found for the trusted intermediary and is not expired, false otherwise
   */
  function _isValid(address _trustedIntermediary, uint256 _userId) internal view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return userAttributes[_trustedIntermediary][_userId][USER_VALID_UNTIL_KEY] > now;
  }

  /**
  * @dev Returns the CHF amount transfered (IN) by an address for a 31 days period for a specific realm
  * @param _realm the realm for which we want the amount to be returned
  * @param _trustedIntermediaries array of trustedIntermediaries in which we lookup the address
  * @param _address address to lookup
  * @return the CHF amount transfered (IN) by an address for the period for a specific realm 
  */
  function _monthlyInTransfers(
    address _realm,
    address[] memory _trustedIntermediaries,
    address _address
  ) 
    internal view returns (uint256) 
  {
    uint256 _userId;
    address _trustedIntermediary;
    (_userId, _trustedIntermediary) = _getUser(_trustedIntermediaries, _address);
    if (_userId == 0) {
      return addressTransfers[_realm][_address][_getMonth(0)].in_;
    }
    uint256 amount = 0;
    for (uint256 i = 0; i < userAddresses[_trustedIntermediary][_userId].length; i++) {
      amount = amount.add(
        addressTransfers[_realm][userAddresses[_trustedIntermediary][_userId][i]][_getMonth(0)].in_
      );
    }
    return amount;
  }

  /**
  * @dev Returns the CHF amount transfered (OUT) by an address for a 31 days period for a specific realm
  * @param _realm the realm for which we want the amount to be returned
  * @param _trustedIntermediaries array of trustedIntermediaries in which we lookup the address
  * @param _address address to lookup
  * @return the CHF amount transfered (OUT) by an address for the period for a specific realm 
  */
  function _monthlyOutTransfers(
    address _realm,
    address[] memory _trustedIntermediaries,
    address _address
  ) 
    internal view returns (uint256) 
  {
    uint256 _userId;
    address _trustedIntermediary;
    (_userId, _trustedIntermediary) = _getUser(_trustedIntermediaries, _address);
    if (_userId == 0) {
      return addressTransfers[_realm][_address][_getMonth(0)].out_;
    }
    uint256 amount = 0;
    for (uint256 i = 0; i < userAddresses[_trustedIntermediary][_userId].length; i++) {
      amount = amount.add(
        addressTransfers[_realm][userAddresses[_trustedIntermediary][_userId][i]][_getMonth(0)].out_
      );
    }
    return amount;
  }

  /**
  * @dev Returns the CHF amount transfered (IN) by an address for a 12 months period for a specific realm
  * @param _realm the realm for which we want the amount to be returned
  * @param _trustedIntermediaries array of trustedIntermediaries in which we lookup the address
  * @param _address address to lookup
  * @return the CHF amount transfered (IN) by an address for the period for a specific realm 
  */
  function _yearlyInTransfers(
    address _realm,
    address[] memory _trustedIntermediaries,
    address _address
  ) 
    internal view returns (uint256) 
  {
    uint256 _userId;
    address _trustedIntermediary;
    (_userId, _trustedIntermediary) = _getUser(_trustedIntermediaries, _address);
    uint256 amount = 0;
    if (_userId == 0) {
      for (uint256 i = 0; i < 12; i++) {
        amount = amount.add(addressTransfers[_realm][_address][_getMonth(i)].in_);
      }
      return amount;
    }
    for (uint256 i = 0; i < 12; i++) {
      for (uint256 j = 0; j < userAddresses[_trustedIntermediary][_userId].length; j++) {
        amount = amount.add(
          addressTransfers[_realm][userAddresses[_trustedIntermediary][_userId][j]][_getMonth(i)].in_
        );
      }
    }
    return amount;
  }

  /**
  * @dev Returns the CHF amount transfered (OUT) by an address for a 12 months period for a specific realm
  * @param _realm the realm for which we want the amount to be returned
  * @param _trustedIntermediaries array of trustedIntermediaries in which we lookup the address
  * @param _address address to lookup
  * @return the CHF amount transfered (OUT) by an address for the period for a specific realm 
  */
  function _yearlyOutTransfers(
    address _realm,
    address[] memory _trustedIntermediaries,
    address _address
  ) 
    internal view returns (uint256) 
  {
    uint256 _userId;
    address _trustedIntermediary;
    (_userId, _trustedIntermediary) = _getUser(_trustedIntermediaries, _address);
    uint256 amount = 0;
    if (_userId == 0) {
      for (uint256 i = 0; i < 12; i++) {
        amount = amount.add(addressTransfers[_realm][_address][_getMonth(i)].out_);
      }
      return amount;
    }
    for (uint256 i = 0; i < 12; i++) {
      for (uint256 j = 0; j < userAddresses[_trustedIntermediary][_userId].length; j++) {
        amount = amount.add(
          addressTransfers[_realm][userAddresses[_trustedIntermediary][_userId][j]][_getMonth(i)].out_
        );
      }
    }
    return amount;
  }

  /**
   * @dev fetch the userId associated to the provided address registered by trusted intermediaries
   * @dev The algorithm loops through each trusted intermediary and returns the first userId found 
   * @dev even if the user exists for next trusted intermediaries
   * @param _trustedIntermediaries array of trusted intermediaries to look the address for
   * @param _address address to look for
   * @return userId the user id found, 0 if not found
   * @return the address of the first trusted intermediary for which the user was found, 0x0 if no user was found
   */
  function _getUser(address[] memory _trustedIntermediaries, address _address) 
    internal view returns (uint256, address) 
  {
    uint256 _userId;
    for (uint256 i = 0; i < _trustedIntermediaries.length; i++) {
      _userId = addressUsers[_trustedIntermediaries[i]][_address];
      if (_userId != 0) {
        return (_userId, _trustedIntermediaries[i]);
      }
    }
    return (0, address(0));
  }

  /**
  * @dev Returns the month number based on the current date and the offset number of seconds in the past
  * @dev As we compute 31 days long month, it is assumed that the month number will not be accurate
  */
  function _getMonth(uint256 offset) internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    uint256 _date = now - (offset * MONTH);
    return _date - (_date % MONTH);
  }

  /* 
  * @dev Updates the minBoundary index
  * @param trustedIntermediary the trusted intermediary
  * @param minBoundary the initial min boundary
  * @param maxBoundary the final max boundary
  */
  function _updateOnHoldMinBoundary(address trustedIntermediary, uint256 minBoundary, uint256 maxBoundary) internal {
    for (uint256 i = minBoundary; i < maxBoundary; i++) {
      if (onHoldTransfers[trustedIntermediary][i].decision != TRANSFER_ONHOLD) {
        minBoundary++;
      } else {
        break;
      }
    }
    onHoldMinBoundary[trustedIntermediary] = minBoundary;
  }
}