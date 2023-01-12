pragma solidity 0.8.17;

import "./SafeERC20.sol";

library AssetLib {
    using SafeERC20 for IERC20;
    uint256 private constant MAX_UINT = type(uint256).max;

    IERC20 internal constant NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function getBalance(IERC20 token) internal view returns (uint256) {
        return token == NATIVE_ADDRESS ? address(this).balance : token.balanceOf(address(this));
    }
}