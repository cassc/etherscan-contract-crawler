// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../BaseServer.sol";

// maybe add owner for bridge? not sure if anything bad can happen if gas prices aren't set correctly

interface IArbitrumBridge {
  // going to be deprecated
  function outboundTransfer(
    address _l1Token,
    address _to,
    uint256 _amount,
    uint256 _maxGas,
    uint256 _gasPriceBid,
    bytes calldata _data
  ) external payable returns (bytes memory res);

  function outboundTransferCustomRefund(
    address _l1Token,
    address _refundTo,
    address _to,
    uint256 _amount,
    uint256 _maxGas,
    uint256 _gasPriceBid,
    bytes calldata _data
  ) external payable returns (bytes memory res);
}

contract ArbitrumServer is BaseServer {
  address public constant bridgeAddr = 0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef;

  event BridgedSushi(address indexed minichef, uint256 indexed amount);

  constructor(uint256 _pid, address _minichef) BaseServer(_pid, _minichef) {}

  function _bridge() internal override {}

  function _bridgeWithData(bytes calldata data) internal override {
    (
      address _l1Token, 
      address _refundTo,
      address _to,
      uint256 _amount,
      uint256 _maxGas,
      uint256 _gasPriceBid,
      bytes memory _data
    ) = abi.decode(data, (address, address, address, uint256, uint256, uint256, bytes));

    uint256 sushiBalance = sushi.balanceOf(address(this));

    sushi.approve(bridgeAddr, sushiBalance);
    IArbitrumBridge(bridgeAddr).outboundTransferCustomRefund(
      _l1Token,
      _refundTo,
      _to,
      _amount,
      _maxGas,
      _gasPriceBid,
      _data
    );
    emit BridgedSushi(minichef, sushiBalance);
  }
}