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

/// @notice Contract bridges Sushi to chains that use op style bridges
/// @dev requires l2Token and gatewayAddr to be set in the constructor
contract OpStyleServer is BaseServer {
  address public l2Token;
  address public gatewayAddr;

  error NotAuthorizedToBridge();

  constructor(
    uint256 _pid,
    address _minichef,
    address _gatewayAddr,
    address _l2Token
  ) BaseServer(_pid, _minichef) {
    gatewayAddr = _gatewayAddr;
    l2Token = _l2Token;
  }

  /// @dev internal bridge call
  /// @param data is used: uint32 l2Gas, bytes bridgeData
  function _bridge(bytes calldata data) internal override {
    (uint32 l2Gas, bytes memory bridgeData) = abi.decode(data, (uint32, bytes));

    uint256 sushiBalance = sushi.balanceOf(address(this));
    sushi.approve(gatewayAddr, sushiBalance);
    IGatewayBridge(gatewayAddr).depositERC20To(address(sushi), l2Token, minichef, sushiBalance, l2Gas, bridgeData);

    emit BridgedSushi(minichef, sushiBalance);
  }
}