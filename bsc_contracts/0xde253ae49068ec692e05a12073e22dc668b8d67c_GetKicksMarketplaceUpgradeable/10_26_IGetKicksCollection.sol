// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IGetKicksCollection is IERC721 {
    error TokenLocked(uint256 tokenId);

    /**
     * @dev Emitted when `tokenId` nft is minted to `to`.
     */
    event TokenMint(uint256 tokenId, address to);

    /**
     * @dev Emitted when `setBaseURI` is change to `newBaseTokenURI`.
     */
    event BaseUriChanged(string oldBaseTokenURI, string newBaseTokenURI);

    /**
     * @dev Emitted when `setContoller` is change to `newAddress`.
     */
    event ControllerChanged(address newAddress);

    /**
     * @dev Emitted when `locked` of `tokenId` is change to true.
     */
    event TokenIdLocked(uint256 tokenId, bool locked);

    /**
     * @dev Emitted when `locked` of `tokenId` is change to false.
     */
    event TokenIdReleased(uint256 tokenId, bool locked);

    /**
     * @dev Returns all tokenIds.
     */
    // function tokenIds() external view returns (uint256[] memory);

    /**
     * @dev Returns all current and previous owners of the `tokenId` token.
     */
    function ownersHistory(uint256 tokenId) external view returns (address[] memory);

    /**
     * @dev Returns true of false of the locked value for the room of the `tokenId` token
     */
    function locked(uint256 tokenId) external view returns (bool);

    /**
     * @dev Return the address of the controller.
     */
    function controller() external view returns (address);

    /**
     * @dev Return the amount of replicas has been minted.
     */
    function replicas() external view returns (uint256);

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function baseURI() external view returns (string memory);

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev Set Room informations of the `tokenId` token.
     *
     * @param tokenId the token identification of the nft
     * @param locked the ability to locked transfers of the nft
     *
     * Requirements:
     *
     * - `msg.sender` only the controller address can call this function.
     * - `tokenId` can not be the zero value.
     *
     * Emits a {RoomInfoAdded} event.
     * Emits a {DimensionsAdded} event.
     */
    function setCollectionInfos(uint256 tokenId, bool locked) external;

    /**
     * @dev Set the controller address.
     *
     * Requirements:
     *
     * - `msg.sender` only the old controller address can call this function.
     * - `controller_` cannot be the zero address.
     * - `controller_` cannot be the same address as the current value.
     */
    function setController(address controller_) external;

    /**
     * @dev lock the nft trading of the `tokenId` token.
     *
     * Requirements:
     *
     * - `msg.sender` only the controller address can call this function.
     * - `tokenId`must exist.
     * -
     */
    function lockTokenId(uint256 tokenId) external;

    /**
     * @dev release lock the nft trading of the `tokenId` token.
     *
     * Requirements:
     *
     * - `msg.sender` only the controller address can call this function.
     * - `tokenId` must exist.
     * - `tokenId` cannot be locked before.
     * -
     */
    function releaseLockedTokenId(uint256 tokenId) external;

    /**
     * @dev setBaseURI.
     *
     * @param newBaseTokenURI the new base uri for the collections
     *
     * Requirements:
     *
     * - `msg.sender` only the admin address can call this function.
     *
     */
    function setBaseURI(string calldata newBaseTokenURI) external;

    /**
     * @dev setTokenUri for the `tokenId`.
     *
     * @param tokenId the nft identifications
     * @param tokenURI_ ipfs uris of the nft
     *
     * Requirements:
     *
     * - `msg.sender` only the old controller address can call this function.
     * - `tokenId` must not exist.
     *
     */
    function setTokenURI(uint256 tokenId, string memory tokenURI_) external;

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * @param royaltyRecipient the recipient address of the royalty
     * @param royaltyValue the royalty value for the team,
     *   if 0 then the smart contrac will use globalRoyaltyValue
     *
     * Requirements:
     *
     * - `msg.sender` only the old controller address can call this function.
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits {TokenMint and Transfer} event.
     */
    function mint(
        address to,
        string memory uri,
        address royaltyRecipient,
        uint256 royaltyValue
    ) external;

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * @param royaltyRecipient the recipient address of the royalty
     * @param royaltyValue the royalty value for the team,
     *   if 0 then the smart contrac will use globalRoyaltyValue
     *
     * Requirements:
     *
     * - `msg.sender` only the old controller address can call this function.
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits {TokenMint and Transfer} event.
     */
    function safeMint(
        string memory uri,
        address to,
        address royaltyRecipient,
        uint256 royaltyValue,
        bytes memory _data
    ) external;
}