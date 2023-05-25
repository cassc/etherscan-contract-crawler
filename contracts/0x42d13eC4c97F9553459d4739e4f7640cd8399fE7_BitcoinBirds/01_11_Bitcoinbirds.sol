// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BitcoinBirds is ERC721AQueryable,Ownable,ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => uint256) public hasMinted;
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxFreeSupply;
    uint256 public maxPerWallet;
    uint256 public maxPerWalletBirdList;
    string private baseURI;
    bool public publicMintActive = false;
    bool public freeMintActive = false;
    bool public birdListMintActive = true;

    event birdListEvents(address indexed _from, uint256 indexed _amount);
    event publicMintEvents(address indexed _from, uint256 indexed _amount);
    constructor(
        uint256  _cost,
        uint256 _maxSupply,
        uint256 _maxPerWallet,
        uint256 _maxFreeSupply,
        uint256 _maxPerFree,
        string memory _baseuriPr
        ) ERC721A("BitcoinBirds", "BB") {
            
            setCost(_cost);
            maxSupply = _maxSupply;
            setmaxPerWallet(_maxPerWallet);
            setmaxFreeSupply(_maxFreeSupply);
            setmaxPerFree(_maxPerFree);
            setBase(_baseuriPr);
        }

    function birdlistMint( bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        require(birdListMintActive, "Birdlist mint is not active!");
        uint256 _mintAmount = maxPerWalletBirdList;
        require(hasMinted[msg.sender] < _mintAmount, "Address already mint!");
        require(totalSupply() + _mintAmount <= maxFreeSupply,"Maxbirdlist supply exceeded!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid proof!");
        hasMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
        emit birdListEvents(msg.sender,_mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        nonReentrant
    {
        require(publicMintActive, "Public mint is not active!");
        require(hasMinted[msg.sender]+_mintAmount <= maxPerWallet,"You can't mint more!");
        require(totalSupply() + _mintAmount <= maxSupply,"Max supply exceeded!");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        hasMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
        emit publicMintEvents(msg.sender,_mintAmount);
    }

    function freeMint(uint256 _mintAmount)
        public
        payable
        nonReentrant
    {
        require(freeMintActive, "Free mint is not active!");
        require(hasMinted[msg.sender]+_mintAmount <= maxPerWalletBirdList,"You can't mint more!");
        require(totalSupply() + _mintAmount <= maxFreeSupply,"MaxFree supply exceeded!");
        hasMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
        emit publicMintEvents(msg.sender,_mintAmount);
    }

    function burn (uint256 tokenId) public{
        require(msg.sender == ownerOf(tokenId), "You don't own this nft");
        _burn(tokenId);
    }


    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        nonReentrant
        onlyOwner
    {
         require(totalSupply() + _mintAmount <= maxSupply,"Max supply exceeded!");
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = baseURI;
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), '.json'))
      : '';
  }


    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setmaxPerWallet(uint256 _maxPerWallet)
        public
        onlyOwner
    {
        maxPerWallet = _maxPerWallet;
    }

    function setmaxPerFree(uint256 _maxPerWallet)
        public
        onlyOwner
    {
        maxPerWalletBirdList = _maxPerWallet;
    }

    function setmaxFreeSupply(uint256 _maxFreeSupply)
        public
        onlyOwner
    {
        maxFreeSupply = _maxFreeSupply;
    }
    function setPublicMintActive(bool _state) public onlyOwner {
        publicMintActive = _state;
    }
     function setFreeMintActive(bool _state) public onlyOwner {
        freeMintActive = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBirdListMintActive(bool _state) public onlyOwner {
        birdListMintActive = _state;
    }
    function setBase(string memory _base) public onlyOwner {
        baseURI = _base;
    }
    function reserve(uint256 quantity) public payable onlyOwner {
        require(
            totalSupply() + quantity <= maxSupply,
            "Not enough tokens left"
        );
        _safeMint(msg.sender, quantity);
    }

    function withdraw() public payable onlyOwner {
     require(payable(msg.sender).send(address(this).balance));
    } 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}