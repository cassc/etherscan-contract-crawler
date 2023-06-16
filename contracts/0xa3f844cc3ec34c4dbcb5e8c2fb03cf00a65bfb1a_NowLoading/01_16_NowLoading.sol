/*





  __    ____         _  _      ___    ___        _      ____    ____      ___   
 / J   / _  `.      FJ  L]    F _ ", F __".     /.\    /_  _\  F ___J    F __". 
 L J  J_/-7 .'     J |  | L  J `-' |J |--\ L   //_\\   [J  L] J |___:   J (___| 
 J  L `-:'.'.'     | |  | |  |  __/F| |  J |  / ___ \   |  |  | _____|  J\___ \ 
 J  L .' ;_J__     F L__J J  F |__/ F L__J | / L___J \  F  J  F L____: .--___) \
 J__LJ________L   J\______/FJ__|   J______/FJ__L   J__LJ____LJ________LJ\______J
 |__||________|_   J______F |__L   |______F |__L_  J__||____||________| J______F
   / _  `. FJ  L]       FJ  L]    F __ ]    FJ  L]    F _ ",    F __".          
  J_/-7 .'J |__| L     J |__| L  J |--| L  J |  | L  J `-'(|   J (___|          
  `-:'.'.'|____  |     |  __  |  | |  | |  | |  | |  |  _  L   J\___ \          
  .' ;_J__L____J J     F L__J J  F L__J J  F L__J J  F |_\  L .--___) \         
 J________L    J__L   J__L  J__LJ\______/FJ\______/FJ__| \\__LJ\______J         
 |________|    J__|   |__L  J__| J______F  J______F |__|  J__| J______F  


 A Pixel Perfection Project by Kim Deitlof. Launch Midnight 6/12/2023.














*/                                                                                
                                                      



// SPDX-License-Identifier: MIT 


pragma solidity >=0.8.9 <0.9.0;
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
contract NowLoading is ERC721AQueryable, Ownable, ReentrancyGuard {
  using Strings for uint256;
  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  string public MAX_TOTAL_DORM_SUPPLY = '876';
  string public CURRENT_REVEAL_PHASE = '0';
  string public uriPrefix = '';
  string public uriSuffix = '.json';

  string public hiddenMetadataUri;
  string private Update_Schedule = '';

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
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
  
  function reserve(uint256 _mintAmount, address _receiver) public onlyOwner {
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