// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../operator/DefaultOperatorFilterer.sol";
import "../interfaces/IERC721Initializable.sol";

contract ERC721ASource is
    ERC721AUpgradeable,
    ERC721ABurnableUpgradeable,
    ERC721AQueryableUpgradeable,
    IERC721Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    DefaultOperatorFilterer,
    OwnableUpgradeable,
    ERC2981
{
    event BaseURIUpdated(string indexed oldBaseUri, string indexed newBaseUri);
    event RoyaltyInfoSet(address indexed royaltyReceiver, uint256 royaltyFeeBps);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public maxCapacity;

    // metadata URI
    string private _baseTokenURI;

    function initialize(
        string calldata name,
        string calldata symbol,
        string calldata baseUri,
        uint256 maxCap,
        address admin,
        address minter
    ) external override initializerERC721A initializer {
        require(maxCap > 0, "!max_cap");
        __Ownable_init();
        __ERC721ABurnable_init();
        __ERC721AQueryable_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC721A_init(name, symbol);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, minter);

        maxCapacity = maxCap;
        _baseTokenURI = baseUri;
    }

    function safeMint(address to, uint256 quantity) external whenNotPaused onlyRole(MINTER_ROLE) {
        require(totalSupply() + quantity <= maxCapacity, "max_cap_reached");
        // In 721a _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(to, quantity);
    }

    function setBaseUri(string calldata newBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory oldBaseURI = _baseTokenURI;
        _baseTokenURI = newBaseUri;
        emit BaseURIUpdated(oldBaseURI, newBaseUri);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setRoyaltyInfo(uint96 _royaltyFeeBps, address _royaltyReceiver)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeBps);
        emit RoyaltyInfoSet(_royaltyReceiver, _royaltyFeeBps);
    }

    /** Internal Functions */

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred.
     * This includes minting. And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, AccessControlUpgradeable, ERC2981)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    // Operator filter overrides

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}