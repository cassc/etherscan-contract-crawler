// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @dev A contract for managing claims within a window and
 *  ensuring that each claim can only be made once.
 */
abstract contract Claimable {
  using SafeMath for uint256;

  // Mapping from claim ID to a boolean indicating whether the claim has been made or not.
  mapping(bytes32 => bool) public hasClaimed;
  // Mapping from a window ID to the total amount claimed within that window.
  mapping(bytes32 => uint256) public windowClaimed;

  /**
   * @dev Internal function to update the window claimed amount when the amount does not exceed the window limit.
   * @param amount The amount being claimed.
   * @param window The ID of the window being claimed within.
   * @param windowLimit The maximum amount that can be claimed within the window.
   * @return windowLiquidity The remaining amount that can be claimed within the window.
   */
  function _updateWindow(
    uint256 amount,
    bytes32 window,
    uint256 windowLimit
  ) internal returns (uint256 windowLiquidity) {
    require(amount > 0, "Claimable:invalid-amount");
    windowLiquidity = windowLimit - windowClaimed[window];
    require(amount <= windowLiquidity, "Claimable:insufficient-fund");
    windowClaimed[window] = windowClaimed[window].add(amount);
  }

  /**
   * @dev Internal function to update the window claimed amount and the claim ID has not been used before.
   * @param amount The amount being claimed.
   * @param window The ID of the window being claimed within.
   * @param windowLimit The maximum amount that can be claimed within the window.
   * @param claimId The ID of the claim being made.
   * @return windowLiquidity The remaining amount that can be claimed within the window.
   */
  function _updateClaim(
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    bytes32 claimId
  ) internal returns (uint256 windowLiquidity) {
    windowLiquidity = _updateWindow(amount, window, windowLimit);
    require(!hasClaimed[claimId], "Claimable:already-claimed");
    hasClaimed[claimId] = true;
  }

  /**
   * @dev Internal function to update the window claimed amount and multiple claim IDs have not been used before.
   * @param amount The amount being claimed.
   * @param window The ID of the window being claimed within.
   * @param windowLimit The maximum amount that can be claimed within the window.
   * @param claimIds An array of claim IDs being made.
   * @return windowLiquidity The remaining amount that can be claimed within the window.
   */
  function _updateBatchClaim(
    uint256 amount,
    bytes32 window,
    uint256 windowLimit,
    bytes32[] calldata claimIds
  ) internal returns (uint256 windowLiquidity) {
    windowLiquidity = _updateWindow(amount, window, windowLimit);
    for (uint256 i = 0; i < claimIds.length; i++) {
      require(!hasClaimed[claimIds[i]], "Claimable:already-claimed");
      hasClaimed[claimIds[i]] = true;
    }
  }

  /**
   * @dev Get the claimed status for multiple claims
   * @param ids IDs of the claims to check
   * @return batchClaimed Array of claimed status for each ID provided
   */
  function getBatchClaimed(bytes32[] calldata ids)
    external
    view
    returns (bool[] memory)
  {
    bool[] memory batchClaimed = new bool[](ids.length);
    for (uint256 i = 0; i < ids.length; ++i) {
      batchClaimed[i] = hasClaimed[ids[i]];
    }
    return batchClaimed;
  }

  /**
   * @dev Get the amount claimed for multiple windows
   * @param ids IDs of the windows to check
   * @return batchWindowsClaimed Array of claimed amounts for each window ID provided
   */
  function getBatchWindowClaimed(bytes32[] calldata ids)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory batchWindowsClaimed = new uint256[](ids.length);

    for (uint256 i = 0; i < ids.length; ++i) {
      batchWindowsClaimed[i] = windowClaimed[ids[i]];
    }

    return batchWindowsClaimed;
  }
}