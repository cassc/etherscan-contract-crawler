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
import "../access/Roles.sol";
import "./abstract/SeizableBridgeERC20.sol";
import "../interfaces/IRulable.sol";
import "../interfaces/ISuppliable.sol";
import "../interfaces/IMintable.sol";
import "../interfaces/IContactable.sol";
import "../interfaces/IProcessor.sol";
import "../interfaces/IBulkTransferable.sol";
import "../interfaces/IERC2612.sol";
import "../interfaces/IERC3009.sol";
import "./utils/EIP712.sol";

/**
 * @title BridgeToken
 * @dev BridgeToken contract
 *
 * Error messages
 * SU01: Caller is not supplier
 * RU01: Rules and rules params don't have the same length
 * RE01: Rule id overflow
 * EX01: Authorization is expired
 * EX02: Authorization is not valid yet
 * EX03: Authorization is already used or cancelled
 * SI01: Invalid signature 
 * BK01: To array is not the same size as values array
**/


contract BridgeToken is Initializable, IContactable, IRulable, ISuppliable, IMintable, IERC2612, IERC3009, IBulkTransferable, SeizableBridgeERC20 {
  using Roles for Roles.Role;
  using SafeMath for uint256;
  
  bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9; // = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
  bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267; // = keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
  bytes32 public constant APPROVE_WITH_AUTHORIZATION_TYPEHASH = 0x808c10407a796f3ef2c7ea38c0638ea9d2b8a1c63e3ca9e1f56ce84ae59df73c; // = keccak256("ApproveWithAuthorization(address owner,address spender,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
  bytes32 public constant INCREASE_APPROVAL_WITH_AUTHORIZATION_TYPEHASH = 0x9a42d39fe98978ff30e5bb6104a6ce6f70ac074c10013f1bce9743e2dccce41b; // = keccak256("IncreaseApprovalWithAuthorization(address owner,address spender,uint256 increment,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
  bytes32 public constant DECREASE_APPROVAL_WITH_AUTHORIZATION_TYPEHASH = 0x604bdf0208a879f7d9fa63ff2f539804aaf6f7876eaa13d531bdc957f1c0284f; // = keccak256("DecreaseApprovalWithAuthorization(address owner,address spender,uint256 decrement,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
  bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH = 0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429; // = keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")

  Roles.Role internal _suppliers;
  uint256[] internal _rules;
  uint256[] internal _rulesParams;
  string internal _contact;
  /* EIP712 Domain Separator */
  bytes32 public DOMAIN_SEPARATOR;
  /* EIP2612 Permit nonces */
  mapping(address => uint256) public nonces;
  /* EIP3009 Authorization States */
  mapping(address => mapping(bytes32 => AuthorizationState)) public authorizationStates;

  function initialize(
    address owner,
    IProcessor processor,
    string memory name,
    string memory symbol,
    uint8 decimals,
    address[] memory trustedIntermediaries
  ) 
    public virtual initializer 
  {
    SeizableBridgeERC20.initialize(owner, processor);
    processor.register(name, symbol, decimals);
    _trustedIntermediaries = trustedIntermediaries;
    emit TrustedIntermediariesChanged(trustedIntermediaries);
    _upgradeToV2();
  }

  modifier onlySupplier() {
    require(isSupplier(_msgSender()), "SU01");
    _;
  }

  /* Upgrade helpers */
  function upgradeToV2() public onlyOwner {
    _upgradeToV2();
  }

  /* Mintable */
  function isSupplier(address _supplier) public override view returns (bool) {
    return _suppliers.has(_supplier);
  }

  function addSupplier(address _supplier) public override onlyAdministrator {
    _suppliers.add(_supplier);
    emit SupplierAdded(_supplier);
  }

  function removeSupplier(address _supplier) public override onlyAdministrator {
    _suppliers.remove(_supplier);
    emit SupplierRemoved(_supplier);
  }  

  function mint(address _to, uint256 _amount)
    public override onlySupplier hasProcessor
  {
    _processor.mint(_msgSender(), _to, _amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
  }

  function burn(address _from, uint256 _amount)
    public override onlySupplier hasProcessor 
  {
    _processor.burn(_msgSender(), _from, _amount);
    emit Burn(_from, _amount);
    emit Transfer(_from, address(0), _amount);
  }

  /* Rulable */
  function rules() public override view returns (uint256[] memory, uint256[] memory) {
    return (_rules, _rulesParams);
  }
  
  function rule(uint256 ruleId) public override view returns (uint256, uint256) {
    require(ruleId < _rules.length, "RE01");
    return (_rules[ruleId], _rulesParams[ruleId]);
  }

  function canTransfer(
    address _from, address _to, uint256 _amount
  ) 
    public override hasProcessor view returns (bool, uint256, uint256) 
  {
    return _processor.canTransfer(_from, _to, _amount);
  }

  function setRules(
    uint256[] calldata newRules, 
    uint256[] calldata newRulesParams
  ) 
    external override onlyAdministrator
  {
    require(newRules.length == newRulesParams.length, "RU01");
    _rules = newRules;
    _rulesParams = newRulesParams;
    emit RulesChanged(_rules, _rulesParams);
  }

  /* Contactable */
  function contact() external override view returns (string memory) {
    return _contact;
  }

  function setContact(string calldata __contact) external override onlyAdministrator {
    _contact = __contact;
    emit ContactSet(__contact);
  }

  /* EIP2612 - Initial code from https://github.com/centrehq/centre-tokens/blob/master/contracts/v2/Permit.sol */
  function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override hasProcessor {
      require(deadline >= block.timestamp, "EX01");

      bytes memory data = abi.encode(
        PERMIT_TYPEHASH,
        owner,
        spender,
        value,
        nonces[owner]++,
        deadline
      );
      require(
        EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == owner,
        "SI01"
      );

      _approve(owner, spender, value);
  }

  /* EIP3009 - Initial code from https://github.com/centrehq/centre-tokens/blob/master/contracts/v2/GasAbstraction.sol */
  /**
   * @notice Execute a transfer with a signed authorization
   * @param from          Payer's address (Authorizer)
   * @param to            Payee's address
   * @param value         Amount to be transferred
   * @param validAfter    The time after which this is valid (unix time)
   * @param validBefore   The time before which this is valid (unix time)
   * @param nonce         Unique nonce
   * @param v             v of the signature
   * @param r             r of the signature
   * @param s             s of the signature
  */
  function transferWithAuthorization(
    address from,
    address to,
    uint256 value,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override hasProcessor {
    _requireValidAuthorization(from, nonce, validAfter, validBefore);

    bytes memory data = abi.encode(
      TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
      from,
      to,
      value,
      validAfter,
      validBefore,
      nonce
    );
    require(
      EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == from,
      "SI01"
    );

    _markAuthorizationAsUsed(from, nonce);
    _transferFrom(from, to, value);
  }

  /**
  * @notice Update allowance with a signed authorization
  * @param owner         Token owner's address (Authorizer)
  * @param spender       Spender's address
  * @param value         Amount of allowance
  * @param validAfter    The time after which this is valid (unix time)
  * @param validBefore   The time before which this is valid (unix time)
  * @param nonce         Unique nonce
  * @param v             v of the signature
  * @param r             r of the signature
  * @param s             s of the signature
  */
  function approveWithAuthorization(
    address owner,
    address spender,
    uint256 value,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external hasProcessor {
    _requireValidAuthorization(owner, nonce, validAfter, validBefore);

    bytes memory data = abi.encode(
      APPROVE_WITH_AUTHORIZATION_TYPEHASH,
      owner,
      spender,
      value,
      validAfter,
      validBefore,
      nonce
    );
    require(
      EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == owner,
      "SI01"
    );

    _markAuthorizationAsUsed(owner, nonce);
    _approve(owner, spender, value);
  }

  /**
  * @notice Increase approval with a signed authorization
  * @param owner         Token owner's address (Authorizer)
  * @param spender       Spender's address
  * @param increment     Amount of increase in allowance
  * @param validAfter    The time after which this is valid (unix time)
  * @param validBefore   The time before which this is valid (unix time)
  * @param nonce         Unique nonce
  * @param v             v of the signature
  * @param r             r of the signature
  * @param s             s of the signature
  */
  function increaseApprovalWithAuthorization(
    address owner,
    address spender,
    uint256 increment,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external hasProcessor {
    _requireValidAuthorization(owner, nonce, validAfter, validBefore);

    bytes memory data = abi.encode(
      INCREASE_APPROVAL_WITH_AUTHORIZATION_TYPEHASH,
      owner,
      spender,
      increment,
      validAfter,
      validBefore,
      nonce
    );
    require(
      EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == owner,
      "SI01"
    );

    _markAuthorizationAsUsed(owner, nonce);
    _increaseApproval(owner, spender, increment);
  }

  /**
  * @notice Decrease approval with a signed authorization
  * @param owner         Token owner's address (Authorizer)
  * @param spender       Spender's address
  * @param decrement     Amount of decrease in allowance
  * @param validAfter    The time after which this is valid (unix time)
  * @param validBefore   The time before which this is valid (unix time)
  * @param nonce         Unique nonce
  * @param v             v of the signature
  * @param r             r of the signature
  * @param s             s of the signature
  */
  function decreaseApprovalWithAuthorization(
    address owner,
    address spender,
    uint256 decrement,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external hasProcessor {
    _requireValidAuthorization(owner, nonce, validAfter, validBefore);

    bytes memory data = abi.encode(
      DECREASE_APPROVAL_WITH_AUTHORIZATION_TYPEHASH,
      owner,
      spender,
      decrement,
      validAfter,
      validBefore,
      nonce
    );
    require(
      EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == owner,
      "SI01"
    );

    _markAuthorizationAsUsed(owner, nonce);
    _decreaseApproval(owner, spender, decrement);
  }

  /**
  * @notice Attempt to cancel an authorization
  * @dev Works only if the authorization is not yet used.
  * @param authorizer    Authorizer's address
  * @param nonce         Nonce of the authorization
  * @param v             v of the signature
  * @param r             r of the signature
  * @param s             s of the signature
  */
  function cancelAuthorization(
    address authorizer,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    _requireUnusedAuthorization(authorizer, nonce);

    bytes memory data = abi.encode(
      CANCEL_AUTHORIZATION_TYPEHASH,
      authorizer,
      nonce
    );
    require(
      EIP712.recover(DOMAIN_SEPARATOR, v, r, s, data) == authorizer,
      "SI01"
    );

    authorizationStates[authorizer][nonce] = AuthorizationState.Canceled;
    emit AuthorizationCanceled(authorizer, nonce);
  }

  /* Private EIP3009 functions */
  /**
  * @notice Check that an authorization is unused
  * @param authorizer    Authorizer's address
  * @param nonce         Nonce of the authorization
  */
  function _requireUnusedAuthorization(address authorizer, bytes32 nonce) internal view {
    require(
      authorizationStates[authorizer][nonce] == AuthorizationState.Unused,
      "EX03"
    );
  }

  /**
  * @notice Check that authorization is valid
  * @param authorizer    Authorizer's address
  * @param nonce         Nonce of the authorization
  * @param validAfter    The time after which this is valid (unix time)
  * @param validBefore   The time before which this is valid (unix time)
  */
  function _requireValidAuthorization(
    address authorizer,
    bytes32 nonce,
    uint256 validAfter,
    uint256 validBefore
  ) internal view {
    require(
      block.timestamp > validAfter,
      "EX02"
    );
    require(block.timestamp < validBefore, "EX01");
    _requireUnusedAuthorization(authorizer, nonce);
  }

  /**
  * @notice Mark an authorization as used
  * @param authorizer    Authorizer's address
  * @param nonce         Nonce of the authorization
  */
  function _markAuthorizationAsUsed(address authorizer, bytes32 nonce) internal { 
    authorizationStates[authorizer][nonce] = AuthorizationState.Used;
    emit AuthorizationUsed(authorizer, nonce);
  }

  /**
  * @dev bulk transfer tokens to specified addresses
  * @param _to The array of addresses to transfer to.
  * @param _values The array of amounts to be transferred.
  */
  function bulkTransfer(address[] calldata _to, uint256[] calldata _values) external override hasProcessor  
  {
    require(_to.length == _values.length, "BK01");
    for (uint256 i = 0; i < _to.length; i++) {
      _transferFrom(_msgSender(), _to[i], _values[i]);
    }
  }

  /**
  * @dev bulk transfer tokens from one address to multiple specified addresses
  * @param _from address The address which you want to send tokens from
  * @param _to The array of addresses to transfer to.
  * @param _values The array of amounts to be transferred.
  */
  function bulkTransferFrom(address _from, address[] calldata _to, uint256[] calldata _values) external override hasProcessor  
  {
    require(_to.length == _values.length, "BK01");
    uint256 _totalValue = 0;
    uint256 _totalTransfered = 0;
    for (uint256 i = 0; i < _to.length; i++) {
      _totalValue = _totalValue.add(_values[i]);
    }
    require(_totalValue <= _processor.allowance(_from, _msgSender()), "AL01"); 
    for (uint256 i = 0; i < _to.length; i++) {
      bool success;
      address updatedTo;
      uint256 updatedAmount;
      (success, updatedTo, updatedAmount) = _transferFrom(_from, _to[i], _values[i]);
      _totalTransfered = _totalTransfered.add(updatedAmount);
    }
    _processor.decreaseApproval(_from, _msgSender(), _totalTransfered);
  }

  /* Private upgrader logic */
  function _upgradeToV2() internal {
    DOMAIN_SEPARATOR = EIP712.makeDomainSeparator(_processor.name(), "2");
  }

  /* Reserved slots for future use: https://docs.openzeppelin.com/sdk/2.5/writing-contracts.html#modifying-your-contracts */
  uint256[47] private ______gap;
}