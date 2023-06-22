// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import '../../../interfaces/HegicPool/IHegicPoolMetadata.sol';

contract HegicPoolV3Metadata is IHegicPoolMetadata {
  function isHegicPool() external override pure returns (bool) {
    return true;
  }
  function getName() external override pure returns (string memory) {
    return 'HegicPoolV3';
  }
}