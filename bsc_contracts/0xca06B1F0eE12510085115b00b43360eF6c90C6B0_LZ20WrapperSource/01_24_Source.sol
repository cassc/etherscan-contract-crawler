/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: Implementation of LZ 1822/1967 ERC20
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

import "./Max-20-Burnable-UUPS-LZ.sol";
import "./lib/Safe20.sol";
import "./lib/20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract LZ20WrapperSource is Initializable
                            , Max20BurnUUPSLZ
                            , UUPSUpgradeable {

  using Lib20 for Lib20.Token;
  using Safe20 for IERC20;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    string memory _name
  , string memory _symbol
  , uint8 _deci
  , address _token
  , address _admin
  , address _endpoint
  , uint256 _gas
  ) initializer
    public {
      __Max20_init(_name, _symbol, _deci,  _admin);
      __UUPSUpgradeable_init();
     Token = _token;
     endpoint = ILayerZeroEndpoint(_endpoint);
     bytes memory _trustedRemote = abi.encodePacked(address(this), address(this));
     trustedRemoteLookup[102] = _trustedRemote;
     trustedRemoteLookup[106] = _trustedRemote;
     trustedRemoteLookup[109] = _trustedRemote;
     trustedRemoteLookup[110] = _trustedRemote;
     trustedRemoteLookup[111] = _trustedRemote;
     trustedRemoteLookup[112] = _trustedRemote;
     gasForDestinationLzReceive = _gas;
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(ADMIN)
    override
    {}

  function deposit(
    uint256 amount
  ) external
    virtual
    returns (bool) {
    // Find balance of prior to
    uint256 start = IERC20(Token).balanceOf(address(this));
    // The transfer
    IERC20(Token).safeTransferFrom(msg.sender, address(this), amount);
    // Balance of post transfer
    uint256 finish = IERC20(Token).balanceOf(address(this));
    // The delta (aka to mint)
    uint256 toMint = finish - start;
    // mint and emit event
    token20.mint(msg.sender, toMint);
    emit Transfer(address(0), msg.sender, toMint);
    // burn all tokens on contract
    return true;
  }

  function withdraw(
    uint256 amount
  ) external
    virtual
    returns (bool) {
    uint256 userBal = token20.getBalanceOf(msg.sender);
    if (amount > userBal) {
      revert Unauthorized();
    }
    token20.burn(msg.sender, amount);
    emit Transfer(msg.sender, address(0), amount);
    IERC20(Token).safeTransfer(msg.sender, amount);
    return true;
  }
    

  function setToken(
    address newToken
  ) external
    virtual
    onlyDev() {
    Token = newToken;
  }

  function sourceToken()
    external
    view
    returns (address) {
    return Token;
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
    if (_amount > userBal) {
      revert Unauthorized();
    }
    if (trustedRemoteLookup[_chainId].length == 0) {
      revert MaxSplaining({
        reason: "Token: TR not set"
      });
    }

    // burn , eliminating it from circulation on src chain
    token20.burn(msg.sender, _amount);
    emit Transfer(msg.sender, address(0), _amount);

    // abi.encode() the payload with the values to send
    bytes memory payload = abi.encode(
                             msg.sender
                           , _amount);

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
  ) external
    onlyDev() {
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