// _______  _______  _______  _______  _______        ___  __   __  __   __  _______  _______  ______    _______ //
//|       ||       ||   _   ||       ||       |      |   ||  | |  ||  |_|  ||       ||       ||    _ |  |       |//
//|  _____||    _  ||  |_|  ||       ||    ___|      |   ||  | |  ||       ||    _  ||    ___||   | ||  |  _____|//
//| |_____ |   |_| ||       ||       ||   |___       |   ||  |_|  ||       ||   |_| ||   |___ |   |_||_ | |_____ //
//|_____  ||    ___||       ||      _||    ___|   ___|   ||       ||       ||    ___||    ___||    __  ||_____  |//
// _____| ||   |    |   _   ||     |_ |   |___   |       ||       || ||_|| ||   |    |   |___ |   |  | | _____| |//
//|_______||___|    |__| |__||_______||_______|  |_______||_______||_|   |_||___|    |_______||___|  |_||_______|//

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract SpaceJumpers is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public answer = 0x9e159dfcfe557cc1ca6c716e87af98fdcb94cd8c832386d0429b2b7bec02754f;        
  bytes32 public answer2; 
  bytes32 public merkleRoot;
  mapping(address => bool) public freeMintClaimed;
  mapping(address => bool) public whitelistClaimed;
  string public uriPrefix = '';  
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
    uint256 public cost;
  uint256 public _textv;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerWallet = 2;
  bool public whitelistMintEnabled = false;
  bool public paused = true;
  bool public revealed = false;
  bool public wlon = true;
  
  

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
   
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
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

function mint(uint256 _mintAmount, string memory _word, address _minter, bytes32 _secretmsg) public payable mintCompliance(_mintAmount) {
    answer2 = keccak256(abi.encodePacked(tx.origin));
    require(!paused, 'The contract is paused!');
    require(balanceOf(msg.sender) + _mintAmount <= maxMintAmountPerWallet, "Max mint per wallet exceeded!");
    require(_secretmsg == answer2); 
    require(keccak256(abi.encodePacked(_word)) == answer);
    require(_minter == tx.origin);
     
    
    if(!freeMintClaimed[_msgSender()]){
   
        if(_mintAmount>1){        
            require(msg.value >= cost * (_mintAmount-1), 'Insufficient funds!');
        }
           freeMintClaimed[_msgSender()]=true;
    }else{
            require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    }
      _safeMint(_msgSender(), _mintAmount);
    
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function whitelistOn(bool _wlon) public onlyOwner {
    wlon = _wlon;
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

  function returnwl() public view returns (bool){            
            return wlon;
  }  

  function value(address _input) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_input));
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
  

  function withdraw() public onlyOwner nonReentrant {
     
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
   
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}