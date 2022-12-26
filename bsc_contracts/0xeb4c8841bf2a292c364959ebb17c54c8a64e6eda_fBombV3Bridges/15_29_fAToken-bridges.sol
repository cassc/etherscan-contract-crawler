/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Fantom Bomb, LZ ERC 20 for BOMB/wBOMB on destination chains
 * @author Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
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

import "./Max-20-UUPS-LZ.sol";
import "./lib/Safe20.sol";
import "./lib/20.sol";
import "./lib/Lists.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract fTokenOC is Initializable
                   , Max20ImplementationUUPSLZ
                   , UUPSUpgradeable {

  using Lib20 for Lib20.Token;
  using Lists for Lists.Access;
  using Safe20 for IERC20;

  function disable()
    external {
    _disableInitializers();
  }

  function initialize(
    string memory _name
  , string memory _symbol
  , address _admin
  , address _dev
  , address _owner
  ) initializer
    public {
      __Max20_init(_name, _symbol, 18,  _admin, _dev, _owner);
      __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(ADMIN)
    override
    {}

  function addExempt(
    address newAddress
  ) external
    virtual
    onlyDev() {
    taxExempt.add(newAddress);
  }

  function removeExempt(
    address newAddress
  ) external
    virtual
    onlyDev() {
    taxExempt.remove(newAddress);
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
    override (Max20ImplementationUUPSLZ)
    returns (bool success) {
    if (_to == address(0)) {
      revert MaxSplaining({
        reason: "Max20: to address(0)"
      });
    } else {
      if (taxExempt.onList(_to) || taxExempt.onList(msg.sender)) {
        success = token20.doTransfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
      } else {
        uint256 transValue = _value * 99 / 100;
        success = token20.doTransfer(msg.sender, _to, transValue);
        emit Transfer(msg.sender, _to, transValue);
        token20.burn(msg.sender, _value - transValue);
        emit Transfer(msg.sender, address(0), _value - transValue);
      }
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
    override (Max20ImplementationUUPSLZ)
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
      if (taxExempt.onList(_to) || taxExempt.onList(_from)) {
        success = token20.doTransfer(_from, _to, _value);
        emit Transfer(_from, _to, _value);
      } else {
        uint256 transValue = _value * 99 / 100;
        success = token20.doTransfer(_from, _to, transValue);
        emit Transfer(_from, _to, transValue);
        token20.burn(_from, _value - transValue);
        emit Transfer(_from, address(0), _value - transValue);
      }
    }
  }

  function setTres(
    address newAddress
  ) external
    virtual
    onlyDev() {
    treasury = newAddress;
  }

  // @notice: This function transfers the ft from your address on the 
  //          source chain to the same address on the destination chain
  // @param _chainId: the uint16 of desination chain (see LZ docs)
  // @param _amount: amount to be sent
  function traverseChains(
    uint16 _chainId
  , uint256 _amount
  ) public
    virtual
    payable {
    uint256 userBal = token20.getBalanceOf(msg.sender);
    if (_amount >= userBal) {
      revert Unauthorized();
    }
    if (trustedRemoteLookup[_chainId].length == 0) {
      revert MaxSplaining({
        reason: "Token: TR not set"
      });
    }

    // set the amout to burn and send to treasury
    uint256 onePer = _amount / 100;
    uint256 toTraverse = _amount - (onePer * 2);

    // burn FT, eliminating it from circulation on src chain
    token20.burn(msg.sender, _amount - onePer);
    emit Transfer(msg.sender, address(0), _amount - onePer);
    token20.doTransfer(msg.sender, treasury, onePer);
    emit Transfer(msg.sender, treasury, onePer);

    // abi.encode() the payload with the values to send
    bytes memory payload = abi.encode(
                             msg.sender
                           , toTraverse);

    // encode adapterParams to specify more gas for the destination
    uint16 version = 1;
    bytes memory adapterParams = abi.encodePacked(
                                   version
                                 , gasForDestinationLzReceive);

    // get the fees we need to pay to LayerZero + Relayer to cover message delivery
    // you will be refunded for extra gas paid
    (uint messageFee, ) = endpoint.estimateFees(
                            _chainId
                          , address(this)
                          , payload
                          , false
                          , adapterParams);

    // revert this transaction if the fees are not met
    if (messageFee > msg.value) {
      revert MaxSplaining({
        reason: "Token: message fee low"
      });
    }

    // send the transaction to the endpoint
    endpoint.send{value: msg.value}(
      _chainId,                           // destination chainId
      trustedRemoteLookup[_chainId],      // destination address of nft contract
      payload,                            // abi.encoded()'ed bytes
      payable(msg.sender),                // refund address
      address(0x0),                       // 'zroPaymentAddress' unused for this
      adapterParams                       // txParameters 
    );
  }

  // @notice: just in case this fixed variable limits us from future integrations
  // @param newVal: new value for gas amount
  function setGasForDestinationLzReceive(
    uint newVal
  ) external onlyDev() {
    gasForDestinationLzReceive = newVal;
  }

  // @notice internal function to mint FT from migration
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function _LzReceive(
    uint16 _srcChainId
  , bytes memory _srcAddress
  , uint64 _nonce
  , bytes memory _payload
  ) override
    internal {
    // decode
    (address toAddr, uint256 amount) = abi.decode(_payload, (address, uint256));

    // mint the tokens back into existence on destination chain
    token20.mint(toAddr, amount);
    emit Transfer(address(0), toAddr, amount);
  }

  // @notice: will return gas value for LZ
  // @return: uint for gas value
  function currentLZGas()
    external
    view
    returns (uint256) {
    return gasForDestinationLzReceive;
  }  
}