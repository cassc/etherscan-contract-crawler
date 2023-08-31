// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IWLBox.sol";
import "./ERC721ARoyalty.sol";

contract WLBox is 
    IWLBox,
    ERC721ARoyalty,
    AccessControlUpgradeable, 
    DefaultOperatorFiltererUpgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable {
    /**
     * @dev Roles
     * DEFAULT_ADMIN_ROLE
     * - can update royalty of each NFT
     * - can update role of each account
     *
     * OPERATOR_ROLE
     * - can update tokenURI
     * - can enable/disable mint
     * 
     * MINTER_ROLE
     * - can call mint function when mintEnabled is true
     *
     * OPENING ROLE
     * - can call burn function when the boxes are opening 
     *
     * DEPLOYER_ROLE
     * - can update the logic contract
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OPENING_ROLE = keccak256("OPENING_ROLE");    
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    uint256 public totalReserveMinted;
    bool public mintEnabled;
    uint public claimCount;
    
    mapping(uint256 => string) private _tokenURIs;
    string private baseURI;
    
    using StringsUpgradeable for uint256;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override only(DEPLOYER_ROLE) {}
    
    /**
     * @dev
     * Params
     * `adminAddress`: ownership and `DEFAULT_ADMIN_ROLE` will be granted 
     * `operatorAddress`: `OPERATOR_ROLE` will be granted
     * `minterAddress`: `MINTER_ROLE` will be granted
     * `boxOpeningAddress`: `OPENING_ROLE` will be granted
     * `defaultRoyaltyReceiver`: default royalty fee receiver
     * `defaultFeeNumerator`: default royalty fee
     * `nftClaimCount`: the number of NFT count that will be created when a box is opened
     */
    function initialize(
        string memory name, 
        string memory symbol,
        address adminAddress, 
        address operatorAddress,
        address minterAddress,
        address boxOpeningAddress,
        address defaultRoyaltyReceiver,
        uint96 defaultFeeNumerator,
        uint nftClaimCount) initializerERC721A initializer public {
        __ERC721A_init(name, symbol);
        __ERC721AQueryable_init_unchained();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __DefaultOperatorFilterer_init();
        __ReentrancyGuard_init();
        
        mintEnabled = true;
        claimCount = nftClaimCount;
        
        transferOwnership(adminAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(OPERATOR_ROLE, operatorAddress);
        _setupRole(MINTER_ROLE, minterAddress);
        _setupRole(OPENING_ROLE, boxOpeningAddress);
        _setupRole(DEPLOYER_ROLE, _msgSender());
        _setDefaultRoyalty(defaultRoyaltyReceiver, defaultFeeNumerator);
    }
    
    // modifier
    modifier only(bytes32 role) {
        require(hasRole(role, _msgSender()), "Caller does not have permission");
       _;
    }
    
    // viewer
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }
    
    function tokenURI(uint256 tokenId) 
        public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        _requireMinted(tokenId);
        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    // external
    /**
     * @dev Creates `quantity` tokens and assign them to `to`
     * 
     * Requirements
     * - the caller must have the `MINTER_ROLE`
     */
    function mint(address to, uint256 quantity, bool reserved) external only(MINTER_ROLE) nonReentrant returns (uint256, uint256) {
        require(quantity > 0, "Quantity cannot be zero");
        require(mintEnabled, "Mint has not been enabled");
        uint256 start = _nextTokenId();
        uint256 end = start + quantity -1;
        _safeMint(to, quantity);
        
        if (reserved) {
            totalReserveMinted += quantity;
        }        
        return (start, end);
    }
    
    /**
     * @dev Burns token list. It means opening boxes.
     * A contract that has `OPENING_ROLE` will burn tokens before creating new tokens
     * 
     * Requirements
     * - the caller must have the `OPENING_ROLE`
     */
    function burn(uint256[] calldata tokenIds) external only(OPENING_ROLE) {
        for (uint i=0; i<tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }
    
    // operator
    /**
     * @dev Enables mint
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setMintEnabled(bool enabled) external only(OPERATOR_ROLE) {
        mintEnabled = enabled;
    }
    
    /**
     * @dev Sets NFT ClaimCount that the number of NFT count that will be created when a box is opened
     */
    function updateClaimCount(uint count) external only(OPERATOR_ROLE) {
        claimCount = count;
    }
    
    /**
     * @dev Sets baseURI
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setBaseURI(string memory uri) external only(OPERATOR_ROLE) {
        baseURI = uri;
    }
    
    /**
     * @dev Sets TokenURI of a token
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setTokenURI(uint256 tokenId, string memory URI) external only(OPERATOR_ROLE) {
        _requireMinted(tokenId);
        _tokenURIs[tokenId] = URI;
    }
    
    /**
     * @dev Sets tokenURIs from `tokenIdFrom` to `tokenIdFrom + tokenURIs.length -1`
     *
     * Requirements
     * - the caller must have the `OPERATOR_ROLE`
     */
    function setTokenURIs(uint256 tokenIdFrom, string[] calldata tokenURIs) external only(OPERATOR_ROLE) {
        uint count = tokenURIs.length;
        uint256 tokenId = tokenIdFrom;
        for (uint i=0; i<count; i++) {
            _requireMinted(tokenId);
            _tokenURIs[tokenId] = tokenURIs[i];
            tokenId++;
        }
    }
    
    // Royalty interface
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external only(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    
    function deleteDefaultRoyalty() external only(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }
    
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external only(DEFAULT_ADMIN_ROLE){
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
    
    function resetTokenRoyalty(uint256 tokenId) external only(DEFAULT_ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }
    
    // OpenSea operator filter
    function setApprovalForAll(address operator, bool approved) 
        public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
        public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) 
        public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    // supportsInterface
    function supportsInterface(bytes4 interfaceId) 
        public view virtual 
        override(IERC721AUpgradeable, AccessControlUpgradeable, ERC721ARoyalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}