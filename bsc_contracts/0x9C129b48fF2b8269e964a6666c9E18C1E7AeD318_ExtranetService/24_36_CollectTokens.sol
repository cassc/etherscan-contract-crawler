// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library CollectTokens {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function _collectTokens(address[] memory tokens, address to)
        internal
    {
        for (uint i=0; i<tokens.length; i++) {
            _collect(tokens[i], to);
        }
    }

    function _collect(address tokenAddress, address to)
        internal
    {
        if (tokenAddress == address(0)) {
            if (address(this).balance == 0) {
                return;
            }

            payable(to).transfer(address(this).balance);

            return;
        }

        uint256 _balance = IERC20Upgradeable(tokenAddress).balanceOf(address(this));
        if (_balance == 0) {
            return;
        }

        IERC20Upgradeable(tokenAddress).safeTransfer(to, _balance);
    }
}