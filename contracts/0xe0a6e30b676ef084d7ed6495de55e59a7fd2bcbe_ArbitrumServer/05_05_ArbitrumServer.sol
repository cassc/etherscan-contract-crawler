// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../BaseServer.sol";

interface IArbitrumBridge {
  function outboundTransferCustomRefund(
    address _l1Token,
    address _refundTo,
    address _to,
    uint256 _amount,
    uint256 _maxGas,
    uint256 _gasPriceBid,
    bytes calldata _data
  ) external payable returns (bytes memory);
}

/// @notice Contract bridges Sushi to arbitrum chains using their official bridge
/// @dev requires routerAddr and gatewayAddr to be set in the constructor
contract ArbitrumServer is BaseServer {
  address public routerAddr;
  address public gatewayAddr;

  error NotAuthorizedToBridge();

  constructor(
    uint256 _pid,
    address _minichef,
    address _routerAddr,
    address _gatewayAddr
  ) BaseServer(_pid, _minichef) {
    routerAddr = _routerAddr;
    gatewayAddr = _gatewayAddr;
  }

  /// @dev internal bridge call
  /// @param data is used: address refundTo, uint256 maxGas, uint256 gasPriceBid, bytes bridgeData
  function _bridge(bytes calldata data) internal override {
    (address refundTo, uint256 maxGas, uint256 gasPriceBid, bytes memory bridgeData) = abi.decode(
      data,
      (address, uint256, uint256, bytes)
    );

    uint256 sushiBalance = sushi.balanceOf(address(this));

    sushi.approve(gatewayAddr, sushiBalance);
    IArbitrumBridge(routerAddr).outboundTransferCustomRefund{value: msg.value}(
      address(sushi),
      refundTo,
      minichef,
      sushiBalance,
      maxGas,
      gasPriceBid,
      bridgeData
    );

    emit BridgedSushi(minichef, sushiBalance);
  }
}