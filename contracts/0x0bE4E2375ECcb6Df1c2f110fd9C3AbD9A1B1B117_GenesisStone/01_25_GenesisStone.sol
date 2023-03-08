//SPDX-License-Identifier: Unlicense
// Version 0.0.5

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

contract GenesisStone is
    ERC721ABurnable,
    ERC721AQueryable,
    AccessControl,
    Ownable,
    ERC2981,
    OperatorFilterer
{
    using Address for address;
    using Strings for uint256;
    using ECDSA for bytes32;

    /**
     * Default admin is zero address
     */
    error AdminIsZeroAddress();

    /**
     * Default owner is zero address
     */
    error OwnerIsZeroAddress();

    /**
     * Royalty is zero
     */
    error RoyaltyIsZero();

    /**
     * The signature is invalid
     */
    error InvalidSignature();

    /**
     * The number of NFTs exceeds the limit
     */
    error NFTQuantityExceedsLimit();

    /**
     * There's no private mint
     */
    error EmptyPrivateMint();

    /**
     * Unmatched private mint address and quantities
     */
    error UnmatchedMintAddressesAndQuantities();

    /**
     * Transfer ownership to zero address
     */
    error TransferOwnershipToZeroAddress();

    /**
     * Whitelister already minted
     */
    error WhitelisterAlreadyMinted();

    /**
     * The person is not whitelisted
     */
    error NotWhitelisted();

    /**
     * The current owner is not intended to be the owner of the Mythic stone
     */
    error InvalidMythicOwner();

    // Constants
    uint32 public constant MAX_NFTS = 1000; // Maximum allowed number of NFTs
    address public constant CUSTOM_SUBSCRIPTION =
        address(0x31d1d81dAA99f1370b02362f5C646E5595eedABa);

    // Public variable
    bytes32 public merkleRoot; // Merkle root for whitelisting

    // Private variables
    string private _baseURI_;
    string private _mythicBaseURI_;
    string private _contractURI;
    mapping(address => uint256) private _whitelistMinted;
    mapping(uint256 => bool) private _isMythic;

    constructor(
        address defaultAdmin_,
        address defaultOwner_,
        uint96 defaultRoyalty_,
        string memory baseURI_,
        string memory contractURI_,
        address[] memory tos_,
        uint256[] memory quantities_
    )
        ERC721A("Genesis Dimensional Stones", "DMG")
        OperatorFilterer(0x0000000000000000000000000000000000000000, false)
    {
        if (defaultAdmin_ == address(0)) {
            revert AdminIsZeroAddress();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);

        if (defaultOwner_ == address(0)) {
            revert OwnerIsZeroAddress();
        }
        _transferOwnership(defaultOwner_);

        if (defaultRoyalty_ == 0) {
            revert RoyaltyIsZero();
        }
        _setDefaultRoyalty(defaultAdmin_, defaultRoyalty_);

        _baseURI_ = baseURI_;
        _mythicBaseURI_ = baseURI_;
        _contractURI = contractURI_;

        if (tos_.length != quantities_.length) {
            revert UnmatchedMintAddressesAndQuantities();
        }
        for (uint256 i = 0; i < tos_.length; i++) {
            _safeMint(tos_[i], quantities_[i]);
        }

        if (_nextTokenId() == 0) {
            revert EmptyPrivateMint();
        }
    }

    //--------------------------------------------------------------//
    //    The following functions are for setting Mythic stone.     //
    //--------------------------------------------------------------//

    /// Set a stone to be Mythic
    function setMythicToken(
        address owner,
        uint256 tokenId_,
        bool isMythic_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (ownerOf(tokenId_) != owner) {
            revert InvalidMythicOwner();
        }
        _isMythic[tokenId_] = isMythic_;
    }

    /// Get mythicBaseURI
    function mythicBaseURI() public view returns (string memory) {
        return _mythicBaseURI_;
    }

    /// Set Mythic stone base URI
    function setMythicBaseURI(string memory _mythicBaseUri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mythicBaseURI_ = _mythicBaseUri;
    }

    //--------------------------------------------------------------//
    // The following functions are required to mint by merkle tree. //
    //--------------------------------------------------------------//
    function setMerkleRoot(bytes32 merkleRoot_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        merkleRoot = merkleRoot_;
    }

    function whitelistMint(bytes32[] calldata proof_) external {
        if (!_isWhitelisted(msg.sender, proof_)) {
            revert NotWhitelisted();
        }
        if (_whitelistMinted[msg.sender] > 0) {
            revert WhitelisterAlreadyMinted();
        }
        _whitelistMinted[msg.sender] = _nextTokenId();
        _safeMint(msg.sender, 1);
    }

    function whitelistMintedTokenId() external view returns (uint256) {
        return _whitelistMinted[msg.sender];
    }

    function _isWhitelisted(address account_, bytes32[] calldata proof_)
        internal
        view
        returns (bool)
    {
        return _verify(_leaf(account_), proof_);
    }

    function _leaf(address account_) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account_));
    }

    function _verify(bytes32 leaf_, bytes32[] memory proof_)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof_, merkleRoot, leaf_);
    }

    /**
     * @dev Limit the maximum number of NFTs to MAX_NFTS
     */
    function _mint(address to_, uint256 quantity_)
        internal
        virtual
        override(ERC721A)
    {
        if (totalSupply() + quantity_ > MAX_NFTS) {
            revert NFTQuantityExceedsLimit();
        }
        super._mint(to_, quantity_);
    }

    //------------------//
    // Custom overrides //
    //------------------//
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(IERC721A, ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory __baseURI = _isMythic[tokenId]
            ? _mythicBaseURI_
            : _baseURI_;
        return
            bytes(__baseURI).length > 0
                ? string(
                    abi.encodePacked(__baseURI, tokenId.toString(), ".json")
                )
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURI_;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory baseURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseURI_ = baseURI_;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function getOwnershipAt(uint256 index)
        public
        view
        returns (TokenOwnership memory)
    {
        return _ownershipAt(index);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    //--------------------------------------------------//
    // The following functions are required by Opensea. //
    //--------------------------------------------------//

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string calldata contractURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _contractURI = contractURI_;
    }

    function _checkFilterOperatorCustom(address registrant, address operator)
        internal
        view
        virtual
    {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (
                !OPERATOR_FILTER_REGISTRY.isOperatorAllowed(
                    registrant,
                    operator
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    /**
     * Checks if the operator is allowed to perform an action
     * on behalf of the CUSTOM_SUBSCRIPTION address.
     */
    modifier onlyAllowedOperatorApprovalCustom(address operator) virtual {
        _checkFilterOperatorCustom(CUSTOM_SUBSCRIPTION, operator);
        _;
    }

    /**
     * Checks if the operator is allowed to perform an action
     * on behalf of the CUSTOM_SUBSCRIPTION address.
     */
    modifier onlyAllowedOperatorCustom(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperatorCustom(CUSTOM_SUBSCRIPTION, msg.sender);
        }
        _;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
        onlyAllowedOperatorApprovalCustom(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
        onlyAllowedOperatorApprovalCustom(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
        onlyAllowedOperatorCustom(from)
    {
        if (_isMythic[tokenId]) {
            _isMythic[tokenId] = false;
        }
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
        onlyAllowedOperatorCustom(from)
    {
        if (_isMythic[tokenId]) {
            _isMythic[tokenId] = false;
        }
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
        onlyAllowedOperatorCustom(from)
    {
        if (_isMythic[tokenId]) {
            _isMythic[tokenId] = false;
        }
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //------------------------------------------------------------//
    //      The following functions are for contract ownership    //
    //------------------------------------------------------------//

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner_)
        public
        override(Ownable)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (newOwner_ == address(0)) {
            revert TransferOwnershipToZeroAddress();
        }
        _transferOwnership(newOwner_);
    }

    function renounceOwnership()
        public
        override(Ownable)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _transferOwnership(address(0));
    }

    //------------------------------------------------------------//
    // The following functions are overrides required by Solidity.//
    //------------------------------------------------------------//

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC721A, ERC721A, AccessControl, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721A).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}