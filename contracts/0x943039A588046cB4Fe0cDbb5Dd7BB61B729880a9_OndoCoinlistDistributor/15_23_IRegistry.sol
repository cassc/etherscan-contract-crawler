// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/interfaces/IWETH.sol";

/**
 * @title Global values used by many contracts
 * @notice This is mostly used for access control
 */
interface IRegistry is IAccessControl {
  function paused() external view returns (bool);

  function pause() external;

  function unpause() external;

  function enableFeatureFlag(bytes32 _featureFlag) external;

  function disableFeatureFlag(bytes32 _featureFlag) external;

  function getFeatureFlag(bytes32 _featureFlag) external view returns (bool);

  function denominator() external view returns (uint256);

  function weth() external view returns (IWETH);

  function authorized(bytes32 _role, address _account)
    external
    view
    returns (bool);
}