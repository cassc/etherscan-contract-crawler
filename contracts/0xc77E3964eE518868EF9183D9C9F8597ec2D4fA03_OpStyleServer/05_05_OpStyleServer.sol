// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../BaseServer.sol";

interface IGatewayBridge {
  function depositERC20To(
    address _l1Token,
    address _l2Token,
    address _to,
    uint256 _amount,
    uint32 _l2Gas,
    bytes calldata _data
  ) external;
}

/// @notice Contract bridges Sushi to chains that use op style bridges using their gateway bridge
/// @dev takes an operator address in constructor to guard _bridge calls
contract OpStyleServer is BaseServer {
  address public l2Token;
  address public gatewayAddr;
  address public operatorAddr;

  error NotAuthorizedToBridge();

  constructor(
    uint256 _pid,
    address _minichef,
    address _gatewayAddr,
    address _l2Token,
    address _operatorAddr
  ) BaseServer(_pid, _minichef) {
    gatewayAddr = _gatewayAddr;
    l2Token = _l2Token;
    operatorAddr = _operatorAddr;
  }

  /// @dev internal bridge call
  /// @param data is used: uint32 l2Gas, bytes bridgeData
  function _bridge(bytes calldata data) internal override {
    if (msg.sender != operatorAddr) revert NotAuthorizedToBridge();

    (uint32 l2Gas, bytes memory bridgeData) = abi.decode(data, (uint32, bytes));

    uint256 sushiBalance = sushi.balanceOf(address(this));
    sushi.approve(gatewayAddr, sushiBalance);
    IGatewayBridge(gatewayAddr).depositERC20To(address(sushi), l2Token, minichef, sushiBalance, l2Gas, bridgeData);

    emit BridgedSushi(minichef, sushiBalance);
  }

  /// @dev set operator address, to guard _bridge calls
  function setOperatorAddr(address newAddy) external onlyOwner {
    operatorAddr = newAddy;
  }
}