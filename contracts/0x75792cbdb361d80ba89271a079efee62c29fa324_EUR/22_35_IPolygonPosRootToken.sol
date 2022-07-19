/* SPDX-License-Identifier: apache-2.0 */

pragma solidity ^0.8.0;

/**
 * @title IPolygonPosRootToken
 * @dev This interface define the mandatory method enabling polygon bridging mechanism.
 * @notice This interface should be inherited to deploy on ethereum.
 */
interface IPolygonPosRootToken {
  function mint(address user, uint256 amount) external returns(bool);
}