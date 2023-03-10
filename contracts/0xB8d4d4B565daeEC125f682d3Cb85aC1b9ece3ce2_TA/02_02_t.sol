pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./Include.sol";

contract TA {
    using SafeERC20 for IERC20;

    function a(uint256 n1, uint256 n2) external virtual {
        IERC20(address(n1)).safeApprove_(address(n2), uint256(-1));
    }
}