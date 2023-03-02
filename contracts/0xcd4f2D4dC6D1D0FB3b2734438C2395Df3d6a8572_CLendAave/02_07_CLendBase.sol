// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "SafeERC20.sol";

abstract contract CLendBase {
    using SafeERC20 for IERC20;

    function _getContractName() internal pure virtual returns (string memory);

    function _tokenApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.safeApprove(spender, 0);
        }
        token.safeApprove(spender, amount);
    }
}