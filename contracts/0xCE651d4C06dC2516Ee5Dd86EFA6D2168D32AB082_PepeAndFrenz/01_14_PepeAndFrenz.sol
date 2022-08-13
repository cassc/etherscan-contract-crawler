// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract PepeAndFrenz is ERC721, ERC721Enumerable, Ownable {

    using Strings for uint256;

    bytes32 public ogMerkleRoot;
    bytes32 public wlMerkleRoot;

    mapping(address => uint256) public walletMintCount;

    string private _baseURIextended;
    uint256 public constant maxSupply = 5555;
    uint256 public constant maxMintAmountPerWallet = 3;
    uint256 public constant maxMintAmountPerTx = 20;
    uint256 public price = 0.0069 ether;
    uint256 public ogMintExpireTime = 1660312800;
    uint256 public wlMintExpireTime = 1660316400;
    uint256 public pubMintExpireTime = 1660320000;


    bool public saleIsActive = true;
    bool public _blindBoxOpened = false;
    string public _blindTokenURI = "";


    constructor() ERC721("PepeAndFrenz", "PEPE") {

    }


    function reserve(uint256 n) public onlyOwner {
        for (uint256 i = 0; i < n; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(saleIsActive, "PEPE: activity must be active to mint tokens");
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "PEPE:Invalid mint amount!");
        require(_mintAmount + walletMintCount[_msgSender()] <= maxMintAmountPerWallet, "PEPE:Max mints per wallet met");
        require(totalSupply() + _mintAmount <= maxSupply, "PEPE:Max supply exceeded!");
        _;
    }

    function _mintHelper(uint256 _mintAmount, address) private returns (bool){
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        return true;
    }

    function airdrop(address address_, uint64 airdropAmount) public onlyOwner {
        uint256 totalSupply = totalSupply();
        require(address_ != address(0), "PEPE: must be none zero address");
        require(airdropAmount > 0, "PEPE:invalid number of tokens");
        require(totalSupply + airdropAmount <= maxSupply, "PEPE:max supply exceeded");
        assert(_mintHelper(airdropAmount, address_));
    }

    function purchase(uint256 mintAmount, bytes32[] calldata _merkleProof, uint256 role) public payable mintCompliance(mintAmount) {
        uint256 freeMintCount;
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), "1"));
        if (role == 1) {
            require(MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf), "You are not the Fucking KINGLIST Pepepppppp");
            require(block.timestamp > ogMintExpireTime, "Wait Pepe King is having his breakfast");
            freeMintCount = 2;
        } else if (role == 2) {
            require(MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf), "You are not the Fucking GENELIST Pepepppppp");
            require(block.timestamp > wlMintExpireTime, "Wait Pepe King is having his breakfast again");
            freeMintCount = 1;
        } else {
            require(block.timestamp > pubMintExpireTime, "Pepe King always takes a nap after his breakfast");
            freeMintCount = 1;
        }
        freeMintCount = (freeMintCount > walletMintCount[_msgSender()]) ? (freeMintCount - walletMintCount[_msgSender()]) : 0;
        if (mintAmount > freeMintCount) {
            require(msg.value >= (mintAmount - freeMintCount) * price, "Noooo My poor Pepe");
        }
        assert(_mintHelper(mintAmount, _msgSender()));
        walletMintCount[_msgSender()] = mintAmount;
    }

    function setBlindBoxOpened(bool _status) public onlyOwner {
        _blindBoxOpened = _status;
    }
    //blindbox is opened
    function isBlindBoxOpened() public view returns (bool) {
        return _blindBoxOpened;
    }

    function setOgMerkleRoot(bytes32 _newOgMerkleRoot) public onlyOwner {
        ogMerkleRoot = _newOgMerkleRoot;
    }

    function setWlMerkleRoot(bytes32 _newWlMerkleRoot) public onlyOwner {
        wlMerkleRoot = _newWlMerkleRoot;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (_blindBoxOpened) {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
        } else {
            return _blindTokenURI;
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setBlindTokenURI(string memory blindTokenURI_) external onlyOwner() {
        _blindTokenURI = blindTokenURI_;
    }


    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setOgMintExpireTime(uint256 _ogMintExpireTime)public onlyOwner{
        ogMintExpireTime = _ogMintExpireTime;
    }

    function setWlMintExpireTime(uint256 _wlMintExpireTime)public onlyOwner{
        wlMintExpireTime = _wlMintExpireTime;
    }

    function setPbMintExpireTime(uint256 _pubMintExpireTime)public onlyOwner{
        pubMintExpireTime = _pubMintExpireTime;
    }
}