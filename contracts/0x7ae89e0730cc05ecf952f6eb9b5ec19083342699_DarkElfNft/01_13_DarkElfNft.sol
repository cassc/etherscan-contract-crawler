//     ,---,                              ,-.             ,---,.  ,--,            
//   .'  .' `\                        ,--/ /|           ,'  .' |,--.'|     .--.,  
// ,---.'     \              __  ,-.,--. :/ |         ,---.'   ||  | :   ,--.'  \ 
// |   |  .`\  |           ,' ,'/ /|:  : ' /          |   |   .':  : '   |  | /\/ 
// :   : |  '  |  ,--.--.  '  | |' ||  '  /           :   :  |-,|  ' |   :  : :   
// |   ' '  ;  : /       \ |  |   ,''  |  :           :   |  ;/|'  | |   :  | |-, 
// '   | ;  .  |.--.  .-. |'  :  /  |  |   \          |   :   .'|  | :   |  : :/| 
// |   | :  |  ' \__\/: . .|  | '   '  : |. \         |   |  |-,'  : |__ |  |  .' 
// '   : | /  ;  ," .--.; |;  : |   |  | ' \ \        '   :  ;/||  | '.'|'  : '   
// |   | '` ,/  /  /  ,.  ||  , ;   '  : |--'         |   |    \;  :    ;|  | |   
// ;   :  .'   ;  :   .'   \---'    ;  |,'            |   :   .'|  ,   / |  : \   
// |   ,.'     |  ,     .-./        '--'              |   | ,'   ---`-'  |  |,'   
// '---'        `--`---'                              `----'             `--'     
                                                                               
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract DarkElfNft is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerWallet;

  bool public paused = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxMintAmountPerWallet,
    string memory _metadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    setMaxSupply(_maxSupply);
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
    setUriPrefix(_metadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(balanceOf(msg.sender) + _mintAmount <= maxMintAmountPerWallet, "Max mint per wallet exceeded!");
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
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

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}