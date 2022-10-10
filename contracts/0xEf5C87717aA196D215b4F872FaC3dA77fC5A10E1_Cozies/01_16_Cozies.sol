// SPDX-License-Identifier: MIT
/*
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-                                                                                                                                                       -
-                                                                                                                                                       -
-                         -=010101010101010101010101:  .+0101010101010101010101010+.   .=01010101=   :+01010101010101010. .:=01010101010101010101010*   -
-                      :*01010101010101010101010101. .*0101010101010101010101010101.  *010101010:  +010101010101010101=  *0101010101010101010101010+    -
-                    .*01010101010101010101010101:  =01010101010101010101010101010=  -010101010=  -010101010101010101+ .01010101010101010101010101*     -
-                   =010101010101+                                  010101010101*.                                    +010101010+                       -
-                 :01010101010+  .=0101010101010101010101010101.  :010101010101:  :+01010101   :+0101010101010101-  -01010101010101010101010101         -
-               .010101010101.  +0101010101010101010101010101*.  *01010101010=  =010101010=  -010101010101010101. .01010101010101010101010101*          -
-              =01010101010-  =01010101010101010101010101010:  =01010101010*  :010101010*. :010101010101010101-  +0101010101010101010101010:            -
-            -01010101010=  :01010101010101010101010101010=  :010101010101: .*010101010:  *010101010=           01010101010101010101010101=             -
-          .010101010101. .*0101010101"      .0101010101*   *01010101010=  =010101010=  =01010101010101010*                  -01010101010*              -
-         +01010101010-  =01010101010101010101010101010:  =01010101010+  :010101010* .:010101010101010101-  +01010101010101010101010101:                -
-       -01010101010+  :01010101010101010101010101010-  :010101010101. .*010101010.  *01010101010101010+  -01010101010101010101010101=                  -
-     .010101010101. .*0101010101010101010101010101:  .*01010101010-  =010101010=  =01010101010101010+. .01010101010101010101010101*-                   -
-    -01010101010-                                   =01010101010*                                                                                      -
-   -010101010101010101010101010101010101010101*   :0101010101010101010101010101010101010101010101010101010101  +010+  +010+  +010+                     -
-   010101010101010101010101010101010101010101+  .0101010101010101010101010101010101010101010101010101010101=  0101+  0101+  0101+                      -
-   *0101010101010101010101010101010101010101.  -010101010101010101010101010101010101010101010101010101010=  =010+  =010+  =010+                        -
-    -0101010101010101010101010101010101010:    *0101010101010101010101010101010101010101010101010101010=  .0101  .0101  .0101                          -
-                                                                                                                                                       -
-                                                                                                                                        C O Z I E S    -
-                                                                                                                                                       -
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Cozies Whitepaper [https://cozies.gitbook.io/cozies/]

Cozies NFT Terms & Conditions [https://cozies.io/terms]

CantBeEvil NFT License (written by a16z) Non-Exclusive Commercial Rights with Creator Retention & Hate Speech Termination (“CBE-NECR-HS”) 

[https://7q7win2vvm2wnqvltzauqamrnuyhq3jn57yqad2nrgau4fe3l5ya.arweave.net/_D9kN1WrNWbCq55BSAGRbTB4bS3v8QAPTYmBThSbX3A/3]
*/

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Cozies is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public goldenlistClaimed;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public goldenlistMintEnabled = false;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

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

  function goldenlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(goldenlistMintEnabled, 'The golden list sale is not enabled!');
    require(!goldenlistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    goldenlistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
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
    return 0;
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

  function setGoldenlistMintEnabled(bool _state) public onlyOwner {
    goldenlistMintEnabled = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}