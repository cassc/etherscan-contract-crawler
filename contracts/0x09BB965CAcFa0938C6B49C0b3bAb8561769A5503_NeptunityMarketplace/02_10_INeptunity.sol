// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface INeptunity {
    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(
        string memory _tokenURI,
        address _to,
        uint24 _artistFee
    ) external;

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

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
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev returns the artist wallet address for the token Id
     */
    function artists(uint256 _tokenId) external view returns (address);

    /**
     * @dev only either auction or marketplace contract can call it to set tokenId as secondary sale.
     */
    function setSecondarySale(uint256 _tokenId) external;

    /**
     * @dev returns basic information about the token, and marketplace*/
    function getStateInfo(uint256 _tokenId)
        external
        view
        returns (
            address,
            bool,
            uint24,
            uint24,
            uint24,
            address
        );
}