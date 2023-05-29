// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

/**
 * @title IERC1644 Controller Token Operation (part of the ERC1400 Security
 * Token Standards)
 *
 * See https://github.com/ethereum/EIPs/issues/1644. Data and operatorData
 * parameters were removed.
 */
interface IERC1644 {
    event ControllerRedemption(
        address account,
        address indexed from,
        uint256 value
    );

    event ControllerTransfer(
        address controller,
        address indexed from,
        address indexed to,
        uint256 value
    );

    /**
     * Burns `tokenId` without checking whether the caller owns or is approved
     * to spend the token.
     *
     * Emits a `Transfer` event with `address(0)` as `to` AND a
     * `ControllerRedemption` event.
     *
     * Requirements:
     * - The caller must be the token contract owner or the batcher.
     * - `isControllable` must be true.
     * @param account The account whose token will be burned.
     * @param value Amount (ERC20) or token ID (ERC721)
     */
    function controllerRedeem(
        address account,
        uint256 value // amount (ERC20) or tokenId (ERC721))
    ) external;

    /**
     * Transfers `tokenId` token from `from` to `to`, without checking whether
     * the caller owns or is approved to spend the token.
     *
     * Emits a `Transfer` event with `address(0)` as `to` AND a
     * `ControllerRedemption` event.
     *
     * Requirements:
     * - The caller must be the token contract owner or the batcher.
     * - `isControllable` must be true.
     * @param from The account sending the token.
     * @param to The account to receive the token.
     * @param value Amount (ERC20) or token ID (ERC721)
     */
    function controllerTransfer(
        address from,
        address to,
        uint256 value // amount (ERC20) or tokenId (ERC721)
    ) external;
}