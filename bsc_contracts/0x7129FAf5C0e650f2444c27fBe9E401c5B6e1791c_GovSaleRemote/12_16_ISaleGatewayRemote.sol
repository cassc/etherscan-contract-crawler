// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../layerZero/interfaces/ILayerZeroEndpoint.sol";

interface ISaleGatewayRemote {
  function buyToken(
    address,
    bytes calldata,
    bytes calldata,
    uint256
  ) external payable;

  function lzEndpoint() external returns (ILayerZeroEndpoint);
}