// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library CollectTokens {
    using SafeERC20 for IERC20;

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

        uint256 _balance = IERC20(tokenAddress).balanceOf(address(this));
        if (_balance == 0) {
            return;
        }

        IERC20(tokenAddress).safeTransfer(to, _balance);
    }
}