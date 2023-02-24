// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../../interfaces/external/convex/IBooster.sol";
import "../../interfaces/external/convex/IClaimZap.sol";
import "../../interfaces/external/convex/ICvxRewardPool.sol";
import "../../interfaces/external/convex/IConvexToken.sol";

import "../BorrowStaker.sol";

/// @title ConvexTokenStaker
/// @author Angle Labs, Inc.
/// @dev Borrow staker adapted to Curve LP tokens deposited on Convex
abstract contract ConvexTokenStaker is BorrowStaker {
    /// @notice Initializes the `BorrowStaker` for Convex
    function initialize(ICoreBorrow _coreBorrow) external {
        string memory erc20Name = string(
            abi.encodePacked("Angle ", IERC20Metadata(address(asset())).name(), " Convex Staker")
        );
        string memory erc20Symbol = string(abi.encodePacked("agstk-cvx-", IERC20Metadata(address(asset())).symbol()));
        _initialize(_coreBorrow, erc20Name, erc20Symbol);
    }

    /// @inheritdoc BorrowStaker
    function _getRewards() internal pure virtual override returns (IERC20[] memory rewards) {
        rewards = new IERC20[](2);
        rewards[0] = _crv();
        rewards[1] = _cvx();
        return rewards;
    }

    // ============================= VIRTUAL FUNCTIONS =============================

    /// @notice ID of the pool associated to the LP token on Convex
    function poolPid() public pure virtual returns (uint256);

    /// @notice Address of the Convex contract that routes deposits
    function _convexBooster() internal pure virtual returns (IConvexBooster);

    /// @notice Address of the CRV token
    function _crv() internal pure virtual returns (IERC20);

    /// @notice Address of the CVX token
    function _cvx() internal pure virtual returns (IConvexToken);
}