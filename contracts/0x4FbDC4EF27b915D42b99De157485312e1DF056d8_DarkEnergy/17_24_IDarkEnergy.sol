// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./INonFungibleSeaDropToken.sol";
import "./ERC721SeaDropStructsErrorsAndEvents.sol";

/**
 * @dev Interface of ERC721A.
 */
interface IDarkEnergy is INonFungibleSeaDropToken, ERC721SeaDropStructsErrorsAndEvents {
    /**
     * The caller must own the token or be an approved operator.
     */
    error CallerNotOwnerNorApproved();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * One cannot send a token holding negative energy to a holder of a token
     * holding positive energy
     */
    error NegativeEnergyToPositiveHolder();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error QuantityExceedsLimit();

    /**
     * The token does not exist.
     */
    error QueryForNonExistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error QueryForZeroAddress();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Caller needs a gamePass to proceed
     */
    error NoGamePass();

    /**
     * The game rules aren't consistent
     */
    error InvalidGameRules();

    /**
     * To prevent Owner from overriding fees, Administrator must
     * first initialize with fee.
     */
    error AdministratorMustInitializeWithFee();

    /**
     * To be thrown in case the max supply was reached and the mint doesn't go
     * through SeaDrop
     */
    error MaxSupplyExceeded();

    /**
     * To be thrown in case the max supply was reached and the mint doesn't go
     * through SeaDrop
     */
    error OperatorNotAllowed();

    /**
     * To be thrown in case the max supply was reached and the mint doesn't go
     * through SeaDrop
     */
    error AddressNotHolder();

    /**
     * To be thrown in case the max supply was reached and the mint doesn't go
     * through SeaDrop
     */
    error GameNotActive();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed from,
        address indexed to
    );

    // =============================================================
    //                      Marketplace Related
    // =============================================================
    /**
     * @dev Signal to marketplaces that the token has been updated
     */
    event MetadataUpdate(uint256 _tokenId);

    /**
     * @dev Allowed a SeaDrop
     */
    event AllowedSeaDrop(address indexed seaDrop);

    /**
     * @dev Denied a SeaDrop
     */
    event DeniedSeaDrop(address indexed seaDrop);

    // =============================================================
    //                      DarkEnergy-specific
    // =============================================================

    /**
     * @dev GamePass earned through minting
     */
    event GamePassesGained(uint256 indexed tokenId, uint16 indexed amount);

    /**
     * @dev Energy updated
     */
    event EnergyUpdate(address indexed player, int40 indexed energyDiff);

    /**
     * @dev Energy doubled
     */
    event EnergyDoubled(address indexed player, int40 indexed energy);

    /**
     * @dev Energy halved
     */
    event EnergyHalved(address indexed player, int40 indexed energy);

    /**
     * @dev No risk game played
     */
    event PlayNoRisk(address indexed player);

    /**
     * @dev High stakes game played
     */
    event PlayHighStakes(address indexed player);

    /**
     * @dev Ordinal won
     */
    event OrdinalWon(address indexed player);

    /**
     * @dev Game rules updated
     */
    event GameRulesUpdated(bytes32 indexed oldRules, bytes32 indexed newRules);

    /**
     * @dev Game rules updated
     */
    event OrdinalsVouchersDeployed(address indexed contractAddress);

    /**
     * @dev Dark Energy minted
     */
    event GlitchMint(address indexed to, uint256 indexed energy, uint256 indexed gamePasses);

    /**
     * @dev Dark Energy minted
     */
    event AdminMint(address indexed to, int40 indexed energyDiff, uint16 indexed gamePassesDiff);
}