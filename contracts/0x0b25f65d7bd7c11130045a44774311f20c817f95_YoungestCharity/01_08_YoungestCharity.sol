// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract YoungestCharity is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public UriData = '';
  string public UriJson = '.json';
  string public MetadataUri;

  string public donation = 'Gustave Roussy and theyoungest.eth love you';

  uint256 public price = 0.0 ether;
  uint256 public maxSupply = 3103;
  uint256 public maxMintAmountPerTx = 10;
  uint256 public maxPerWallet = 100;

  bool public paused = true;
  bool public revealed = false;
  bool public weloveyou = true;
  mapping(address => uint256) public addressMintedBalance;


 constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _donation,
    uint256 _price,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxPerWallet,
    
    string memory _MetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    price = _price;
    maxSupply = _maxSupply;
    maxPerWallet = _maxPerWallet;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setMetadataUri(_MetadataUri);
    donation = _donation;

  }

  modifier YCCompliance(uint256 _mintAmount) {
    require(!paused, "Public sale didn't start");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'None NFT left ! ');
    require(addressMintedBalance[msg.sender] + _mintAmount <= maxPerWallet, 'You reached maximum nft you can get');
    require(msg.sender == tx.origin, 'No Astra and No CryAio please');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');
    _;
  }

  function mint(uint256 _mintAmount) public payable YCCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(msg.sender == tx.origin, 'No Astra and No CryAio please');

    addressMintedBalance[msg.sender] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public YCCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner)); 
        uint256 end = _nextTokenId();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;    
    }
  }
  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return MetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), UriJson))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setmaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMetadataUri(string memory _MetadataUri) public onlyOwner {
    MetadataUri = _MetadataUri;
  }

  function setUriData(string memory _UriData) public onlyOwner {
    UriData = _UriData;
  }

  function setUriJson(string memory _UriJson) public onlyOwner {
    UriJson = _UriJson;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return UriData;
  }
}