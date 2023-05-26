// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "../ERC20/IERC20.sol";
import "./Context.sol";
import "../access/roles/RecoverRole.sol";

contract TokenRecover is Context, RecoverRole {

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyRecoverer {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= tokenAmount, "TokenRecover.recoverERC20: INVALID_AMOUNT");
        IERC20(tokenAddress).transfer(_msgSender(), tokenAmount);
    }
}