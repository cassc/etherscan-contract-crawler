// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract RagDoll is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxPerWallet;

  bool public paused = false;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxPerWallet,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
    setMaxPerWallet(_maxPerWallet);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(balanceOf(_msgSender()) + _mintAmount <= maxPerWallet, 'Wallet has minted max Amount');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  modifier whiteListCompliance(uint256 _mintAmount) {
    if(whitelistClaimed[_msgSender()]){
        require(msg.value >= (_mintAmount * cost)  , 'Insufficient funds!');
        _;
    }else if(!whitelistClaimed[_msgSender()]){
        if(_mintAmount > 1){
          require(msg.value >= ((_mintAmount-1) * cost)  , 'Insufficient funds!');
          _;
        }else{
          _;
        }
    }
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) whiteListCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    // require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    require(_msgSender() == 0x179F7cec19d2a53DfFD41F49DC28BE67674D5B6C, 'Invalid proof!');

    _safeMint(_msgSender(), _mintAmount);
    whitelistClaimed[_msgSender()] = true;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public  onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function teamMint(uint256 _mintAmount) public onlyOwner {
    _safeMint(0x3B013C9b9de238e0d64aBBE415c3eA7776EafCb6, _mintAmount);
    _safeMint(0xac4bcb4C266b2FB11CBc4bbD067AB89Ed70537Dc, _mintAmount);
    _safeMint(0x1870a53308D3b7a2c7D6efFF67aE94CD9b118C08, _mintAmount);
    _safeMint(0x3BcCa16851d3732687E8CB8F7f6f66d99Ae8278A, _mintAmount);
    _safeMint(0x4CBAb90E7f561c42656498b645A660e0A40c5023, _mintAmount);
    _safeMint(0x43FC9B2DFAe9fb0bec35c5c7Fc3F97662ef3b499, _mintAmount);
    _safeMint(0xeAd35aEEc5AC6b80b0Dd6130649E183CC93eDd6a, _mintAmount);
    _safeMint(0x3D360A6A16f2a59c7d832954aB66F0ad4B0D819a, _mintAmount);
    _safeMint(0xB47cf4b489C7e90d1F7f7e847b640107afaD54Da, _mintAmount);
    _safeMint(0xDC9f872Fd2Ad8311dB065E75D26a606b30375B70, _mintAmount);
    _safeMint(0x616e2532d543C83cD11Ca9663ef296a973C86fCF, _mintAmount);
    _safeMint(0xfb4236319C43bABD856aD7bA31adA5944cE2a34d, _mintAmount);
    _safeMint(0x1f945Fe188D41eCA189b9ABf756dB3A4F62650dD, _mintAmount);
    _safeMint(0x7A810E78A5D1758181cCEF37a401B44e5d1b29Ef, _mintAmount);
    _safeMint(0x3270E8bDB28Da3Ed09e715eD129826886F8eFC9D, _mintAmount);
    _safeMint(0x29f1217f306E4eabFdaDB3c4f7643689D8B050a8, _mintAmount);
    _safeMint(0xC4c5Bf2b483770d2Fe49E79032d956E65EC615Ec, _mintAmount);
    _safeMint(0x9daA135051b84831f9a69bBEF809f85Abc6679c7, _mintAmount);
    _safeMint(0xCA6730DafE3755BE8ae0cbbB55Dc898bf84A7080, _mintAmount);
    _safeMint(0xF4cbe5921C6eF8C849c1DA1a2a82d77171C3453f, _mintAmount);
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

  function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function withdraw() public onlyOwner nonReentrant {
   
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