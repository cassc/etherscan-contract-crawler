// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/libs/CREATE2.sol";
import "src/utils/Proxy.sol";

import "src/commons/receiver/Receiver.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ReceiverHub is Initializable {
  error ReceiverCallError(address _receiver, address _to, uint256 _value, bytes _data, bytes _result);
  
  address public receiverTemplate;
  bytes32 private receiverTemplateCreationCodeHash;

  function __initializeReceiverHub() internal onlyInitializing {
    receiverTemplate = address(new Receiver());
    receiverTemplateCreationCodeHash = keccak256(Proxy.creationCode(address(receiverTemplate)));
  }

  function receiverFor(uint256 _id) public view returns (Receiver) {
    return Receiver(CREATE2.addressOf(address(this), _id, receiverTemplateCreationCodeHash));
  }

  function createReceiver(uint256 _id) internal returns (Receiver) {
    Receiver receiver = Receiver(CREATE2.deploy(_id, Proxy.creationCode(receiverTemplate)));
    receiver.__initializeReceiver();
    return receiver;
  }

  function createIfNeeded(Receiver receiver, uint256 _id) internal returns (Receiver) {
    uint256 receiverCodeSize; assembly { receiverCodeSize := extcodesize(receiver) }
    if (receiverCodeSize != 0) {
      return receiver;
    }

    return createReceiver(_id);
  }

  function useReceiver(uint256 _id) internal returns (Receiver) {
    return createIfNeeded(receiverFor(_id), _id);
  }

  function executeOnReceiver(uint256 _id, address _to, uint256 _value, bytes memory _data) internal returns (bytes memory) {
    return executeOnReceiver(useReceiver(_id), _to, _value, _data);
  }

  function executeOnReceiver(Receiver _receiver, address _to, uint256 _value, bytes memory _data) internal returns (bytes memory) {
    (bool succeed, bytes memory result) = _receiver.execute(payable(_to), _value, _data);
    if (!succeed) revert ReceiverCallError(address(_receiver), _to, _value, _data, result);

    return result;
  }
}