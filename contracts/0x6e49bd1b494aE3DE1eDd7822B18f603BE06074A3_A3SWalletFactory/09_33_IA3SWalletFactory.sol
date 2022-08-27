//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IA3SWalletFactory is IERC721Upgradeable {
    /**
     * @dev Emitted when a token for a newly created wallet is minted using create2 of the given `salt`, to `to`
     */
    event MintWallet(
        address indexed to,
        bytes32 indexed salt,
        address wallet,
        uint256 tokenId
    );

    /**
     * @dev Mints `tokenId`, creates a A3SWallet, and assign the token to `to`.
     *      Need to charge fees with ether or fait token decided by `useFiatToken`
     *
     * WARNING: We do not
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * - fiat token must not be address zero when `useFiatToken` is true
     *
     * Emits a {MintWallet} event.
     */
    function mintWallet(
        address to,
        bytes32 salt,
        bool useFiatToken,
        bytes32[] calldata proof
    ) external payable returns (address);

    /**
     * @dev Transfer a batch of `tokens` from `from` to `bo`
     *
     * Requirements:
     *
     * - msg.sender must be the owner or approved for every token in `tokens`
     * - every token in `tokens` must belongs to `from`.
     * - `to` cannot be the zero address.
     *
     * Emits a {MintWallet} event.
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokens
    ) external;

    /**
     * @dev Returns the wallet address of the `tokenId` Token
     *
     * Requirements:
     *
     * - `wallet` must exist.
     */
    function walletOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the token ID  of the `wallet` wallet address.
     *
     * Requirements:
     *
     * - `tokenId` must larger than 0.
     */
    function walletIdOf(address wallet) external view returns (uint256);

    /**
     * @dev Returns the owner of the `wallet` wallet address.
     *
     * Requirements:
     *
     * - `owner` must exist.
     */
    function walletOwnerOf(address wallet) external view returns (address);

    /**
     * @dev Returns the wallet address computed with create2 method with given `salt` bytes32.
     */
    // function predictWalletAddress(bytes32 salt) external view returns (address);
}