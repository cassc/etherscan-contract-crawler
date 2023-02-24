// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../../StakeDAOTokenStaker.sol";

/// @title StakeDAOTokenStakerMainnet
/// @author Angle Labs, Inc.
/// @dev Constants for borrow staker adapted to Curve LP tokens deposited on Stake DAO Mainnet
abstract contract StakeDAOTokenStakerMainnet is StakeDAOTokenStaker {
    /// @inheritdoc BorrowStaker
    function _getRewards() internal pure override returns (IERC20[] memory rewards) {
        rewards = new IERC20[](2);
        rewards[0] = _crv();
        rewards[1] = _sdt();
        return rewards;
    }

    /// @notice Address of the CRV token
    function _crv() internal pure returns (IERC20) {
        return IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    }

    /// @notice Address of the SDT token
    function _sdt() internal pure returns (IERC20) {
        return IERC20(0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F);
    }
}