/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: NonblockingReceiver.sol
 * @author: OG?? Rewrite: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: LZ non blocking reciever
 * OG Source: https://etherscan.io/address/0xa74ae2c6fca0cedbaef30a8ceef834b247186bcf#code
 * Remember to set all the trustedRemoteLookups with trustedRemoteLookup[chainID] = contract address
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ILayerZeroReceiver.sol";
import "./ILayerZeroEndpoint.sol";
import "../access/MaxAccess.sol";

abstract contract NonblockingReceiver is MaxAccess, ILayerZeroReceiver {

  ILayerZeroEndpoint internal endpoint;

  struct FailedMessages {
    uint payloadLength;
    bytes32 payloadHash;
  }

  mapping(uint16 => mapping(bytes => mapping(uint => FailedMessages))) public failedMessages;
  mapping(uint16 => bytes) public trustedRemoteLookup;

  event TrustedRemoteSet(
    uint16 _chainId
  , bytes _trustedRemote);

  event MessageFailed(
    uint16 _srcChainId
  , bytes _srcAddress
  , uint64 _nonce
  , bytes _payload);

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
        reason: "NonblockingReceiver: This message did not come from the endpoint, you failed, I won!"
      });
    }

    if (
      _srcAddress.length != trustedRemoteLookup[_srcChainId].length ||
      keccak256(_srcAddress) != keccak256(trustedRemoteLookup[_srcChainId])
    ) {
      revert MaxSplaining({
        reason: "NonblockingReceiver: This message did not come from a trusted contract, you failed, I won!"
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
        reason: "NonblockingReceiver: This message did not come internally, you failed, I won!"
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
        reason: "NonblockingReceiver: This message was already executed, you failed, I won!"
      });
    }
    if (
      _payload.length != failedMsg.payloadLength ||
      keccak256(_payload) != failedMsg.payloadHash
    ) {
      revert MaxSplaining({
        reason: "NonblockingReceiver: This message was not stored, you failed, I won!"
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
}