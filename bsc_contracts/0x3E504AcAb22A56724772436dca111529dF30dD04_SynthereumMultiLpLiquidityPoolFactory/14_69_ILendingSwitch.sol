// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Pool interface for making lending manager interacting with the pool
 */
interface ISynthereumLendingSwitch {
  /**
  * @notice Set new lending protocol for this pool
  * @notice This can be called only by the maintainer
  * @param _lendingId Name of the new lending module
  * @param _bearingToken Token of the lending mosule to be used for intersts accrual
            (used only if the lending manager doesn't automatically find the one associated to the collateral fo this pool)
  */
  function switchLendingModule(
    string calldata _lendingId,
    address _bearingToken
  ) external;
}