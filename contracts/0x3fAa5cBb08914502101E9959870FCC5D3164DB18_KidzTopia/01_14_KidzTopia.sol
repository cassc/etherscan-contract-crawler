// SPDX-License-Identifier: MIT

/*

██╗  ██╗██╗██████╗ ███████╗████████╗ █████╗ ██████╗ ██╗ █████╗
██║░██╔╝██║██╔══██╗╚════██║╚══██╔══╝██╔══██╗██╔══██╗██║██╔══██╗
█████═╝░██║██║░░██║░░███╔═╝░░░██║░░░██║░░██║██████╔╝██║███████║
██╔═██╗░██║██║░░██║██╔══╝░░░░░██║░░░██║░░██║██╔═══╝░██║██╔══██║
██║░╚██╗██║██████╔╝███████╗░░░██║░░░╚█████╔╝██║░░░░░██║██║░░██║
╚═╝░░╚═╝╚═╝╚═════╝░╚══════╝░░░╚═╝░░░░╚════╝░╚═╝░░░░░╚═╝╚═╝░░╚═╝

*/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract KidzTopia is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bool public mintStart = false;
  uint public mintPrice = 0.002 ether;
  uint public freeMint = 1;
  uint public maxMint = 20;
  uint public maxSupply = 6666;

  string public baseURI;

  mapping(address => uint256) public addressMinted;

  constructor() ERC721A('KidzTopia', 'KIDZ') {
  }

  function ownerMint(address _address, uint _mintAmount) external onlyOwner {
    require(maxSupply >= totalSupply() + _mintAmount, "KidzTopia: Sold out");
    _safeMint(_address, _mintAmount);
  }

  function mint(uint256 _mintAmount) external payable {
    require(mintStart, "KidzTopia: Mint is not live yet");
    require(maxSupply >= totalSupply() + _mintAmount, "KidzTopia: Sold out");
    require(_mintAmount > 0, "KidzTopia: Invalid mint amount");
    require(_mintAmount  <= maxMint, "KidzTopia: Exceed max mint");
    _safemint(_mintAmount);
  }

  function _safemint(uint256 _mintAmount) internal {
    if(addressMinted[msg.sender] < freeMint) {
      if(_mintAmount < freeMint) _mintAmount = freeMint;
      require(msg.value >= (_mintAmount - freeMint) * mintPrice,"KidzTopia: Claim Free NFT");
      addressMinted[msg.sender] += _mintAmount;
      _safeMint(msg.sender, _mintAmount);
    }
    else {
      require(msg.value >= _mintAmount * mintPrice,"KidzTopia: Invalid mint price");
      addressMinted[msg.sender] += _mintAmount;
      _safeMint(msg.sender, _mintAmount);
    }
  }

  function _startTokenId() internal view virtual override returns (uint256) { 
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setMintPrice(uint256 _mintPrice) public onlyOwner {
    mintPrice = _mintPrice;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxMint(uint256 _maxMint) public onlyOwner {
    maxMint = _maxMint;
  }

  function setRevealURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function setMintStart(bool _state) public onlyOwner {
    mintStart = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
}