// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Owned.sol";

abstract contract TokensRecoverable is Owned {
    using SafeERC20 for IERC20;

    /**
     * @dev Recovers all ERC20 token stuck in the contract when someone sends it by mistake
     * Owner cannot take from user's balance anything,
     * Owner can just recover the tokens stuck in contract address that are irrecoverable otherwise.
     * Requirements:
     *
     * - `token` - Address of ERC20 token to recover
     */
    function recoverTokens(IERC20 token) public onlyOwner {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @dev Recovers BNB stuck in the contract
     *
     * Requirements:
     *
     * - `amount` - BNB amount to receive in owner
     */
    function recoverBNB(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}