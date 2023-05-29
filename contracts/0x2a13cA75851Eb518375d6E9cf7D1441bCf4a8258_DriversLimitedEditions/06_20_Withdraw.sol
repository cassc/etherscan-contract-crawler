// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/token/ERC1155/IERC1155.sol";

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Withdraw ETH and tokens module
 * @notice Allows the withdrawal of ETH, ERC20, ERC721, an ERC1155 tokens
 */
abstract contract Withdraw {
    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    error CannotWithdrawToZeroAddress();
    error WithdrawFailed();
    error BalanceTooLow();
    error ZeroBalance();

    /* ------------------------------------------------------------------------
                                  W I T H D R A W
    ------------------------------------------------------------------------ */

    function _withdrawETH(address to) internal {
        // Prevent withdrawing to the zero address
        if (to == address(0)) revert CannotWithdrawToZeroAddress();

        // Check there is eth to withdraw
        uint256 balance = address(this).balance;
        if (balance == 0) revert ZeroBalance();

        // Transfer funds
        (bool success, ) = payable(to).call{value: balance}("");
        if (!success) revert WithdrawFailed();
    }

    function _withdrawToken(address tokenAddress, address to) internal {
        // Prevent withdrawing to the zero address
        if (to == address(0)) revert CannotWithdrawToZeroAddress();

        // Check there are tokens to withdraw
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance == 0) revert ZeroBalance();

        // Transfer tokens
        bool success = IERC20(tokenAddress).transfer(to, balance);
        if (!success) revert WithdrawFailed();
    }

    function _withdrawERC721Token(
        address tokenAddress,
        uint256 id,
        address to
    ) internal {
        // Prevent withdrawing to the zero address
        if (to == address(0)) revert CannotWithdrawToZeroAddress();

        // Check the NFT is in this contract
        address owner = IERC721(tokenAddress).ownerOf(id);
        if (owner != address(this)) revert ZeroBalance();

        // Transfer NFT
        IERC721(tokenAddress).transferFrom(address(this), to, id);
    }

    function _withdrawERC1155Token(
        address tokenAddress,
        uint256 id,
        uint256 amount,
        address to
    ) internal {
        // Prevent withdrawing to the zero address
        if (to == address(0)) revert CannotWithdrawToZeroAddress();

        // Check the tokens are owned by this contract, and there's at least `amount`
        uint256 balance = IERC1155(tokenAddress).balanceOf(address(this), id);
        if (balance == 0) revert ZeroBalance();
        if (amount > balance) revert BalanceTooLow();

        // Transfer tokens
        IERC1155(tokenAddress).safeTransferFrom(address(this), to, id, amount, "");
    }
}