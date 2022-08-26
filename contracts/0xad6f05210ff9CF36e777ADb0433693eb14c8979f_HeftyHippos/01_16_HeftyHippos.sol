// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

//  __  __             ___  __                __  __                                        
// /\ \/\ \          /'___\/\ \__            /\ \/\ \  __                                   
// \ \ \_\ \     __ /\ \__/\ \ ,_\  __  __   \ \ \_\ \/\_\  _____   _____     ___     ____  
//  \ \  _  \  /'__`\ \ ,__\\ \ \/ /\ \/\ \   \ \  _  \/\ \/\ '__`\/\ '__`\  / __`\  /',__\ 
//   \ \ \ \ \/\  __/\ \ \_/ \ \ \_\ \ \_\ \   \ \ \ \ \ \ \ \ \L\ \ \ \L\ \/\ \L\ \/\__, `\
//    \ \_\ \_\ \____\\ \_\   \ \__\\/`____ \   \ \_\ \_\ \_\ \ ,__/\ \ ,__/\ \____/\/\____/
//     \/_/\/_/\/____/ \/_/    \/__/ `/___/> \   \/_/\/_/\/_/\ \ \/  \ \ \/  \/___/  \/___/ 
//                                      /\___/                \ \_\   \ \_\                 
//                                      \/__/                  \/_/    \/_/                 

contract HeftyHippos is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public oglistClaimed;
  mapping(address => bool) public presalelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public reserveSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public burnPaused = true;
  bool public oglistMintEnabled = false;
  bool public whitelistMintEnabled = false;
  bool public presalelistMintEnabled = false;
  bool public revealed = false;

  constructor( 
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _reserveSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    reserveSupply = _reserveSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require((_getAux(msg.sender) + _mintAmount) <= maxMintAmountPerTx, '');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require( msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function mintOGList(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify oglist requirements
    require(oglistMintEnabled, 'The OGlist sale is not enabled!');
    require(!oglistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    oglistClaimed[_msgSender()] = true;
    
    uint256 _toMint = _mintAmount;
    //Mint 3 get 1 free
    if (_mintAmount > 2) {
      _toMint = _toMint + 1;
    }
    _safeMint(_msgSender(), _toMint);
  }

  function mintWhiteList(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintPresaleList(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify presale list requirements
    require(presalelistMintEnabled, 'The Presale is not enabled!');
    require(!presalelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    presalelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
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

  function setOGlistMintEnabled(bool _state) public onlyOwner {
    oglistMintEnabled = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

function setpresalelistMintEnabled(bool _state) public onlyOwner {
    presalelistMintEnabled = _state;
  }

  function setReserveSupply(uint256 _newReserveSupply) external onlyOwner {
    require(_newReserveSupply < maxSupply - totalSupply(), 'New reserve value too high.');

    reserveSupply = _newReserveSupply;
  }

  function airdrop(address[] calldata _address) external onlyOwner {
      require(reserveSupply > 0, 'No reserve supply left.');
      require(_address.length < reserveSupply, 'Number of addresses supplied exceeds reserve supply.');
      require(_address.length > 0, 'No addresse(s) supplied.');
      require(totalSupply() + _address.length <= maxSupply, 'Supply exceeded');
      
      for (uint256 i = 0; i != _address.length; i++) {
          _safeMint(_address[i], 1);
      }
      reserveSupply = reserveSupply - _address.length;
  }

  function airdropMultipleToAddress(address _address, uint256 _mintAmount) external onlyOwner {
      require(reserveSupply > 0, 'No reserve supply left.');
      require(_mintAmount < reserveSupply, 'Total airdrops exceeds reserve supply.');
      require(_mintAmount > 0, 'Number of mints to airdrop not specified.');
      require(totalSupply() + _mintAmount <= maxSupply, 'Supply exceeded.');

      _safeMint(_address, _mintAmount);

      reserveSupply = reserveSupply - _mintAmount;
  }

  function withdraw() public onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    require(balance > 0, 'No balance to withdraw.');

    // This will pay Dev
    // =============================================================================
    (bool garet, ) = payable(0xD6db847A7B5fA8C1730D80DE6E15eA75CB2F481D).call{value: (balance / 100) * 20}('');
    require(garet);
    // This will pay Founder.
    // =============================================================================
    (bool far, ) = payable(0xC4AA8526F2571C7B20C7aa1625Ffb47C7bDF08d4).call{value: (balance / 100) * 20}('');
    require (far);
    // This will transfer the remaining contract balance to the secure project wallet.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    //(bool project, ) = payable(owner()).call{value: address(this).balance}('');
    (bool project, ) = payable(0xf2184E5E7902A2FC7B323d70d34537A58d415b3d).call{value: address(this).balance}('');
    require(project);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}