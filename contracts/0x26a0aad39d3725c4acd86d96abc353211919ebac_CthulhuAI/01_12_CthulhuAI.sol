// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract CthulhuAI is ERC721A, Ownable { 

  using Strings for uint256;

  string private uriPrefix = "ipfs://bafybeicojwlvdpj3amjbtuexs5dvsxto7yey63nq32s37jyfkpbenhd6wy/";
  string public uriSuffix = ".json"; 
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.005 ether; 

  uint256 public maxSupply = 333;
  uint256 public maxMintAmountPerTx = 2;
  uint256 public totalMaxMintAmount = 6;

  uint256 public freeMaxMintAmount = 0; 

  bool public paused = false;
  bool public publicSale = true;
  bool public revealed = true;

  mapping(address => uint256) public addressMintedBalance; 

  constructor() ERC721A("CthulhuAI", "CthulhuAI") { 
         setHiddenMetadataUri("ipfs://bafybeicojwlvdpj3amjbtuexs5dvsxto7yey63nq32s37jyfkpbenhd6wy/hidden.json"); 
            ownerMint(10); 
    } 

  modifier mintCompliance(uint256 _mintAmount) {
    if (msg.sender != owner()) { 
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    }
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  } 

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
   if (ownerMintedCount >= freeMaxMintAmount) {
        require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
   }
        _;
  }

   function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!'); 
    require(publicSale, "Not open to public yet!");
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];

    if (ownerMintedCount < freeMaxMintAmount) {  
            require(ownerMintedCount + _mintAmount <= freeMaxMintAmount, "Exceeded Free Mint Limit");
        } else if (ownerMintedCount >= freeMaxMintAmount) { 
            require(ownerMintedCount + _mintAmount <= totalMaxMintAmount, "Exceeded Mint Limit");
        }

    _safeMint(_msgSender(), _mintAmount);
    for (uint256 i = 1; i <=_mintAmount; i++){
        addressMintedBalance[msg.sender]++;
    }
  }

  function ownerMint(uint256 _mintAmount) public payable onlyOwner {
     require(_mintAmount > 0, 'Invalid mint amount!');
     require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_msgSender(), _mintAmount);
  }

function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }
  
  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost; 
  }

   function setFreeMaxMintAmount(uint256 _freeMaxMintAmount) public onlyOwner {
    freeMaxMintAmount = _freeMaxMintAmount; 
  }

  function setTotalMaxMintAmount(uint _amount) public onlyOwner {
      require(_amount <= maxSupply, "Exceed total amount");
      totalMaxMintAmount = _amount;
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

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setPublicSale(bool _state) public onlyOwner {
    publicSale = _state;
  }

  // WITHDRAW
    function withdraw() public payable onlyOwner {
  
    (bool os, ) = payable(owner()).call{value: address(this).balance}(""); 
    require(os);
   
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}