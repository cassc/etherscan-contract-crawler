// SPDX-License-Identifier: MIT
//*Submitted for verification at Etherscan.io on 2022-12-20
                      
pragma solidity >=0.8.9 <0.9.0;
//
// ___  ___          _  ___  ___            _                _____              _____ _       _     
// |  \/  |         | | |  \/  |           | |              /  ___|            /  __ \ |     | |    
// | .  . | __ _  __| | | .  . | ___  _ __ | | _____ _   _  \ `--.  ___  __ _  | /  \/ |_   _| |__  
// | |\/| |/ _` |/ _` | | |\/| |/ _ \| '_ \| |/ / _ \ | | |  `--. \/ _ \/ _` | | |   | | | | | '_ \ 
// | |  | | (_| | (_| | | |  | | (_) | | | |   <  __/ |_| | /\__/ /  __/ (_| | | \__/\ | |_| | |_) |
// \_|  |_/\__,_|\__,_| \_|  |_/\___/|_| |_|_|\_\___|\__, | \____/ \___|\__,_|  \____/_|\__,_|_.__/ 
//                                                    __/ |                                         
//                                                   |___/                 
// 

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './DefaultOperatorFilterer.sol';

contract MadMonkeySeaClub is DefaultOperatorFilterer, ERC721A, ERC2981,Ownable, ReentrancyGuard {
    //MAX SUPPLY 7999
    //MAX MINT PER TX 3
    //MAX  PER WALLET 3
    //RESERVE 500
    //wallet Creator MadMonkeySeaClub 0xB78BFDddB50c16bDab54a1918c33E3db2ac6D7eb
    
    uint256 tokenCount;
    using Strings for uint256;
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    string private uriPrefix ="ipfs://QmV9a5Tjqifc2R7Ymo3D67PxWxHsbYVvyv8844Jv1e4nKP/";
    string private uriSuffix = ".json";
    string public hiddenMetadataUri;    
    uint256  public maxSupply = 7999;
    uint256 public cost = 0.000 ether;
    uint256 public maxMintAmountPerTx = 3;
    uint8 public maxMintMadMonkeySeaClubsWt = 3;
    uint8 public maxFREEMadMonkeySeaClubsWt = 3;
    uint16 public MadMonkeySeaClubReserve = 500;
    uint256 public whiteListCost = 0 ether;
    uint256 public freeMadMonkeySeaClubAlready = 0;    
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
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'MadMonkeySeaClub: Invalid mint amount!');
        require(totalSupply() + _mintAmount <= maxSupply, 'MadMonkeySeaClub: Max supply exceeded!');
        _;
    }
    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, 'MadMonkeySeaClub: Insufficient funds!');
        require(balanceOf(msg.sender) < maxFREEMadMonkeySeaClubsWt,"MadMonkeySeaClub: You want much MadMonkeySeaClub Free in your Wallet" );
        _;
    }
  function mint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) 
  {
    require(!paused, "MadMonkeySeaClub is sleepping!");
    require(balanceOf(msg.sender)<= maxMintMadMonkeySeaClubsWt, "MadMonkeySeaClub: MadMonkeySeaClub max per wallet");
    require(totalSupply() + _mintAmount <= maxSupply - MadMonkeySeaClubReserve, "MadMonkeySeaClub: MadMonkeySeaClub is SOLD OUT - 500 are reserved");
    _safeMint(msg.sender, _mintAmount);
  }
  //Allows you to start the mint from the toden id 1
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function Airdrop(uint8 _amountPerAddress, address[] calldata addresses) external onlyOwner {
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
 function setmaxMintMadMonkeySeaClubsWt(uint8 _limit) public onlyOwner{
    maxMintMadMonkeySeaClubsWt = _limit;
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
 function setmaxFREEMadMonkeySeaClubsWt(uint8 _maxFREEMadMonkeySeaClubsWt) external onlyOwner{
      maxFREEMadMonkeySeaClubsWt = _maxFREEMadMonkeySeaClubsWt;
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