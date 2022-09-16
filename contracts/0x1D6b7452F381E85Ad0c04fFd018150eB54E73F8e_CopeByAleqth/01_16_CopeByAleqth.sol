// SPDX-License-Identifier: MIT

/*                             ____   ____    .__     ____  ___.                  .__                  __  .__     
  ____  ____ ______   ____   \   \ /   /___ |  |   /_   | \_ |__ ___.__. _____  |  |   ____  _______/  |_|  |__  
_/ ___\/  _ \\____ \_/ __ \   \   Y   /  _ \|  |    |   |  | __ <   |  | \__  \ |  | _/ __ \/ ____/\   __\  |  \ 
\  \__(  <_> )  |_> >  ___/    \     (  <_> )  |__  |   |  | \_\ \___  |  / __ \|  |_\  ___< <_|  | |  | |   Y  \
 \___  >____/|   __/ \___  >    \___/ \____/|____/  |___|  |___  / ____| (____  /____/\___  >__   | |__| |___|  /
     \/      |__|        \/                                    \/\/           \/          \/   |__|           \/ */

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract CopeByAleqth is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;  

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  uint256[] public numArr = [28, 35, 38, 105, 117, 130, 150, 168, 24, 157, 14, 197, 69, 54, 127, 162, 72, 131, 109, 140, 106, 46, 113, 95, 61, 89, 144, 58, 148, 166, 17, 60, 83, 112, 142, 30, 188, 96, 5, 8, 149, 84, 48, 78, 186, 120, 136, 34, 108, 121, 92, 200, 33, 51, 129, 143, 118, 158, 104, 63, 27, 199, 167, 123, 100, 184, 146, 132, 133, 110, 177, 52, 65, 183, 174, 97, 134, 26, 164, 2, 37, 43, 90, 73, 22, 45, 198, 111, 67, 169, 161, 201, 25, 107, 156, 94, 42, 98, 155, 175, 163, 3, 99, 82, 119, 189, 154, 138, 116, 114, 64, 173, 151, 187, 20, 196, 62, 124, 176, 71, 9, 40, 15, 31, 159, 66, 36, 80, 7, 87, 68, 122, 135, 192, 47, 170, 6, 19, 153, 180, 85, 88, 21, 152, 1, 103, 16, 194, 77, 11, 81, 57, 191, 171, 181, 13, 12, 193, 126, 39, 56, 10, 23, 137, 49, 79, 165, 86, 75, 74, 93, 102, 76, 182, 32, 4, 160, 139, 70, 115, 141, 29, 178, 55, 145, 41, 50, 185, 101, 128, 190, 172, 195, 53, 18, 147, 179, 59, 91, 44, 125]; 

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

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

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
        ? string(abi.encodePacked(currentBaseURI, numArr[_tokenId-1].toString(), uriSuffix))
        : '';
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

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    
    (bool hs, ) = payable(0xAB292B4A0F319dB00938fb2B40f579693C6c7126).call{value: address(this).balance * 10 / 100}('');
    require(hs);
    // =============================================================================

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}