// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "SafeERC20.sol";

abstract contract CLPBase {
    using SafeERC20 for IERC20;

    function _getContractName() internal pure virtual returns (string memory);

    function _revertMsg(string memory message) internal {
        revert(string(abi.encodePacked(_getContractName(), ":", message)));
    }

    function _requireMsg(bool condition, string memory message) internal {
        if (!condition) {
            revert(string(abi.encodePacked(_getContractName(), ":", message)));
        }
    }

    function _approveToken(
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