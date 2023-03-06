// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract MysteryOfTheKeysNFT is ERC721A, ERC2981, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public presaleClaimed;
  mapping(address => uint256) public mintCounter;
  mapping (address => bool) private _mintedFree;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public price = 0.0029 ether; 
  
  uint256 public freeMinted = 0;
  uint256 public maxFreePerWallet = 1;	
  uint256 public totalFree = 2000;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerW; 
  

  bool public paused = false;
  bool public publicM = true;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxMintAmountPerW,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    _setDefaultRoyalty(0xb1435616439458c8012A7cc29e66E39eAF9587Ae, 500); 
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setMaxMintAmountPerW(_maxMintAmountPerW);
    setHiddenMetadataUri(_hiddenMetadataUri);
}

/**
 * @dev See {IERC165-supportsInterface}.
 */
function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
}
function setDefaultRoyalty(
  address _receiver, 
  uint96 _feeNumerator
  ) external onlyOwner {
    super._setDefaultRoyalty(_receiver, _feeNumerator);
}

  
function deleteDefaultRoyalty() external onlyOwner {
    super._deleteDefaultRoyalty();
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
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');
    _;
}


modifier onlyAccounts () {
    require(msg.sender == tx.origin, "Not allowed origin");
    _;   
}

function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount)  {
    require(!paused, 'The contract is paused!');
    require(publicM, "PublicSale is OFF");
    require(totalSupply() + _mintAmount <= maxSupply, "reached Max Supply");
      bool isFreeLeft = !(_mintedFree[msg.sender]) &&
            (freeMinted < totalFree);
        bool isEqual = _mintAmount == maxFreePerWallet;

        uint256 cost = price;

        if (isFreeLeft && isEqual) {
            cost = 0;
        }

        if (isFreeLeft && !isEqual) {
            require(
                msg.value >= (_mintAmount - maxFreePerWallet) * cost,
                "Please send the exact amount."
            );
        } else {
            require(msg.value >= _mintAmount * cost, "Please send the exact amount.");
        }
        require(
            _numberMinted(msg.sender) + _mintAmount <= maxMintAmountPerW,
            "Can not mint more than 10"
        );

        _mintedFree[msg.sender] = true;

        if (isFreeLeft) {
            freeMinted++;
        }

        _safeMint(msg.sender, _mintAmount);
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

function setprice(uint256 _price) public onlyOwner {
    price = _price;
}


function setmaxFreePerWallet(uint256 _maxFreePerWallet) public onlyOwner {
    maxFreePerWallet = _maxFreePerWallet;
}

function settotalFree(uint256 _totalFree) public onlyOwner {
    totalFree = _totalFree;
}

function setmaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
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

function _mintedAmount(address minter) external view returns (uint256) {
    return _numberMinted(minter);
}

function togglePause() public onlyOwner {
    paused = !paused;
}

function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
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