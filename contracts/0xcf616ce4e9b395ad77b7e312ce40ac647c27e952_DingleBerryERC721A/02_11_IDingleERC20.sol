// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDingleERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev returns the amount of ERC20 tokens the caller will receive for NFTs minted
     * @param _freeMinted is boolean value indicating whether the NFT mint includes a free mint
     * @param _doubleReward is boolean value indicating whether the user want 2x ERC20 tokens
     */

    function calculateRewards(
        uint256 _nftAmount,
        bool _freeMinted,
        bool _doubleReward
    ) external view returns (uint256);
}