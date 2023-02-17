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
/// @dev takes an operator address in constructor to guard _bridge call
contract ArbitrumServer is BaseServer {
  address public routerAddr;
  address public gatewayAddr;
  address public operatorAddr;

  error NotAuthorizedToBridge();

  constructor(
    uint256 _pid,
    address _minichef,
    address _routerAddr,
    address _gatewayAddr,
    address _operatorAddr
  ) BaseServer(_pid, _minichef) {
    routerAddr = _routerAddr;
    gatewayAddr = _gatewayAddr;
    operatorAddr = _operatorAddr;
  }

  /// @dev internal bridge call
  /// @param data is used: address refundTo, uint256 maxGas, uint256 gasPriceBid, bytes bridgeData
  function _bridge(bytes calldata data) internal override {
    if (msg.sender != operatorAddr) revert NotAuthorizedToBridge();

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

  /// @dev set operator address, to guard _bridge call
  function setOperatorAddr(address newAddy) external onlyOwner {
    operatorAddr = newAddy;
  }
}