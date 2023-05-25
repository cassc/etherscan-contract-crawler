// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "../../eip712/NativeMetaTransaction.sol";
import "../../eip712/ContextMixin.sol";
import "./ERC721APausable.sol";
import {DefaultOperatorFilterer721, OperatorFilterer721} from "../../opensea/DefaultOperatorFilterer721.sol";

contract BMMxNeymarJr_EP01_HUMAN is
    ERC721A,
    ERC721ABurnable,
    ERC721AQueryable,
    ERC721APausable,
    AccessControl,
    DefaultOperatorFilterer721,
    Ownable,
    ContextMixin,
    NativeMetaTransaction
{
    // Create a new role identifier for the minter role
    bytes32 public constant MINER_ROLE = keccak256("MINER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // using Counters for Counters.Counter;
    // Counters.Counter private currentTokenId;
    /// @dev Base token URI used as a prefix by tokenURI().
    string private baseTokenURI;
    string private collectionURI;
    mapping(address => bool) public disapprovedMarketplaces;

    constructor() ERC721A("NeymarJR", "NJR") {
        _initializeEIP712("NeymarJR");
        baseTokenURI = "https://cdn.nftstar.com/neymar/human/metadata/";
        collectionURI = "https://cdn.nftstar.com/neymar/human/contract.json";
        // Grant the contract deployer the default admin role: it will be able to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSenderERC721A());
        _setupRole(MINER_ROLE, _msgSenderERC721A());
        _setupRole(PAUSER_ROLE, _msgSenderERC721A());
    }
    function transferFrom(address from, address to, uint256 tokenId)
    public payable
    override(IERC721A,ERC721A)
    onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
    public payable
    override(IERC721A,ERC721A)
    onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override(IERC721A,ERC721A)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function mintTo(address to) public onlyRole(MINER_ROLE) {
        _mint(to, 1);
    }

    function mint(address to, uint256 quantity) public onlyRole(MINER_ROLE) {
        _safeMint(to, quantity);
    }

    function setDisapprovedMarketplace(address market, bool isDisapprove)
    external
    onlyRole(MINER_ROLE)
    {
        disapprovedMarketplaces[market] = isDisapprove;
    }

    function approve(address to, uint256 tokenId)
    public
    payable
    virtual
    override(IERC721A,ERC721A)
    {
        require(!disapprovedMarketplaces[to], "The address is not approved");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override(IERC721A,ERC721A)
    {
        require(
            !disapprovedMarketplaces[operator],
            "The address is not approved"
        );
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSenderERC721A()),
            "HUMAN: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSenderERC721A()),
            "HUMAN: must have pauser role to unpause"
        );
        _unpause();
    }

    function current() public view returns (uint256) {
        return _totalMinted();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    function setContractURI(string memory _contractURI)
        public
        onlyRole(MINER_ROLE)
    {
        collectionURI = _contractURI;
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI)
        public
        onlyRole(MINER_ROLE)
    {
        baseTokenURI = _baseTokenURI;
    }

    function transferRoleAdmin(address newDefaultAdmin)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, newDefaultAdmin);
    }

    function grantMinerRole(address _miner) external onlyOwner {
        _grantRole(MINER_ROLE, _miner);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A,ERC721A,AccessControl)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _msgSenderERC721A()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}