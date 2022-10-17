// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../LibDiamond.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract MethodsExposureFacet is Ownable, IDiamondCut, IDiamondLoupe, IERC2981, IERC721 {
    // ==================== IDiamondLoupe & IDiamondCut ====================

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external onlyOwner {}

    /// These functions are expected to be called frequently by tools.

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        facets_ = new Facet[](0);
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        facetFunctionSelectors_ = new bytes4[](0);
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](0);
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        return address(0);
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        return false;
    }

    // ==================== ERC721 ====================

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        return 0;
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner) {
        return address(0);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {}

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {}

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
    ) external {}

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external {}

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external {}

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator) {
        return address(0);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return false;
    }

    // ==================== Management ====================

    function setMethodsExposureFacetAddress(string memory _methodsExposureFacetAddress) external onlyOwner {}

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {}

    function setRoyaltiesRecipient(address _royaltiesRecipient) external onlyOwner {}

    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints) external onlyOwner {}

    function setMintPrice(uint256 _mintPrice) external onlyOwner {}

    function setMaxMintsPerWallet(uint32 _maxMintsPerWallet) external onlyOwner {}

    function setMaxMintsTeam(uint32 _maxMintsTeam) external onlyOwner {}

    function setMaxSupply(uint32 _maxSupply) external onlyOwner {}

    function setReveal(bool _isReveal) external onlyOwner {}

    function setPublicMintOpen(bool _publicMintOpen) external onlyOwner {}

    function setAllowlistMintOpen(bool _allowlistMintOpen) external onlyOwner {}

    // ==================== Views ====================

    function implementation() public view returns (address) {
        return address(0);
    }

    function maxSupply() external view returns (uint32) {
        return 0;
    }

    function baseTokenURI() external view returns (string memory) {
        return "";
    }

    function mintPrice() external view returns (uint256) {
        return 0;
    }

    function maxMintsPerWallet() external view returns (uint32) {
        return 0;
    }

    function maxMintsTeam() external view returns (uint32) {
        return 0;
    }

    function isReveal() external view returns (bool) {
        return false;
    }

    function royaltiesRecipient() external view returns (address) {
        return address(0);
    }

    function royaltiesBasisPoints() external view returns (uint256) {
        return 0;
    }

    function publicMintOpen() external view returns (bool) {
        return false;
    }

    function allowlistMintOpen() external view returns (bool) {
        return false;
    }

    function numberMinted(address who) public view returns (uint256) {}

    function totalSupply() public view returns (uint256) {}

    // =========== EIP2981 ===========

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(0), 0);
    }

    // =========== Mint ===========

    function mint(uint256 quantity) external payable {}

    function allowlistMint(bytes32[] calldata proof, uint256 quantity) external payable {}

    function teamMint(uint256 quantity) external payable {}
}