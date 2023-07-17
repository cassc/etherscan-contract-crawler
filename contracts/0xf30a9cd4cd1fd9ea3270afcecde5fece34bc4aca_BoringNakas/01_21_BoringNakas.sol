// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "./ERC721R.sol";
import "./lib/PunkVerify.sol";

contract BoringNakas is ERC721r, ERC2981, PunkVerify, Ownable, ReentrancyGuard, RevokableDefaultOperatorFilterer {
    using Strings for uint256; //allows for uint256var.tostring()

    address public constant BPUNKS  = 0x8Ce578bad214D59aEFAFB49bd20408E81271796F;

    uint256 public MAX_MINT_PER_WALLET_SALE = 10;
    uint256 public MAX_MINT_PER_TX = 10;
    uint256 public price = 0.008 ether;
    uint256 public mintCount;
    uint256 public claimCount;

    string private baseURI;

    bool public mintEnabled = false;
    bool public claimEnabled = false;

    mapping(address => uint256) public users;
    mapping(uint256 => bool) public claimed;

    constructor() ERC721r("BoringNakas", "BNAKA", 20_000) PunkVerify(0xC3AA9bc72Bd623168860a1e5c6a4530d3D80456c, 0x00000000000076A84feF008CDAbe6409d2FE638B) {
        _setDefaultRoyalty(0x57220b0f5335A054014808Be12457CD049B3867E, 690);
    }

    function mintSale(uint256 _amount) public payable {
        require(mintEnabled, "Sale is not enabled");
        require(price * _amount <= msg.value, "Not enough ETH");
        require(_amount <= MAX_MINT_PER_TX, "Too many per TX");
        require(mintCount + _amount <= 10000, "Not enough Nakas left for public mint");
        require(users[msg.sender] + _amount <= MAX_MINT_PER_WALLET_SALE,"Exceeds max mint limit per wallet");
        require(msg.sender == tx.origin, "No contracts");
        users[msg.sender] += _amount;
        mintCount += _amount;
        _mintRandomly(msg.sender, _amount);
    }

    function claim(uint256[] calldata punkIds) public {
        require(claimEnabled, "Claim is not enabled");
        uint256 numTokens = punkIds.length;
        require(claimCount + numTokens  <= 10000, "Not enough Nakas left to claim");
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 punkId = punkIds[i];
            require(!claimed[punkId], "Punk already claimed their naka");
            bool boringHolder = verifyTokenOwner(BPUNKS,punkId);
            require(boringHolder, "You don't own this BoringPunk");
            claimed[punkId] = true;
        }
        claimCount += numTokens;
        _mintRandomly(msg.sender, numTokens);
    }

    function checkClaim(uint256 punkId) public view returns (bool) {
        return claimed[punkId];
    }

    function burnBoringBurn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not your BoringNaka to burn.");
        _burn(tokenId);
    }

    /// ============ INTERNAL ============
    function _mintRandomly(address to, uint256 amount) internal {
        _mintRandom(to, amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// ============ ONLY OWNER ============
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function toggleSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function toggleClaim() external onlyOwner {
        claimEnabled = !claimEnabled;
    }

    function setMaxMintPerWalletSale(uint256 _limit) external onlyOwner {
        require(MAX_MINT_PER_WALLET_SALE != _limit, "New limit is the same as the existing one");
        MAX_MINT_PER_WALLET_SALE = _limit;
    }

    function setMaxMintPerTx(uint256 _limit) external onlyOwner {
        require(MAX_MINT_PER_TX != _limit, "New limit is the same as the existing one");
        MAX_MINT_PER_TX = _limit;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setRoyalty(address wallet, uint96 perc) external onlyOwner {
        _setDefaultRoyalty(wallet, perc);
    }

    function reserve(address to, uint256 tokenId) external onlyOwner {
        require(_ownerOf(tokenId) == address(0), "Token has been minted.");
        require(mintCount + 1 <= 10000, "Not enough Nakas left to reserve");
        mintCount++;
        _mintAtIndex(to, tokenId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /// ============ ERC2981 ============
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721r, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        ERC721r._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /// ============ OPERATOR FILTER REGISTRY ============
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view override(UpdatableOperatorFilterer, Ownable) returns (address) {
        return Ownable.owner();
    }
}