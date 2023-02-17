// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../BaseServer.sol";

interface IPolygonBridge {
  function depositFor(
    address user,
    address token,
    bytes calldata depositData
  ) external;
}

/// @notice Contract bridges Sushi to a chain w/ a PoS style bridge
/// @dev two step bridge process w/ approval on bridge and invoking deposit call on manager
contract PosServer is BaseServer {
  address public posManager;
  address public ercBridge;

  constructor(
    uint256 _pid,
    address _minichef,
    address _posManager,
    address _ercBridge
  ) BaseServer(_pid, _minichef) {
    posManager = _posManager;
    ercBridge = _ercBridge;
  }

  /// @dev internal bridge call
  /// @param data is not used
  function _bridge(bytes calldata data) internal override {
    uint256 sushiBalance = sushi.balanceOf(address(this));

    sushi.approve(address(ercBridge), sushiBalance);
    IPolygonBridge(posManager).depositFor(minichef, address(sushi), toBytes(sushiBalance));

    emit BridgedSushi(minichef, sushiBalance);
  }

  function toBytes(uint256 x) internal pure returns (bytes memory b) {
    b = new bytes(32);
    assembly {
      mstore(add(b, 32), x)
    }
  }
}