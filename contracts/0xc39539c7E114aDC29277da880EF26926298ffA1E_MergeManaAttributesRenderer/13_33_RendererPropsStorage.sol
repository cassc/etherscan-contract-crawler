// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '../libraries/SSTORE2Map.sol';

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/renderers/LayerCompositeRenderer.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';

contract RendererPropsStorage is Ownable {
  uint256 public constant MAX_UINT_16 = 0xFFFF;

  // index starts from zero, useful to use the 0th index as a empty case.
  uint16 public currentMaxRendererPropsIndex = 0;

  constructor() {}

  function batchAddRendererProps(bytes[] calldata rendererProps)
    public
    onlyOwner
  {
    for (uint16 i = 0; i < rendererProps.length; ++i) {
      SSTORE2Map.write(
        bytes32(uint256(currentMaxRendererPropsIndex + i)),
        rendererProps[i]
      );
    }
    currentMaxRendererPropsIndex += uint16(rendererProps.length);
    require(
      currentMaxRendererPropsIndex <= MAX_UINT_16,
      'RendererPropsStorage: Exceeds storage limit'
    );
  }

  function indexToRendererProps(uint16 index)
    public
    view
    returns (bytes memory)
  {
    return SSTORE2Map.read(bytes32(uint256(index)));
  }
}