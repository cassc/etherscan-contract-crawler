// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {ITokenEnforceable} from "src/contracts/common/ITokenEnforceable.sol";
import {IERC1644} from "src/contracts/common/IERC1644.sol";

/**
 * Interface for functions defined in ERC721UpgradeableFork
 */
interface IERC721UpgradeableFork is IERC721MetadataUpgradeable {
    /**
     * @return ID of the first token that will be minted.
     */
    function STARTING_TOKEN_ID() external view returns (uint256);

    /**
     * Max consecutive tokenIds of bulk-minted tokens whose owner can be stored
     * as address(0). This number is capped to reduce the cost of owner lookup.
     */
    function OWNER_ID_STAGGER() external view returns (uint256);

    /**
     * @return ID of the next token that will be minted. Existing tokens are
     * limited to IDs between `STARTING_TOKEN_ID` and `_nextTokenId` (including
     * `STARTING_TOKEN_ID` and excluding `_nextTokenId`, though not all of these
     * IDs may be in use if tokens have been burned).
     */
    function nextTokenId() external view returns (uint256);

    /**
     * @return receiver Address that should receive royalties from sales.
     * @return royaltyAmount How much royalty that should be sent to `receiver`,
     * denominated in the same unit of exchange as `salePrice`.
     * @param tokenId The token being sold.
     * @param salePrice The sale price of the token, denominated in any unit of
     * exchange. The royalty amount will be denominated and should be paid in
     * that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

/**
 * Interface for only functions defined in ERC721Collective (excludes inherited
 * and overridden functions)
 */
interface IERC721CollectiveUnchained is IERC1644 {
    event RendererUpdated(address indexed implementation);
    event RendererLocked();

    /**
     * Initializes `ERC721Collective`.
     *
     * Emits an `Initialized` event.
     *
     * @param name_ Name of token
     * @param symbol_ Symbol of token
     * @param mintGuard_ Address of mint guard
     * @param burnGuard_ Address of burn guard
     * @param transferGuard_ Address of transfer guard
     * @param renderer_ Address of renderer
     */
    function __ERC721Collective_init(
        string memory name_,
        string memory symbol_,
        address mintGuard_,
        address burnGuard_,
        address transferGuard_,
        address renderer_
    ) external;

    /**
     * @return Number of currently-existing tokens (tokens that have been
     * minted and that have not been burned).
     */
    function totalSupply() external view returns (uint256);

    // name(), symbol(), and tokenURI() overriding ERC721UpgradeableFork
    // declared in IERC721Fork

    /**
     * @return The address of the token Renderer. The contract at this address
     * is assumed to implement the IRenderer interface.
     */
    function renderer() external view returns (address);

    /**
     * @return True iff the Renderer cannot be changed.
     */
    function rendererLocked() external view returns (bool);

    /**
     * Update the address of the token Renderer. The contract at the passed-in
     * address is assumed to implement the IRenderer interface.
     *
     * Emits a `RendererUpdated` event.
     *
     * Requirements:
     * - The caller must be the token contract owner or the batcher.
     * - Renderer must not be locked.
     * @param implementation Address of new Renderer
     */
    function updateRenderer(address implementation) external;

    /**
     * Irreversibly prevents the token contract owner from changing the token
     * Renderer.
     *
     * Emits a `RendererLocked` event.
     *
     * Requirements:
     * - The caller must be the token contract owner or the batcher.
     */
    function lockRenderer() external;

    // supportsInterface(bytes4 interfaceId) overriding ERC1644 declared in
    // IERC1644

    /**
     * @return True after successfully executing mint and transfer of
     * `nextTokenId` to `account`.
     *
     * Emits a `Transfer` event with `address(0)` as `from`.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * @param account The account to receive the minted token.
     */
    function mintTo(address account) external returns (bool);

    /**
     * @return True after successfully bulk minting and transferring the
     * `nextTokenId` through `nextTokenId + amount` tokens to `account`.
     *
     * Emits a `Transfer` event (with `address(0)` as `from`) for each token
     * that is minted.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * @param account The account to receive the minted tokens.
     * @param amount The number of tokens to be minted.
     */
    function bulkMintToOneAddress(address account, uint256 amount)
        external
        returns (bool);

    /**
     * @return True after successfully bulk minting and transferring one of the
     * `nextTokenId` through `nextTokenId + accounts.length` tokens to each of
     * the addresses in `accounts`.
     *
     * Emits a `Transfer` event (with `address(0)` as `from`) for each token
     * that is minted.
     *
     * Requirements:
     * - `accounts` cannot have length 0.
     * - None of the addresses in `accounts` can be the zero address.
     * @param accounts The accounts to receive the minted tokens.
     */
    function bulkMintToNAddresses(address[] calldata accounts)
        external
        returns (bool);

    /**
     * @return True after successfully burning `tokenId`.
     *
     * Emits a `Transfer` event with `address(0)` as `to`.
     *
     * Requirements:
     * - The caller must either own or be approved to spend the `tokenId` token.
     * - `tokenId` must exist.
     * @param tokenId The tokenId to be burned.
     */
    function redeem(uint256 tokenId) external returns (bool);

    // controllerRedeem() and controllerTransfer() declared in IERC1644

    /**
     * Sets the default royalty fee percentage for the ERC721.
     *
     * A custom royalty fee will override the default if set for specific tokenIds.
     *
     * Requirements:
     * - The caller must be the token contract owner.
     * - `isControllable` must be true.
     * @param receiver The account to receive the royalty.
     * @param feeNumerator The fee amount in basis points.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    /**
     * Sets a custom royalty fee percentage for the specified `tokenId`.
     *
     * Requirements:
     * - The caller must be the token contract owner.
     * - `isControllable` must be true.
     * - `tokenId` must exist.
     * @param tokenId The tokenId to set a custom royalty for.
     * @param receiver The account to receive the royalty.
     * @param feeNumerator The fee amount in basis points.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external;
}

/**
 * Interface for all functions in ERC721Collective, including inherited and
 * overridden functions
 */
interface IERC721Collective is
    ITokenEnforceable,
    IERC721UpgradeableFork,
    IERC721CollectiveUnchained
{

}