// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface IUSDCBridge {
  event MessageServiceUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );
  event RemoteUSDCBridgeSet(address indexed newRemoteUSDCBridge);
  event Deposited(
    address indexed depositor,
    uint256 amount,
    address indexed to
  );
  event ReceivedFromOtherLayer(
    address indexed recipient,
    uint256 indexed amount
  );

  error NoBurnCapabilities(address addr);
  error AmountTooBig(uint256 amount, uint256 limit);
  error NotMessageService(address addr, address messageService);
  error ZeroAmountNotAllowed(uint256 amount);
  error NotFromRemoteUSDCBridge(address sender, address remoteUSDCBridge);
  error ZeroAddressNotAllowed(address addr);
  error RemoteUSDCBridgeNotSet();
  error SenderBalanceTooLow(uint256 amount, uint256 balance);
  error SameMessageServiceAddr(address messageService);
  error RemoteUSDCBridgeAlreadySet(address remoteUSDCBridge);

  function receiveFromOtherLayer(address to, uint256 amount) external;
}