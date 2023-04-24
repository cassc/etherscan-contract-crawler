// SPDX-License-Identifier: MIT
// 
//
//    Pindar Van Arman's
//      ___    ____   ____                      _                __   ______                    
//     /   |  /  _/  /  _/___ ___  ____ _____ _(_)___  ___  ____/ /  / ____/___ _________  _____
//    / /| |  / /    / // __ `__ \/ __ `/ __ `/ / __ \/ _ \/ __  /  / /_  / __ `/ ___/ _ \/ ___/
//   / ___ |_/ /   _/ // / / / / / /_/ / /_/ / / / / /  __/ /_/ /  / __/ / /_/ / /__/  __(__  ) 
//  /_/  |_/___/  /___/_/ /_/ /_/\__,_/\__, /_/_/ /_/\___/\__,_/  /_/    \__,_/\___/\___/____/       
//                                    /____/                                                  
//   100 AI Imagined Faces
//   100% On-Chain
//
//   Version 1.1
//   with special thanks to bitquence and brougkr

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "./Base64.sol";
import "./LiveMintEnabled.sol"; //BM Modification
import "./InflateLib.sol"; //bitquence Modification

contract AiImaginedFacesOnChain is ERC721A, Ownable, ReentrancyGuard, LiveMintEnabled { //BM Modification

  using Strings for uint256;

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;

  address public ownerAddress;
  address public theAdminAddress;
  string public collectionDescription = "AI Imagined Faces On-Chain";
 
  string public constant image_header = "<svg id='aiface' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1024 1024' width='1024' height='1024'><rect width='1024' height='1024'/>";
  string public constant image_footer = "<style> #aiface{}.bota { animation: 3.0s bota infinite alternate ease-in-out; } @keyframes bota { from { opacity: 0.75; } to { opacity: 0.1; }} #aiface2{}.mida { animation: 2.0s mida infinite alternate ease-in-out; } @keyframes mida { from { opacity: 0.75; } to { opacity: 0.1; }} #aiface3{}.topa { animation: 1.5s topa infinite alternate ease-in-out; } @keyframes topa { from { opacity: 0.75; } to { opacity: 0.1; }} #aiface4{}.bota2 { animation: 2.0s bota2 infinite alternate ease-in-out; } @keyframes bota2 { from { opacity: 0.1; } to { opacity: 0.75; }} #aiface5{}.mida2 { animation: 1.5s mida2 infinite alternate ease-in-out; } @keyframes mida2 { from { opacity: 0.1; } to { opacity: 0.75; }} #aiface6{}.topa2 { animation: 1.0s topa2 infinite alternate ease-in-out; } @keyframes topa2 { from { opacity: 0.1; } to { opacity: 0.75; }} </style> </svg>";

  struct tokenData {    
        string name;
        bytes image_content;
        uint origsize;
        string trait;
        bool updated;
  }

  mapping (uint256 => tokenData) tokens;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx
    ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
  }

function aiImaginedFace(uint _tokenId) public view returns (string memory) {
      return string(abi.encodePacked(
              'data:image/svg+xml;base64,', Base64.encode(bytes(abi.encodePacked(
                            image_header,
                            InflateLib.puff(tokens[_tokenId].image_content, tokens[_tokenId].origsize),
                            image_footer
                          ))))); 
  }   

function aiImaginedFaces(uint _tokenId) public view returns (string memory) {
      return string(abi.encodePacked(
              'data:image/svg+xml;base64,', Base64.encode(bytes(abi.encodePacked(
                            image_header,
                            "<g>",
                            buildColumn(_tokenId+3,"</g><g transform='translate(0 "),
                            buildColumn(_tokenId,"</g><g transform='translate(341.333 "),
                            buildColumn(_tokenId+6,"</g><g transform='translate(682.666 "),
                            "</g>",
                            image_footer
                          ))))); 
  }   

  function buildColumn(uint256 _tokenId, string memory _xystring) public view returns(string memory) {
          return string(abi.encodePacked(
            _xystring,
            "0) scale(0.3333 0.3333)'>",
            InflateLib.puff(tokens[_tokenId+1].image_content, tokens[_tokenId+1].origsize),
            _xystring,
            "341.333) scale(0.3333 0.3333)'>",
             InflateLib.puff(tokens[_tokenId].image_content, tokens[_tokenId].origsize),
            _xystring,
            "642.666) scale(0.3333 0.3333)'>",
            InflateLib.puff(tokens[_tokenId+2].image_content, tokens[_tokenId+2].origsize)
          ));
  }

  function aiImaginedFaceText(uint _tokenId) public view returns (string memory) {
      return string(abi.encodePacked(
                            image_header,
                            InflateLib.puff(tokens[_tokenId].image_content,tokens[_tokenId].origsize),
                            image_footer
                          )); 
  }   

  //BM Modifications
  function purchaseTo(address Recipient) override virtual external onlyLiveMint returns (uint tokenID) 
  {
       _safeMint(Recipient, 1);
       return (totalSupply() - 1);
  }

  function ownerMint(uint256 _mintAmount) public onlyOwner {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    _safeMint(_msgSender(), _mintAmount);
  }

  function _ChangeLiveMintAddress(address LiveMintAddress) override virtual external onlyOwner 
  { 
    _LIVE_MINT_ADDRESS = LiveMintAddress; 
  }
  //BM Modifications

  modifier requireAdminOrOwner() {
    require(theAdminAddress == msg.sender || ownerAddress == msg.sender,"Requires admin or owner privileges");
    _;
  }

  function setAdminAddress(address _adminAddress) public onlyOwner{
        theAdminAddress = _adminAddress;
  }

  //Set permissions for relayer
  //pass in bytes and orig size
  function setTokenInfo(uint _tokenId, string memory _name, bytes memory _image_content_bytes, uint _origsize, string memory _trait) public requireAdminOrOwner() { 
        //require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        tokens[_tokenId].name = _name;
        tokens[_tokenId].trait = _trait;
        tokens[_tokenId].updated = true;
        tokens[_tokenId].origsize = _origsize;
        //bytes uncompressed_image = ???
        //_image_content_string = ???
        tokens[_tokenId].image_content = _image_content_bytes;
  }

  function buildMetadata(uint256 _tokenId) public view returns(string memory) {
            return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          tokens[_tokenId].name,
                          '", "description":"', 
                          collectionDescription,
                          '", "attributes":', 
                          tokens[_tokenId].trait,
                          ', "image": "',
                          'data:image/svg+xml;base64,', Base64.encode(bytes(abi.encodePacked( 
                            image_header,
                            InflateLib.puff(tokens[_tokenId].image_content, tokens[_tokenId].origsize),
                            image_footer))),
                          '"}'))))); 
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
      return buildMetadata(_tokenId);
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

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;
    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];
      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }
        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;
          ownedTokenIndex++;
        }
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

}