// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/IERC20.sol";


abstract contract MultiVaultHelperTokenBalance {
    function _vaultTokenBalance(
        address token
    ) internal view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}