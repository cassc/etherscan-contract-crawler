// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts4.7.3/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts4.7.3/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts4.7.3/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts4.7.3/security/Pausable.sol";
import "@openzeppelin/contracts4.7.3/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts4.7.3/access/Ownable.sol";
import "@openzeppelin/contracts4.7.3/utils/Strings.sol";
import "operator-filter-registry1.3.1/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts4.7.3/utils/Counters.sol";

import "./IMINT_CONTRACT.sol";

/**
 * OasisCommunityPass
 * - Support Royalty(https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721Royalty)
 * - AccessControl
 * - Ownable(For only OpenSea)
 * - Forbid secondary sales (Pausable)
 * - Reveal NFTs (setBaseURI)
 *
 * NOTE: Inintialized by https://wizard.openzeppelin.com/#erc721
 */
contract OasisCommunityPass is ERC721, ERC721Enumerable, Pausable, AccessControlEnumerable, ERC721Royalty, Ownable, DefaultOperatorFilterer, IMINT_CONTRACT {

    using Counters for Counters.Counter;

    bytes32 private constant CONTRACT_TYPE = bytes32("OasisCommunityPass");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ROYALTY_ROLE = keccak256("ROYALTY_ROLE");
    bytes32 public constant REVEAL_ROLE = keccak256("REVEAL_ROLE");

    string private baseURI_ = "";

    Counters.Counter private _tokenIdCounter;

    /**
     * @dev Emitted when `baseURI` is set.
     */
    event BaseURISet(string baseURI);

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ////////////////////
    // Internal

    /**
     * @dev Returns the type of the contract
     */
    function contractType() override external pure returns (bytes32)
    {
        return CONTRACT_TYPE;
    }

    ////////////////////
    // Mint

    /**
     * @dev Minting NFT
     *
     * Requirements:
     *
     * - Message sender must have `MINTER_ROLE`
     */
    
    function mint(address to) public onlyRole(MINTER_ROLE)
    {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    ////////////////////
    // Pausable

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyRole(PAUSER_ROLE)
    {
        _pause();
    }

    /**
     * @dev Triggers un-stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function unpause() public onlyRole(PAUSER_ROLE)
    {
        _unpause();
    }

    ////////////////////
    // Royality

    /**
     * @dev Sets default royalty information.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(ROYALTY_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external onlyRole(ROYALTY_ROLE)
    {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     */
    function setTokenRoyalty(uint256 tokenId ,address receiver, uint96 feeNumerator) public onlyRole(ROYALTY_ROLE)
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function resetTokenRoyalty(uint256 tokenId) public onlyRole(ROYALTY_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    ////////////////////
    // baseURI

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    // function setBaseURI
    function setBaseURI(string calldata _base) public onlyRole(REVEAL_ROLE)
    {
        baseURI_ = _base;
        emit BaseURISet(_base);
    }


    ////////////////////
    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    function burn(uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        _requireMinted(tokenId);
        string memory base = _baseURI();
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual whenNotPaused onlyAllowedOperator(from) override(ERC721, IERC721) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual whenNotPaused onlyAllowedOperator(from) override(ERC721, IERC721) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        virtual whenNotPaused onlyAllowedOperator(from)
        override(ERC721, IERC721)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function renounceOwnership() public virtual onlyOwner override {
        revert("Ownership cannot be renounced");
    }

    ////////////////////
    // Bulk functions

    function bulkMint(uint8 amount, address toAddress) public onlyRole(MINTER_ROLE) {
        require(amount <= 255, "Amount should be 255 or less");
        for (uint8 i; i < amount; ++i) {
            mint(toAddress);
        }
    }

    function bulkTransfer(uint256[] calldata tokenIds, address from, address[] memory toAddresses) public virtual whenNotPaused onlyAllowedOperator(from) {
        uint256 length = tokenIds.length;
        require(length <= 255, "Length should be 255 or less");
        require(length == toAddresses.length, "TokenIds Length and toAddresses length are not matched");
        for (uint8 i; i < length; ++i) {
            super.safeTransferFrom(from, toAddresses[i], tokenIds[i]);
        }
    }

    function bulkBurn(uint256[] calldata tokenIds) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        uint256 length = tokenIds.length;
        require(length <= 255, "Length should be 255 or less");
        for (uint8 i; i < length; ++i) {
            _burn(tokenIds[i]);
        }
    }
}