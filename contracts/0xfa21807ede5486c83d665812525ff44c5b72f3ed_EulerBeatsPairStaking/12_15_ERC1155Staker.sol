// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/**
 * @dev Base contract that support ERC1155 token staking.  Any token is allowed to be be staked/unstaked in this base implementation.
 * Concrete implementations should either do validation checks prior to calling deposit/withdraw, or use the provided hooks
 * to do the checks.
 */
abstract contract ERC1155Staker is ERC1155Holder {
    // hooks

    /**
     * @dev Called prior to transfering given token id from account to this contract.  This is good spot to do
     * any checks and revert if the given account should be able to deposit the specified token.
     * Ths hook is ALWAYS called prior to a deposit -- both the single and batch variants.
     */
    function _beforeDeposit(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Called prior to transfering given token from this contract to the account.  This is good spot to do
     * any checks and revert if the given account should be able to withdraw the specified token.
     * Ths hook is ALWAYS called prior to a withdraw -- both the single and batch variants.
     */
    function _beforeWithdraw(
        address account,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Deposit one or more instance of a single token.
     */
    function _depositSingle(
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(amount > 0, "Invalid amount");
        _beforeDeposit(msg.sender, contractAddress, tokenId, amount);
        IERC1155(contractAddress).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
    }

    /**
     * @dev Deposit one or more instances of the spececified tokens.
     * As a convience for the caller, this returns the total number instances of tokens depositied (the sum of amounts).
     */
    function _deposit(
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal virtual returns (uint256 totalTokensDeposited) {
        totalTokensDeposited = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(amounts[i] > 0, "Invalid amount");
            _beforeDeposit(msg.sender, contractAddress, tokenIds[i], amounts[i]);
            totalTokensDeposited += amounts[i];
        }

        IERC1155(contractAddress).safeBatchTransferFrom(msg.sender, address(this), tokenIds, amounts, "");
    }

    /**
     * @dev Withdraw one or more instance of a single token.
     * As a convience for the caller, this returns the total number instances of tokens depositied (the sum of amounts).
     */
    function _withdrawSingle(
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(amount > 0, "Invalid amount");
        _beforeWithdraw(msg.sender, contractAddress, tokenId, amount);
        IERC1155(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
    }

    /**
     * @dev Withdraw one or more instances of the spececified tokens.
     */
    function _withdraw(
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal virtual returns (uint256 totalTokensWithdrawn) {
        totalTokensWithdrawn = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(amounts[i] > 0, "Invalid amount");
            _beforeWithdraw(msg.sender, contractAddress, tokenIds[i], amounts[i]);
            totalTokensWithdrawn += amounts[i];
        }

        IERC1155(contractAddress).safeBatchTransferFrom(address(this), msg.sender, tokenIds, amounts, "");
    }
}