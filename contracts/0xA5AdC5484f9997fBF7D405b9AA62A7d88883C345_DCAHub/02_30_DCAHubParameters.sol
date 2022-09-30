// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/IDCAHub.sol';
import '../libraries/TokenSorting.sol';

abstract contract DCAHubParameters is IDCAHubParameters {
  /// @notice Swap information about a specific pair
  struct SwapData {
    // How many swaps have been executed
    uint32 performedSwaps;
    // How much of token A will be swapped on the next swap
    uint224 nextAmountToSwapAToB;
    // Timestamp of the last swap
    uint32 lastSwappedAt;
    // How much of token B will be swapped on the next swap
    uint224 nextAmountToSwapBToA;
  }

  /// @notice The difference of tokens to swap between a swap, and the previous one
  struct SwapDelta {
    // How much less of token A will the following swap require
    uint128 swapDeltaAToB;
    // How much less of token B will the following swap require
    uint128 swapDeltaBToA;
  }

  /// @notice The sum of the ratios the oracle reported in all executed swaps
  struct AccumRatio {
    // The sum of all ratios from A to B
    uint256 accumRatioAToB;
    // The sum of all ratios from B to A
    uint256 accumRatioBToA;
  }

  using SafeERC20 for IERC20Metadata;

  /// @inheritdoc IDCAHubParameters
  mapping(address => mapping(address => bytes1)) public activeSwapIntervals; // token A => token B => active swap intervals
  /// @inheritdoc IDCAHubParameters
  mapping(address => uint256) public platformBalance; // token => balance
  /// @inheritdoc IDCAHubParameters
  mapping(address => mapping(address => mapping(bytes1 => mapping(uint32 => SwapDelta)))) public swapAmountDelta; // token A => token B => swap interval => swap number => delta
  /// @inheritdoc IDCAHubParameters
  mapping(address => mapping(address => mapping(bytes1 => mapping(uint32 => AccumRatio)))) public accumRatio; // token A => token B => swap interval => swap number => accum
  /// @inheritdoc IDCAHubParameters
  mapping(address => mapping(address => mapping(bytes1 => SwapData))) public swapData; // token A => token B => swap interval => swap data

  function _assertNonZeroAddress(address _address) internal pure {
    if (_address == address(0)) revert IDCAHub.ZeroAddress();
  }

  function _transfer(
    address _token,
    address _to,
    uint256 _amount
  ) internal {
    if (_amount > 0) {
      IERC20Metadata(_token).safeTransfer(_to, _amount);
    }
  }

  function _balanceOf(address _token) internal view returns (uint256) {
    return IERC20Metadata(_token).balanceOf(address(this));
  }
}