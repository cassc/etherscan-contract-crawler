// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Recoverable {
    /**
     * recovers erc20 tokens when they have been sent to the contract
     * @param tokenId the hash of the token to send out of the contract
     * @param recipient the recipient of the transfer
     * @param amount the magnitude of the transfer
     * @notice native tokens and tokens that match wNative cannot be recovered
     */
    function _recoverERC20(address tokenId, address recipient, uint256 amount) internal virtual {
        require(tokenId != address(0), "Recoverable: tokenId not valid");
        IERC20(tokenId).transfer(recipient, amount);
    }
    modifier unrecoverable(address tokenA, address tokenB) {
        require(tokenA != tokenB, "Recoverable: unable to recover");
        _;
    }
}