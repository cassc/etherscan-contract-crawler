// SPDX-License-Identifier: MIT
//*Submitted for verification at Etherscan.io on 2022-12-20

//CREATORS: Joseph Kurt,Jack Smith,Dona Smith
//A DAy WiTh PeDro, WOOF WOOOF WOOOOOFFFF!

//  .S_sSSs      sSSs   .S_sSSs     .S_sSSs      sSSs_sSSs    
// .SS~YS%%b    d%%SP  .SS~YS%%b   .SS~YS%%b    d%%SP~YS%%b   
// S%S   `S%b  d%S'    S%S   `S%b  S%S   `S%b  d%S'     `S%b  
// S%S    S%S  S%S     S%S    S%S  S%S    S%S  S%S       S%S  
// S%S    d*S  S&S     S%S    S&S  S%S    d*S  S&S       S&S  
// S&S   .S*S  S&S_Ss  S&S    S&S  S&S   .S*S  S&S       S&S  
// S&S_sdSSS   S&S~SP  S&S    S&S  S&S_sdSSS   S&S       S&S  
// S&S~YSSY    S&S     S&S    S&S  S&S~YSY%b   S&S       S&S  
// S*S         S*b     S*S    d*S  S*S   `S%b  S*b       d*S  
// S*S         S*S.    S*S   .S*S  S*S    S%S  S*S.     .S*S  
// S*S          SSSbs  S*S_sdSSS   S*S    S&S   SSSbs_sdSSS   
// S*S           YSSP  SSS~YSSY    S*S    SSS    YSSP~YSSY    
// SP                              SP                         
// Y                               Y                          
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './DefaultOperatorFilterer.sol';

contract Pedro is DefaultOperatorFilterer, ERC721A, ERC2981,Ownable, ReentrancyGuard {
    
     uint256 tokenCount;
    using Strings for uint256;
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    string private uriPrefix ="ipfs://QmfLwxXKsYLXmrz3iV4gPXKCrD3n25pGThA52HSrFmvgVJ/";
    string private uriSuffix = ".json";
    string public hiddenMetadataUri;
    //wallet Creator Pedro 0x3971f91dcB8283d3DF11884B94c1b4FCd05F537B
    //MAX SUPPLY WOOFWOOOFFF
    uint256  public maxSupply = 10000;
    //MAX FREE PEDRO WOOFWOOOFFF
    uint256 public maxFREEPedroTot = 4500;
    //COST PEDRO AFTER FIRST FREE WOOFWOOOFFF
    uint256 public cost = 0.004 ether;
    //MAX MINT PER TX WOOFWOOOFFF
    uint256 public maxMintAmountPerTx = 4;
    //MAX PEDRO PER WALLET WOOFWOOOFFF
    uint8 public maxMintPedrosWt = 4;
    //MAX FREE PEDRO PER WALLET WOOFWOOOFFF
    uint8 public maxFREEPedrosWt = 1;
    //WOOF WOOOF WOOOOF PEDRO RESERVE WOOFWOOOFFF
    uint16 public PedroReserve = 500;
    uint256 public whiteListCost = 0 ether;
    uint256 public freePedroAlready = 0;    
    uint96 royaltyFeesInBips = 1000;
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
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Pedro: Invalid mint amount!');
        require(totalSupply() + _mintAmount <= maxSupply, 'Pedro: Max supply exceeded!');
        _;
    }
    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, 'Pedro: WOOF WOOF Insufficient funds!');
        _;
    }
  function mint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) 
  {
    require(!paused, "Pedro is sleepping!");
    require(balanceOf(msg.sender)<= maxMintPedrosWt, "Pedro: WOOF WOOF Pedro max per wallet");
    require(totalSupply() + _mintAmount < maxSupply + 1, "Pedro: WOOF WOOF Pedro is SOLD OUT");
    _safeMint(msg.sender, _mintAmount);
  }

  function mintFreePedro(uint256 _mintAmount) external payable
  {
     //If at 4500 Free Pedros check cost 
     //Number mint already
     uint256 pedroWt = balanceOf(msg.sender);
    if(freePedroAlready + _mintAmount > maxFREEPedroTot)
    {
        require((cost * _mintAmount) <= msg.value, "Pedro: WOOF WOOF There aren't more Pedro Free");
    }
    else 
    {
        if (pedroWt + _mintAmount > maxFREEPedrosWt) 
        {
            require((cost * _mintAmount) <= msg.value,"Pedro: WOOF WOOF You have already minted Free Pedro");
            require(_mintAmount <= maxMintAmountPerTx,"Pedro: WOOF WOOF You want much Pedro togheter");
        } 
        else 
        {
            require(_mintAmount <= maxFREEPedrosWt,"Pedro: WOOF WOOF You want much Pedro Free in your Wallet" );
            require(pedroWt <= maxFREEPedrosWt,"Pedro: WOOF WOOF You want much Pedro Free in your Wallet" );
            _safeMint(msg.sender, _mintAmount);
            freePedroAlready += _mintAmount;
        }
    }
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
 function setmaxMintPedrosWt(uint8 _limit) public onlyOwner{
    maxMintPedrosWt = _limit;
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
 function setmaxFREEPedrosWt(uint8 _maxFREEPedrosWt) external onlyOwner{
      maxFREEPedrosWt = _maxFREEPedrosWt;
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