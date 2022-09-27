// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '../../interfaces/ITransformer.sol';
import '../utils/CollectableDust.sol';
import '../utils/Multicall.sol';

/// @title A base implementation of `ITransformer` that implements `CollectableDust` and `Multicall`
abstract contract BaseTransformer is CollectableDust, Multicall, ERC165, ITransformer {
  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return
      _interfaceId == type(ITransformer).interfaceId ||
      _interfaceId == type(IGovernable).interfaceId ||
      _interfaceId == type(ICollectableDust).interfaceId ||
      _interfaceId == type(IMulticall).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  modifier checkDeadline(uint256 _deadline) {
    if (block.timestamp > _deadline) revert TransactionExpired();
    _;
  }
}