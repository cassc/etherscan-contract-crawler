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

contract PirateTakeover is ERC721r, ERC2981, Ownable, ReentrancyGuard, RevokableDefaultOperatorFilterer {
    using Counters for Counters.Counter;
    using Strings for uint256; //allows for uint256var.tostring()

    uint256 public MAX_MINT_PER_WALLET_SALE = 12;
    uint256 public MAX_MINT_PER_TX = 4;
    uint256 public MAX_FREE = 444;
    uint256 public MAX_FREE_PER_WALLET = 1;
    uint256 public price = 0.004 ether;

    string private baseURI;
    string public hiddenMetadataUri = "https://bafkreiaglipnjrecxkzakqtuv5kearda2c5jbxsb7jipcobrhc6ftmuc7y.ipfs.nftstorage.link/";
    bool public mintEnabled = false;
    bool public revealed = false;

    mapping(address => uint256) public users;
    mapping(address => uint256) public freeMints;

    constructor() ERC721r("PIRATE TAKEOVER", "PIRATE", 4_444) {
        _setDefaultRoyalty(0x70bd25f00986ae807917459581c81386c46E0B33, 500);
    }

    function mintSale(uint256 _amount) public payable {
        require(mintEnabled, "Sale is not enabled");
        if (totalSupply() + _amount <= MAX_FREE) {
            if (msg.value == 0) {
                require(freeMints[msg.sender] + _amount <= MAX_FREE_PER_WALLET, "Too many free per TX");
                freeMints[msg.sender] += _amount;
            } else {
                require(
                    price * (_amount - (MAX_FREE_PER_WALLET - freeMints[msg.sender])) <= msg.value,
                    "Not enough ETH for multiple NFTs"
                );
                require(_amount <= MAX_MINT_PER_TX, "Too many per TX");
                require(
                    users[msg.sender] + _amount <= MAX_MINT_PER_WALLET_SALE,
                    "Exceeds max mint limit per wallet")
                ;
                users[msg.sender] += _amount - MAX_FREE_PER_WALLET;
                freeMints[msg.sender] += MAX_FREE_PER_WALLET;
            }
        } else {
            require(price * _amount <= msg.value, "Not enough ETH");
            require(_amount <= MAX_MINT_PER_TX, "Too many per TX");
            require(
                users[msg.sender] + _amount <= MAX_MINT_PER_WALLET_SALE,
                "Exceeds max mint limit per wallet");
            users[msg.sender] += _amount;
        }
        _mintRandomly(msg.sender, _amount);
    }

    /// ============ INTERNAL ============
    function _mintRandomly(address to, uint256 amount) internal {
        _mintRandom(to, amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
        : "";
  }

    /// ============ ONLY OWNER ============
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setHiddenMetadataUri(string calldata _newHiddenMetadataURI) external onlyOwner {
        hiddenMetadataUri = _newHiddenMetadataURI;
    }

    function toggleSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
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