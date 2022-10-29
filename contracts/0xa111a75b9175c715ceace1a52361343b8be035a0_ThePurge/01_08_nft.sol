// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';


contract ThePurge is ERC721A, Ownable, ReentrancyGuard {

   using Strings for uint256;

  bytes32 public merkleRootwl;
  bytes32 public merkleRootog;
  mapping(address => bool) public presaleClaimed;
  mapping(address => uint256) public mintCounter;
  mapping (address => uint256) public WalletMint;  

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.0099 ether; 
  uint public freeMint = 1;
  uint256 public maxSupply;
  uint256 public freeSupply = 1556;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerW; 
  

  bool public paused = false;
  bool public presaleM = true;
  bool public publicM = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxMintAmountPerW,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setMaxMintAmountPerW(_maxMintAmountPerW);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }


modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(
        mintCounter[_msgSender()] + _mintAmount <= maxMintAmountPerW,
        "exceeds max per address"
        );
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    mintCounter[_msgSender()] = mintCounter[_msgSender()] + _mintAmount;
    _;
}


modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
}

modifier isValidMerkleProofwl(bytes32[] calldata _proofwl) {
    require(MerkleProof.verify(
    _proofwl,
    merkleRootwl,
    keccak256(abi.encodePacked(msg.sender))
    ) == true, "Not allowed origin");
    _;
}


modifier onlyAccounts () {
    require(msg.sender == tx.origin, "Not allowed origin");
    _;   
}


function presaleMint(address account,uint256 _mintAmount, bytes32[] calldata _proofwl) public payable mintCompliance(_mintAmount) 
    isValidMerkleProofwl(_proofwl) 
    onlyAccounts {
    // Verify presale requirements
    require(presaleM, 'The presale sale is not enabled!');
    require(!presaleClaimed[_msgSender()], 'Address already claimed!');
    require(msg.sender == account, "Not allowed");
    if(WalletMint[_msgSender()] < freeMint) 
        {
            if(_mintAmount < freeMint) _mintAmount = freeMint;
           require(msg.value >= (_mintAmount - freeMint) * cost,"Notice:Claim Free NFT");
            WalletMint[_msgSender()] += _mintAmount;
           _safeMint(_msgSender(), _mintAmount);
        }
        else
        {
           require(msg.value >= _mintAmount * cost,"Notice:Fund not enough");
            WalletMint[_msgSender()] += _mintAmount;
         _safeMint(_msgSender(), _mintAmount);
    }
}

function publicSaleMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount)  {
    require(!paused, 'The contract is paused!');
    require(publicM, "PublicSale is OFF");
      require(totalSupply() + _mintAmount <= maxSupply, "reached Max Supply");
      _safeMint(_msgSender(), _mintAmount);
}
  
function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "reached Max Supply");
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

function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
}

function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
}
function setMaxMintAmountPerW(uint256 _maxMintAmountPerW) public onlyOwner {
      maxMintAmountPerW = _maxMintAmountPerW;
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

function togglePause() public onlyOwner {
    paused = !paused;
}

function setMerkleRoot(bytes32 _merkleRootwl) public onlyOwner {
    merkleRootwl = _merkleRootwl;
}

function togglePresale() public onlyOwner {
    presaleM = !presaleM;
}


function togglePublicSale() public onlyOwner {
    publicM = !publicM;
}

function withdraw() public onlyOwner nonReentrant {
   
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
}

function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
}
}