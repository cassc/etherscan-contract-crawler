/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-unused-vars */
/* solhint-disable no-empty-blocks */
/* solhint-disable wonderland/non-state-vars-leading-underscore */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC721AUpgradeable, IERC721AUpgradeable, ERC721AStorage} from 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import {ERC721AQueryableUpgradeable, IERC721AQueryableUpgradeable} from 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
import {ERC721ABurnableUpgradeable, IERC721ABurnableUpgradeable} from 'erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol';
import {AccessControlUpgradeable, IAccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import {ERC2981Upgradeable, IERC2981Upgradeable} from '@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol';
import {DefaultOperatorFiltererUpgradeable} from 'operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol';

/**
 * ▄▀█ ▀█▀ █░░ ▄▀█ █▄░█ ▀█▀ █ █▀   █░█░█ █▀█ █▀█ █░░ █▀▄
 * █▀█ ░█░ █▄▄ █▀█ █░▀█ ░█░ █ ▄█   ▀▄▀▄▀ █▄█ █▀▄ █▄▄ █▄▀
 *
 *
 * Atlantis World is building the Web3 social metaverse by connecting Web3 with social,
 * gaming and education in one lightweight virtual world that's accessible to everybody.
 *
 * @title Atlanteans
 * @author Carlo Miguel Dy, Rachit Anand Srivastava
 */
contract Atlanteans is
    IERC721AUpgradeable,
    IAccessControlUpgradeable,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC2981Upgradeable,
    DefaultOperatorFiltererUpgradeable
{
    /// @notice The minter role hash format
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    /// @notice The maximum supply for this collection
    uint256 public constant MAX_SUPPLY = 6_450;

    /// @notice The maximum allowed quantity for minting per tx
    uint256 public constant MAX_QUANTITY_PER_TX = 19;

    /// @notice Where the royalties will be sent into
    address public treasury;

    /// @notice The URI for the token metadata
    string public baseURI;

    /// @notice Handles logic to return relevant URI, if false return mystery
    bool public reveal;

    mapping(address => bool) public allowedMarketplaces;

    event CharactersRevealed(string indexed uri);

    /**
     * @notice Reverts transaction when caller is not an Admin.
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Atlanteans: Only the Admin can call this function.');
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Atlanteans: Not admin or minter.');
        _;
    }

    /**
     * @notice Allows admin to mint a batch of tokens to a specified arbitrary address
     * @param to The receiver of the minted tokens
     * @param quantity The amount of tokens to be minted
     */
    function mintTo(address to, uint256 quantity) external whenNotPaused onlyMinter {
        _mint(to, quantity);
    }

    /**
     * @notice Pauses the contract.
     */
    function pause() external onlyAdmin whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     */
    function unpause() external onlyAdmin whenPaused {
        _unpause();
    }

    /**
     * @dev See {ERC2981Upgradeable-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyAdmin {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981Upgradeable-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyAdmin {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice Admin callable function to reveal characters.
     * @param uri string The baseURI from IPFS that have all character metadata.
     */
    function revealCharacters(string calldata uri) external onlyAdmin {
        require(!reveal, 'Atlanteans: Characters have already been revealed.');

        emit CharactersRevealed(uri);
        baseURI = uri;
        reveal = true;
    }

    /**
     * @dev Init.
     */
    function initialize(address _treasury, string calldata _defBaseURI) public initializerERC721A initializer {
        __ERC721A_init('Atlanteans', 'AWC');
        __AccessControl_init();
        __Ownable_init();
        __Pausable_init();
        __ERC2981_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setDefaultRoyalty(_treasury, 7_500);

        treasury = _treasury;
        baseURI = _defBaseURI;
    }

    /**
     * @notice Add a minter.
     */
    function addMinter(address _account) external onlyAdmin {
        _setupRole(MINTER_ROLE, _account);
    }

    /**
     * @notice Removes a minter.
     */
    function removeMinter(address _account) external onlyAdmin {
        _revokeRole(MINTER_ROLE, _account);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            interfaceId == type(IERC721AUpgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Computes the remaining supply.
     */
    function getRemainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    /**
     * @notice Get the next tokenId
     */
    function getCurrentIndex() public view returns (uint256) {
        return ERC721AStorage.layout()._currentIndex;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        if (!reveal) {
            return _baseURI();
        }

        return string(abi.encodePacked(super.tokenURI(tokenId), '.json'));
    }

    /**
     * @notice Prevents minting beyond the total supply & balance.
     * @dev See {ERC721AUpgradeable-_mint}.
     */
    function _mint(address to, uint256 quantity) internal virtual override {
        require(totalSupply() + quantity <= MAX_SUPPLY, 'Atlanteans: Unable to mint more than the max supply.');

        super._mint(to, quantity);
    }

    /**
     * @dev See {ERC721AUpgradeable-_startTokenId}.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {ERC721AUpgradeable-_baseURI}.
     * @inheritdoc ERC721AUpgradeable
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

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
    function approve(address operator, uint256 tokenId)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

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
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Update marketplace list
     * @param marketplace The address of marketplace to be whitelisted
     * @param allowed Whether market place is allowed or not
     */
    function setAllowedMarketplace(address marketplace, bool allowed) public onlyAdmin {
        allowedMarketplaces[marketplace] = allowed;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}