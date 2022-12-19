// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract DeKings is ERC721AQueryable, AccessControlEnumerable, DefaultOperatorFilterer{
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    string private _baseURI_;
    string private _contractURI;
    address private _openSeaProxy;

    bool public tradingDisabled = true;
    uint256 public maxSupply;

    string private _uriSuffix = ".json";

    uint256 public publicCost;
    uint256 public publicSupply;

    uint256 public whitelistCost;

    bytes32 public whitelistMerkleRoot;
    bool public whitelistMintEnabled = false;
    bool public publicMintEnabled = false;

    address public paymentReceiver;

    /**
     * @dev Emitted when general trading is activated
     */
    event enabledTrading(address account);

    event baseURIUpdated(string baseURI);


    constructor (string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        string memory baseURI_,
        string memory contractURI_,
        address openSeaProxy_,
        uint256 publicCost_,
        uint256 whitelistCost_,
        uint256 publicSupply_
    )
    ERC721A(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(WHITELIST_ROLE, _msgSender());
        _baseURI_ = baseURI_;
        _contractURI = contractURI_;
        _openSeaProxy = openSeaProxy_;
        maxSupply = maxSupply_;
        publicCost = publicCost_;
        whitelistCost = whitelistCost_;
        publicSupply = publicSupply_;
        paymentReceiver = _msgSender();
    }

    // Overwrite some default functions to prevent errors
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721A, IERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Transfer many tokens at once
     */
    function batchTransferFrom(address from, address to, uint256[] memory tokenId) public returns (bool) {
        for (uint256 i; i < tokenId.length; i++) {
            transferFrom(from, to, tokenId[i]);
        }
        return true;
    }

    /**
     * @dev Mint for whitelisted users
     */
    function mintWhitelist(uint256 amount, bytes32[] calldata _merkleProof) public payable {
        require(whitelistMintEnabled, "mintWhitelist: The whitelist sale is not enabled");
        require(msg.value >= (whitelistCost * amount), "mintWhitelist: Insufficient funds");
        require((_nextTokenId() + amount) <= (publicSupply + 1), "mintWhitelist: max public supply reached");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "mintWhitelist: Invalid merkle proof");

        (bool os, ) = payable(paymentReceiver).call{value: address(this).balance}('');
        require(os);

        _privateMint(_msgSender(), amount);
    }

    /**
     * @dev Mint for public users
     */
    function mintPublic(uint256 amount) public payable {
        require(publicMintEnabled, "mintPublic: The public sale is not enabled");
        require(msg.value >= publicCost * amount, "mintPublic: Insufficient funds");
        require((_nextTokenId() + amount) <= (publicSupply + 1), "mintPublic: max public supply reached");

        (bool os, ) = payable(paymentReceiver).call{value: address(this).balance}('');
        require(os);

        _privateMint(_msgSender(), amount);
    }


    /**
     * @dev Mint tokens for user with the MINTER_ROLE
     */
    function mintMinter(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "mintMinter: must have minter role to mint");
        _privateMint(to, amount);
    }

    function _privateMint(address to, uint256 amount) internal virtual {
        require((_nextTokenId() + amount) <= (maxSupply + 1), "mint: max supply reached");

        _mint(to, amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_baseURI_).length > 0 ? string(abi.encodePacked(_baseURI_, tokenId.toString(), _uriSuffix)) : "";
    }

    /**
     * @dev Sets `_baseURI_`
     */
    function setBaseURI(string memory baseURI_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setBaseURI: must have admin role");
        _baseURI_ = baseURI_;
        emit baseURIUpdated(baseURI_);
    }
    /**
     * @dev Sets `_uriSuffix`
     */
    function setUriSuffix(string memory uriSuffix_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setUriSuffix: must have admin role");
        _uriSuffix = uriSuffix_;
    }
    /**
     * @dev Sets `_contractURI`
     */
    function setContractURI(string memory contractURI_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setContractURI: must have admin role");
        _contractURI = contractURI_;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Enable trading
     */
    function enableTrading() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "enableTrading: must have admin role");
        tradingDisabled = false;
        emit enabledTrading(_msgSender());
    }



    function setPublicCost(uint256 _publicCost) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setPublicCost: Action is not allowed");
        publicCost = _publicCost;
    }
    function setWhitelistCost(uint256 _whitelistCost) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setWhitelistCost: Action is not allowed");
        whitelistCost = _whitelistCost;
    }
    function setPublicSupply(uint256 _publicSupply) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setpublicSupply: Action is not allowed");
        publicSupply = _publicSupply;
    }
    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setWhitelistMerkleRoot: Action is not allowed");
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }
    function setWhitelistMintEnabled(bool _whitelistMintEnabled) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setWhitelistMintEnabled: Action is not allowed");
        whitelistMintEnabled = _whitelistMintEnabled;
    }
    function setPublicMintEnabled(bool _publicMintEnabled) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setPublicMintEnabled: Action is not allowed");
        publicMintEnabled = _publicMintEnabled;
    }
    function setPaymentReceiver(address _paymentReceiver) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setPaymentReceiver: Action is not allowed");
        paymentReceiver = _paymentReceiver;
    }


    /**
     * @dev Sets `_openSeaProxy`
     */
    function setOpenSeaProxy(address openSeaProxy_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "setOpenSeaProxy: must have admin role");
        _openSeaProxy = openSeaProxy_;
    }

    /**
     * @dev See {ERC721A-_beforeTokenTransfer}.
     *
     * Requirements:
     * - the contract must not be paused.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        if(tradingDisabled){
            if(from != address(0)) // allow always minting
                require(hasRole(WHITELIST_ROLE, _msgSender()), "Trading is not yet enabled");
        }
    }

   /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(address owner, address operator) public override(IERC721A, ERC721A) view returns (bool) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        // for Polygon's Mumbai testnet, use 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
        if (operator == _openSeaProxy) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     */
    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    /**
    */

    function setApprovalForAll(address operator, bool approved) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override(IERC721A, ERC721A)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}