/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title Max-20-UUPS-LZ-Implementation
 * @author Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @dev 
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 Max Flow O2                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./eip/20/IERC20.sol";
import "./eip/20/IERC20Burn.sol";
import "./lib/Safe20.sol";
import "./lib/20.sol";
import "./modules/access/MaxAccess.sol";
import "./lib/Roles.sol";
import "./lib/Lists.sol";
import "./lz/ILayerZeroReceiver.sol";
import "./lz/ILayerZeroEndpoint.sol";
import "./errors/MaxErrors.sol";

abstract contract Max20ImplementationUUPSLZ is Initializable
                                             , MaxErrors
                                             , MaxAccess
                                             , ILayerZeroReceiver
                                             , IERC20 {

  //////////////////////////////////////
  // Storage
  //////////////////////////////////////

  using Lib20 for Lib20.Token;
  using Lists for Lists.Access;
  using Roles for Roles.Role;
  using Safe20 for IERC20;

  Lib20.Token internal token20;
  Roles.Role internal contractRoles;
  Lists.Access internal taxExempt;

  bytes4 constant internal DEVS = 0xca4b208b;
  bytes4 constant internal PENDING_DEVS = 0xca4b208a; // DEVS - 1
  bytes4 constant internal OWNERS = 0x8da5cb5b;
  bytes4 constant internal PENDING_OWNERS = 0x8da5cb5a; // OWNERS - 1
  bytes4 constant internal ADMIN = 0xf851a440;

  address internal Token;
  address internal WToken;
  address internal treasury;

  //////////////////////////////////////
  // LayerZero Storage
  //////////////////////////////////////

  ILayerZeroEndpoint internal endpoint;

  struct FailedMessages {
    uint payloadLength;
    bytes32 payloadHash;
  }

  mapping(uint16 => mapping(bytes => mapping(uint => FailedMessages))) public failedMessages;
  mapping(uint16 => bytes) public trustedRemoteLookup;
  uint256 internal gasForDestinationLzReceive;

  event TrustedRemoteSet(uint16 _chainId, bytes _trustedRemote);
  event EndpointSet(address indexed _endpoint);
  event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

  ///////////////////////
  // MAX-20: Modifiers
  ///////////////////////

  modifier onlyRole(bytes4 role) {
    if (contractRoles.has(role, msg.sender) || contractRoles.has(ADMIN, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  modifier onlyOwner() {
    if (contractRoles.has(OWNERS, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  modifier onlyDev() {
    if (contractRoles.has(DEVS, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  ///////////////////////
  /// MAX-20: Internals
  ///////////////////////

  function __Max20_init(
    string memory _name
  , string memory _symbol
  , uint8 _decimals
  , address _admin
  , address _dev
  , address _owner
  ) internal 
    onlyInitializing() {
    token20.setName(_name);
    token20.setSymbol(_symbol);
    token20.setDecimals(_decimals);
    contractRoles.add(ADMIN, _admin);
    contractRoles.setAdmin(_admin);
    contractRoles.add(DEVS, _dev);
    contractRoles.setDeveloper(_dev);
    contractRoles.add(OWNERS, _owner);
    contractRoles.setOwner(_owner);
  }

  //////////////////////////
  // EIP-20: Token Standard
  //////////////////////////

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return string memory returns the name of the token - e.g. "MyToken".
  function name()
    external
    view
    virtual
    override
    returns (string memory) {
    return token20.getName();
  }

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return string memory returns the symbol of the token. E.g. “HIX”.
  function symbol()
    external
    view
    virtual
    override
    returns (string memory) {
    return token20.getSymbol();
  }

  /// @dev OPTIONAL - This method can be used to improve usability, but interfaces and other
  ///      contracts MUST NOT expect these values to be present.
  /// @return uint8 returns the number of decimals the token uses - e.g. 8, means to divide the
  ///         token amount by 100000000 to get its user representation.
  function decimals()
    external
    view
    virtual
    override
    returns (uint8) {
    return token20.getDecimals();
  }

  /// @dev totalSupply
  /// @return uint256 returns the total token supply.
  function totalSupply()
    external
    view
    virtual
    override
    returns (uint256) {
    return token20.getTotalSupply();
  }

  /// @dev balanceOf
  /// @return balance returns the account balance of another account with address _owner.
  function balanceOf(
    address _owner
  ) external
    view
    virtual
    override
    returns (uint256 balance) {
    balance = token20.getBalanceOf(_owner);
  }

  /// @dev transfer
  /// @return success
  /// @notice Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
  ///         The function SHOULD throw if the message caller’s account balance does not have enough
  ///         tokens to spend.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transfer(
    address _to
  , uint256 _value
  ) external
    virtual
    override
    returns (bool success) {
    if (_to == address(0)) {
      revert MaxSplaining({
        reason: "Max20: to address(0)"
      });
    } else {
      success = token20.doTransfer(msg.sender, _to, _value);
      emit Transfer(msg.sender, _to, _value);
    }
  }

  /// @dev transferFrom
  /// @return success
  /// @notice The transferFrom method is used for a withdraw workflow, allowing contracts to transfer
  ///         tokens on your behalf. This can be used for example to allow a contract to transfer
  ///         tokens on your behalf and/or to charge fees in sub-currencies. The function SHOULD
  ///         throw unless the _from account has deliberately authorized the sender of the message
  ///         via some mechanism.
  /// @notice Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer
  ///         event.
  function transferFrom(
    address _from
  , address _to
  , uint256 _value
  ) external
    virtual
    override
    returns (bool success) {
    uint256 approveBal = this.allowance(_from, msg.sender);
    if (_from == address(0) || _to == address(0)) {
      revert MaxSplaining({
        reason: "Max20: to/from address(0)"
      });
    } else if (approveBal >= _value) {
      revert MaxSplaining({
        reason: "Max20: not approved to spend _value"
      });
    } else {
      success = token20.doTransfer(_from, _to, _value);
      emit Transfer(_from, _to, _value);
    }
  }

  /// @dev approve
  /// @return success
  /// @notice Allows _spender to withdraw from your account multiple times, up to the _value amount.
  ///         If this function is called again it overwrites the current allowance with _value.
  /// @notice To prevent attack vectors like the one described here and discussed here, clients
  ///         SHOULD make sure to create user interfaces in such a way that they set the allowance
  ///         first to 0 before setting it to another value for the same spender. THOUGH The contract
  ///         itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed
  ///         before
  function approve(
    address _spender
  , uint256 _value
  ) external
    virtual
    override
    returns (bool success) {
    success = token20.setApprove(msg.sender, _spender, _value);
    emit Approval(msg.sender, _spender, _value);
  }

  /// @dev allowance
  /// @return remaining uint256 of allowance remaining
  /// @notice Returns the amount which _spender is still allowed to withdraw from _owner.
  function allowance(
    address _owner
  , address _spender
  ) external
    view
    virtual
    override
    returns (uint256 remaining) {
    return token20.getAllowance(_owner, _spender);
  }

  ///////////////////
  /// LayerZero: NBR
  ///////////////////

  // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function lzReceive(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes memory _payload
  ) external
    override {
    if (msg.sender != address(endpoint)) {
      revert MaxSplaining({
        reason: "NBR:1"
      });
    }

    if (
      _srcAddress.length != trustedRemoteLookup[_srcChainId].length ||
      keccak256(_srcAddress) != keccak256(trustedRemoteLookup[_srcChainId])
    ) {
      revert MaxSplaining({
        reason: "NBR:2"
      });
    }

    // try-catch all errors/exceptions
    // having failed messages does not block messages passing
    try this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
      // do nothing
    } catch {
      // error or exception
      failedMessages[_srcChainId][_srcAddress][_nonce] = FailedMessages(_payload.length, keccak256(_payload));
      emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
    }
  }

  // @notice this is the catch all above (should be an internal?)
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function onLzReceive(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes memory _payload
  ) public {

    // only internal transaction
    if (msg.sender != address(this)) {
      revert MaxSplaining({
        reason: "NBR:3"
      });
    }

    // handle incoming message
    _LzReceive( _srcChainId, _srcAddress, _nonce, _payload);
  }

  // @notice internal function to do something in the main contract
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function _LzReceive(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes memory _payload
  ) virtual
    internal;

  // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
  // @param _dstChainId - the destination chain identifier
  // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
  // @param _payload - a custom bytes payload to send to the destination contract
  // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
  // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
  // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
  function _lzSend(
    uint16 _dstChainId
  , bytes memory _payload
  , address payable _refundAddress
  , address _zroPaymentAddress
  , bytes memory _txParam
  ) internal {
    endpoint.send{value: msg.value}(
      _dstChainId
    , trustedRemoteLookup[_dstChainId]
    , _payload, _refundAddress
    , _zroPaymentAddress
    , _txParam);
  }

  // @notice this is to retry a failed message on LayerZero
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  // @param _nonce - the ordered message nonce
  // @param _payload - the payload to be retried
  function retryMessage(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes calldata _payload
  ) external
    payable {
    // assert there is message to retry
    FailedMessages storage failedMsg = failedMessages[_srcChainId][_srcAddress][_nonce];
    if (failedMsg.payloadHash == bytes32(0)) {
      revert MaxSplaining({
        reason: "NBR:4"
      });
    }
    if (
      _payload.length != failedMsg.payloadLength ||
      keccak256(_payload) != failedMsg.payloadHash
    ) {
      revert MaxSplaining({
        reason: "NBR:5"
      });
    }

    // clear the stored message
    failedMsg.payloadLength = 0;
    failedMsg.payloadHash = bytes32(0);

    // execute the message. revert if it fails again
    this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }


  // @notice this is to set all valid incoming messages
  // @param _srcChainId - the source chain identifier
  // @param _trustedRemote - the source chain contract address
  function setTrustedRemote(
    uint16 _chainId
  , bytes calldata _trustedRemote
  ) external
    onlyDev() {
    trustedRemoteLookup[_chainId] = _trustedRemote;
    emit TrustedRemoteSet(_chainId, _trustedRemote);
  }

  // @notice this is to set all valid incoming messages
  // @param _srcChainId - the source chain identifier
  // @param _trustedRemote - the source chain contract address
  function setEndPoint(
    address newEndpoint
  ) external
    onlyDev() {
    endpoint = ILayerZeroEndpoint(newEndpoint);
    emit EndpointSet(newEndpoint);
  }

  /////////////////////////////////////////
  /// EIP-173: Contract Ownership Standard
  /////////////////////////////////////////

  /// @notice Get the address of the owner    
  /// @return The address of the owner.
  function owner()
    view
    external
    returns(address) {
    return contractRoles.getOwner();
  }
	
  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract    
  function transferOwnership(
    address _newOwner
  ) external
    onlyRole(OWNERS) {
    contractRoles.add(OWNERS, _newOwner);
    contractRoles.setOwner(_newOwner);
    contractRoles.remove(OWNERS, msg.sender);
  }

  ////////////////////////////////////////////////////////////////
  /// EIP-173: Contract Ownership Standard, MaxFlowO2's extension
  ////////////////////////////////////////////////////////////////

  /// @dev This is the classic "EIP-173" method of renouncing onlyOwner()  
  function renounceOwnership()
    external 
    onlyRole(OWNERS) {
    contractRoles.setOwner(address(0));
    contractRoles.remove(OWNERS, msg.sender);
  }

  /// @dev This accepts the push-pull method of onlyOwner()
  function acceptOwnership()
    external
    onlyRole(PENDING_OWNERS) {
    contractRoles.add(OWNERS, msg.sender);
    contractRoles.setOwner(msg.sender);
    contractRoles.remove(PENDING_OWNERS, msg.sender);
  }

  /// @dev This declines the push-pull method of onlyOwner()
  function declineOwnership()
    external
    onlyRole(PENDING_OWNERS) {
    contractRoles.remove(PENDING_OWNERS, msg.sender);
  }

  /// @dev This starts the push-pull method of onlyOwner()
  /// @param newOwner: addres of new pending owner role
  function pushOwnership(
    address newOwner
  ) external
    onlyRole(OWNERS) {
    contractRoles.add(PENDING_OWNERS, newOwner);
  }

  //////////////////////////////////////////////
  /// [Not an EIP]: Contract Developer Standard
  //////////////////////////////////////////////

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @return Developer of contract
  function developer()
    external
    view
    returns (address) {
    return contractRoles.getDeveloper();
  }

  /// @dev This renounces your role as onlyDev()
  function renounceDeveloper()
    external
    onlyRole(DEVS) {
    contractRoles.setDeveloper(address(0));
    contractRoles.remove(DEVS, msg.sender);
  }

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @param newDeveloper: addres of new pending Developer role
  function transferDeveloper(
    address newDeveloper
  ) external
    onlyRole(DEVS) {
    contractRoles.add(DEVS, newDeveloper);
    contractRoles.setDeveloper(newDeveloper);
    contractRoles.remove(DEVS, msg.sender);
  }

  /// @dev This accepts the push-pull method of onlyDev()
  function acceptDeveloper()
    external
    onlyRole(PENDING_DEVS) {
    contractRoles.add(DEVS, msg.sender);
    contractRoles.setDeveloper(msg.sender);
    contractRoles.remove(PENDING_DEVS, msg.sender);
  }

  /// @dev This declines the push-pull method of onlyDev()
  function declineDeveloper()
    external
    onlyRole(PENDING_DEVS) {
    contractRoles.remove(PENDING_DEVS, msg.sender);
  }

  /// @dev This starts the push-pull method of onlyDev()
  /// @param newDeveloper: addres of new pending developer role
  function pushDeveloper(
    address newDeveloper
  ) external
    onlyRole(DEVS) {
    contractRoles.add(PENDING_DEVS, newDeveloper);
  }

  //////////////////////////////////////////
  /// [Not an EIP]: Contract Roles Standard
  //////////////////////////////////////////

  /// @dev Returns `true` if `account` has been granted `role`.
  /// @param role: Bytes4 of a role
  /// @param account: Address to check
  /// @return bool true/false if account has role
  function hasRole(
    bytes4 role
  , address account
  ) external
    view
    returns (bool) {
    return contractRoles.has(role, account);
  }

  /// @dev Returns the admin role that controls a role
  /// @param role: Role to check
  /// @return admin role
  function getRoleAdmin(
    bytes4 role
  ) external
    view 
    returns (bytes4) {
    return ADMIN;
  }

  /// @dev Grants `role` to `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to give role to
  function grantRole(
    bytes4 role
  , address account
  ) external
    onlyRole(role) {
    if (role == PENDING_DEVS || role == PENDING_OWNERS) {
      revert Unauthorized();
    } else {
      contractRoles.add(role, account);
    }
  }

  /// @dev Revokes `role` from `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to revoke role from
  function revokeRole(
    bytes4 role
  , address account
  ) external
    onlyRole(role) {
    if (role == PENDING_DEVS || role == PENDING_OWNERS) {
      if (account == msg.sender) {
        contractRoles.remove(role, account);
      } else {
        revert Unauthorized();
      }
    } else {
      contractRoles.remove(role, account);
    }
  }

  /// @dev Renounces `role` from `account`
  /// @param role: Bytes4 of a role
  function renounceRole(
    bytes4 role
  ) external
    onlyRole(role) {
    contractRoles.remove(role, msg.sender);
  }


  //////////////////////////////////////////
  /// EIP-165: Standard Interface Detection
  //////////////////////////////////////////

  /// @dev Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @notice Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(
    bytes4 interfaceID
  ) external
    view
    virtual
    override
    returns (bool) {
    return (
      interfaceID == type(IERC173).interfaceId  ||
      interfaceID == type(IMAX173).interfaceId  ||
      interfaceID == type(IMAXDEV).interfaceId  ||
      interfaceID == type(IRoles).interfaceId  ||
      interfaceID == type(IERC20).interfaceId   
    );
  }
 
  uint256[35] private __gap;
}