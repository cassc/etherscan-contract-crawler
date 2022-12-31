// SPDX-License-Identifier: MIT
//*Submitted for verification at Etherscan.io on 2022-12-30

//CREATORS: Smile Bubble Team

//  ██████  ███▄ ▄███▓ ██▓ ██▓    ▓█████  ▄▄▄▄    █    ██  ▄▄▄▄    ▄▄▄▄    ██▓    ▓█████   ██████ 
//▒██    ▒ ▓██▒▀█▀ ██▒▓██▒▓██▒    ▓█   ▀ ▓█████▄  ██  ▓██▒▓█████▄ ▓█████▄ ▓██▒    ▓█   ▀ ▒██    ▒ 
//░ ▓██▄   ▓██    ▓██░▒██▒▒██░    ▒███   ▒██▒ ▄██▓██  ▒██░▒██▒ ▄██▒██▒ ▄██▒██░    ▒███   ░ ▓██▄   
//  ▒   ██▒▒██    ▒██ ░██░▒██░    ▒▓█  ▄ ▒██░█▀  ▓▓█  ░██░▒██░█▀  ▒██░█▀  ▒██░    ▒▓█  ▄   ▒   ██▒
//▒██████▒▒▒██▒   ░██▒░██░░██████▒░▒████▒░▓█  ▀█▓▒▒█████▓ ░▓█  ▀█▓░▓█  ▀█▓░██████▒░▒████▒▒██████▒▒
//▒ ▒▓▒ ▒ ░░ ▒░   ░  ░░▓  ░ ▒░▓  ░░░ ▒░ ░░▒▓███▀▒░▒▓▒ ▒ ▒ ░▒▓███▀▒░▒▓███▀▒░ ▒░▓  ░░░ ▒░ ░▒ ▒▓▒ ▒ ░
//░ ░▒  ░ ░░  ░      ░ ▒ ░░ ░ ▒  ░ ░ ░  ░▒░▒   ░ ░░▒░ ░ ░ ▒░▒   ░ ▒░▒   ░ ░ ░ ▒  ░ ░ ░  ░░ ░▒  ░ ░
//░  ░  ░  ░      ░    ▒ ░  ░ ░      ░    ░    ░  ░░░ ░ ░  ░    ░  ░    ░   ░ ░      ░   ░  ░  ░  
//      ░         ░    ░      ░  ░   ░  ░ ░         ░      ░       ░          ░  ░   ░  ░      ░  
//                                             ░                ░       ░                         
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './DefaultOperatorFilterer.sol';

contract SmileBubbles is DefaultOperatorFilterer, ERC721A, ERC2981,Ownable, ReentrancyGuard {
    
     uint256 tokenCount;
    using Strings for uint256;
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    string private uriPrefix ="ipfs://QmXFxRjuGrjqNezezkxsoffjAT1pGUnRU3pQ4Q51fgVxgL/";
    string private uriSuffix = ".json";
    string public hiddenMetadataUri;
    //wallet Creator SmileBubble 0xBfEFBcC9c7D43F2fB026f1132c2A85AE83f7336D
    //MAX SUPPLY 
    uint256  public maxSupply = 10000;
    //MAX FREE 
    uint256 public maxFREETot = 5000;
    //COST AFTER 5 FREE 
    uint256 public cost = 0.002 ether;
    //MAX MINT PER TX 
    uint256 public maxMintAmountPerTx = 5;
    //MAX PER WALLET 
    uint8 public maxMintWt = 10;
    //MAX FREE PER WALLET 
    uint8 public maxFREEWt = 5;
    uint256 public whiteListCost = 0 ether;
    uint256 public freeAlreadyMint = 0;
    uint96 royaltyFeesInBips = 500;
    bool public whitelistMintEnabled = false;
    bool public paused = false;
    bool public revealed  =true;

    constructor(string memory _tokenName,
    string memory _tokenSymbol, 
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
     uint96 _royaltyFeesInBips
  ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        _setDefaultRoyalty(msg.sender,_royaltyFeesInBips);
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
        maxSupply = _maxSupply;
       
  }
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A,ERC2981)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
      //ROYALTY INFO FOR MARKETPLACE
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
      _setDefaultRoyalty(_receiver,_royaltyFeesInBips);
    }
    
    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        _;
    }
    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
        _;
    }
  function mint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) 
  {
    require(!paused, "Contract is paused!");
    require(balanceOf(msg.sender)<= maxMintWt, "Max per wallet");
    require(totalSupply() + _mintAmount < maxSupply + 1, "SOLD OUT");
    _safeMint(msg.sender, _mintAmount);
  }
  
  function mintFree(uint256 _mintAmount) external payable
  {
    //Number mint already
    require(totalSupply() + _mintAmount < maxSupply + 1, "SOLD OUT");
    uint256 AlreadyWt = balanceOf(msg.sender);

    if(freeAlreadyMint + _mintAmount > maxFREETot)
    {
        require((cost * _mintAmount) <= msg.value, " There aren't more Free");
    }
    else 
    {
        if (AlreadyWt + _mintAmount > maxFREEWt) 
        {
            require((cost * _mintAmount) <= msg.value," You have already minted Free ");
            require(_mintAmount <= maxMintAmountPerTx," You want much togheter");
        } 
        else 
        {
            require(_mintAmount <= maxFREEWt," You want much Free in your Wallet" );
            require(AlreadyWt <= maxFREEWt," You want much Free in your Wallet" );
            _safeMint(msg.sender, _mintAmount);
            freeAlreadyMint += _mintAmount;
        }
    }
  }
  
  //Allows you to start the mint from the toden id 1
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function MintWl(uint8 _amountPerAddress, address[] calldata addresses) external onlyOwner {
     uint16 totalSupply = uint16(totalSupply());
     uint totalAmount =   _amountPerAddress * addresses.length;
    require(totalSupply + totalAmount <= maxSupply, "Excedes max supply.");
     for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], _amountPerAddress);
     }
     delete _amountPerAddress;
     delete totalSupply;
  }
  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
      maxSupply = _maxSupply;
  }
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    if (revealed == false) {
      return hiddenMetadataUri;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString() ,uriSuffix))
        : "";
  }
   //Enable Whitelist sell function
   function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }
  function setWLCost(uint256 _cost) public onlyOwner {
    whiteListCost = _cost;
    delete _cost;
  }
 function setmaxMintWt(uint8 _limit) public onlyOwner{
    maxMintWt = _limit;
     delete _limit;
 }    
   function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }
   function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }
  function addToPresaleWhitelist(address[] calldata entries) external onlyOwner {
        for(uint8 i = 0; i < entries.length; i++) {
            whitelistClaimed[entries[i]] = true;
        }   
    }
 function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        // Verify whitelist requirements
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }
  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }
  function setPaused() public onlyOwner {
    paused = !paused;
  }
  function setCost(uint _cost) public onlyOwner{
      cost = _cost;
  }
  function setmaxFREEWt(uint8 _maxFREEWt) external onlyOwner{
      maxFREEWt = _maxFREEWt;
  }
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }
  function setMaxMintAmountPerTx(uint256 _maxtx) public onlyOwner{
      maxMintAmountPerTx = _maxtx;
  }
  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }
  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }
  function withdraw() public onlyOwner nonReentrant {
   
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
  function _baseURI() internal view  override returns (string memory) {
    return uriPrefix;
  }
}