//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/governance/utils/IVotesUpgradeable.sol";

import "./components/IVestingScheduleManager.1.sol";

/// @title TLC Interface (v1)
/// @author Alluvial
/// @notice TLC token interface
interface ITLCV1 is IVestingScheduleManagerV1, IVotesUpgradeable, IERC20Upgradeable {
    /// @notice Initializes the TLC Token
    /// @param _account The initial account to grant all the minted tokens
    function initTLCV1(address _account) external;
}