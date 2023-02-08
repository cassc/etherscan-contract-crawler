pragma solidity 0.8.17;

import "./SafeERC20.sol";

library AssetLib {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT = type(uint256).max;

    address internal constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getBalance(address token) internal view returns (uint256) {
        return token == NATIVE_ADDRESS ? address(this).balance : IERC20(token).balanceOf(address(this));
    }

    function userBalance(address user, address token) internal view returns (uint256) {
        return token == NATIVE_ADDRESS ? user.balance : IERC20(token).balanceOf(user);
    }
}