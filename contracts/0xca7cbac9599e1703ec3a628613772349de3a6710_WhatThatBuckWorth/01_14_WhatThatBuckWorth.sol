// SPDX-License-Identifier: MIT

/**
Y8b Y8b Y888P 888               d8       d8   888               d8                          
 Y8b Y8b Y8P  888 ee   ,"Y88b  d88      d88   888 ee   ,"Y88b  d88                          
  Y8b Y8b Y   888 88b "8" 888 d88888   d88888 888 88b "8" 888 d88888                        
   Y8b Y8b    888 888 ,ee 888  888      888   888 888 ,ee 888  888                          
    Y8P Y     888 888 "88 888  888      888   888 888 "88 888  888                          
                                                                                            
                                                                                            
888                         888                                       d8   888     ,8,'88b  
888 88e  8888 8888  e88'888 888 ee   Y8b Y8b Y888P  e88 88e  888,8,  d88   888 ee   "  888D 
888 888b 8888 8888 d888  '8 888 P     Y8b Y8b Y8P  d888 888b 888 "  d88888 888 88b     88P  
888 888P Y888 888P Y888   , 888 b      Y8b Y8b "   Y888 888P 888     888   888 888    ,"'   
888 88"   "88 88"   "88,e8' 888 8b      YP  Y8P     "88 88"  888     888   888 888   "8"    
                                                                                                                                                                                                
*/

pragma solidity >=0.8.9 <0.9.0;

import './ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract WhatThatBuckWorth is ERC721, ERC2981, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using SafeERC20 for IERC20;

  string public uriPrefix = '';
  string public constant uriSuffix = '.json';

  uint256 public constant cost = 0;
  uint256 public constant maxSupply = 1971;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;


  constructor(
    address _royaltyReceiver,
    uint96 _royaltyFeeNumerator
  ) ERC721("What That Buck Worth", "WTBW") {
    setMaxMintAmountPerTx(1);

    setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, '1 per tx pls');
    require(_currentIndex + _mintAmount - 1 <= maxSupply, 'hell yeah! sold out');
    _;
  }

  modifier mintPriceCompliance() {
    // Do you know what happened in 1971?
    if (_currentIndex == 1971) {
      require(msg.value >= 1971 ether, '1971 eth bro');
    }
    _;
  }

  function mint(uint256 _mintAmount) public payable mintPriceCompliance() mintCompliance(_mintAmount) {
    require(!paused, 'pls wait');
    require(_msgSender() != address(0), "who is this buck for");

    for (uint256 i = 0; i < _mintAmount; i++) {
      payTaxForOwner();
      _mint(_msgSender());
    }
  }

  function payTaxForOwner() internal mintCompliance(1) {
    // The Only Two Certainties In Life Are Death And Taxes.
    if (
        _currentIndex == 2 ||
        _currentIndex == 5 ||
        _currentIndex == 10 ||
        _currentIndex == 20 ||
        _currentIndex == 50 ||
        _currentIndex == 100
    ) {
      _mint(owner());
    }
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_tokenId > 0 && _tokenId < _currentIndex, 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual returns (string memory) {
    return uriPrefix;
  }

  function withdrawERC20(IERC20 token) public onlyOwner nonReentrant {
    token.safeTransfer(owner(), token.balanceOf(address(this)));
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  receive() external payable {
    // do nothing
  }

  function getETHBalance() external view returns (uint256) {
    return address(this).balance;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function totalSupply() public view returns (uint256) {
    return _currentIndex - 1;
  }
}