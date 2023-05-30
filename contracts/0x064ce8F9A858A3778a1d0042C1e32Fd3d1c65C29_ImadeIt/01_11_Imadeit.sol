// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ImadeIt is ERC721AQueryable,Ownable,ReentrancyGuard {
    using Strings for uint256;

    
    mapping(address => uint256) public holdersMinted;
    mapping(address => uint256) public hasMinted;
    mapping(address => uint256) public hasWlMinted;
    uint256 public cost;//0.0066
    uint256 public maxSupply;//6666
    uint256 public maxWlSupply;//4444
    uint256 public maxPerWallet;//10
    uint256 public maxPerWalletWl;//1
    uint256 public maxPerWalletHolders;//1
    string private baseURI;
    bool public publicMintActive = false;
    bool public wlMintActive = true;
    bool public holdersMintActive = false;
    bytes32 public merkleRoot;

    constructor(
        uint256  _cost,
        uint256 _maxSupply,
        uint256 _maxPerWallet,
        uint256 _maxWlSupply,
        uint256 _maxPerWl,
        uint256 _maxPerWalletHolders,
        string memory _baseuriPr
        ) ERC721A("ImadeIt", "IMI") {
            setCost(_cost);
            maxSupply = _maxSupply;
            setmaxPerWallet(_maxPerWallet);
            setmaxWlSupply(_maxWlSupply);
            setmaxPerWl(_maxPerWl);
            setmaxPerHolders(_maxPerWalletHolders);
            setBase(_baseuriPr);
        }

    function wlMint( bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        require(wlMintActive, "WL mint is not active!");
        require(hasWlMinted[msg.sender] < maxPerWalletWl, "Address already mint!");
        require(totalSupply() + 1 <= maxWlSupply,"Max. supply exceeded!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid proof!");
        hasWlMinted[msg.sender] += 1;
        _safeMint(msg.sender, 1);
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
    }

    function holdersMint(uint256 _mintAmount)
        public
        payable
        nonReentrant
    {
        require(holdersMintActive, "Holders mint is not active!");
        require(balanceOf(msg.sender) > 0,"You are not holder");
        require(holdersMinted[msg.sender]+_mintAmount <= maxPerWalletHolders,"You can't mint more!");
        require(totalSupply() + _mintAmount <= maxSupply,"Max supply exceeded!");
        holdersMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }


   

    function burn (uint256[] memory tokenIds) public{
        for (uint i = 0; i < tokenIds.length; i++){
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "You don't own this nft");
            _burn(tokenId);
        } 
       
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

    function setmaxPerWl(uint256 _maxPerWallet)
        public
        onlyOwner
    {
        maxPerWalletWl = _maxPerWallet;
    }
    function setmaxPerHolders(uint256 _maxPerWallet)
        public
        onlyOwner
    {
        maxPerWalletHolders = _maxPerWallet;
    }

    function setmaxWlSupply(uint256 _maxFreeSupply)
        public
        onlyOwner
    {
        maxWlSupply = _maxFreeSupply;
    }
    function setPublicMintActive(bool _state) public onlyOwner {
        publicMintActive = _state;
    }
    function setWlMintActive(bool _state) public onlyOwner {
        wlMintActive = _state;
    }
    function setHoldersMintActive(bool _state) public onlyOwner {
        holdersMintActive = _state;
    }
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
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