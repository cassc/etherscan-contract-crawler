// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import {DefaultOperatorFilterer} from './DefaultOperatorFilterer.sol';

contract PepesAJoke is ERC721A, DefaultOperatorFilterer, Ownable, ReentrancyGuard { 
  using Strings for uint256;

  string public uri = 'ipfs://bafybeid7pnomgxcyfafi6bo6hvez7xxrk4o7gn2pu37rekz7fm5z3y72z4/'; 
  
  uint256 public cost = 0.002 ether;  
  uint256 public maxSupply = 6969;
  uint256 public maxPerWallet = 10; 
  bool public paused = true;  
  address public PROJECT_WALLET = 0x4B42562f30e52b30c94302A5CA23d26ded965E38;  
  address public DEV_WALLET = 0xd43D74Ea757A5565374b90844B8AaD7DE5A84E58; 

  constructor() ERC721A("Pepe's a Joke!", "PAJ") { 
    mintForAddress(1,owner());
  } 

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, 'Invalid mint amount!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxPerWallet, 'Max Limit per Wallet!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
    require(!paused, 'The contract is paused!');
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), '.json'))
        : '';
  } 

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  } 

  function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
  } 

  function setUri(string memory _uri) public onlyOwner {
    uri = _uri;
  } 

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  } 

  function withdraw() public onlyOwner nonReentrant {   
    uint256 balance = address(this).balance;  
    payable(DEV_WALLET).transfer((balance * 5 / 100)); 
    payable(PROJECT_WALLET).transfer(address(this).balance); 
  } 

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  function setDevWallet(address _devWallet)public onlyOwner{
    DEV_WALLET = _devWallet;
  }

  function setProjectWallet(address _projectWallet)public onlyOwner{
    PROJECT_WALLET = _projectWallet;
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
  public payable
  override
  onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  } 
}