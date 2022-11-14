// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "../src/DefaultOperatorFilterer.sol";


contract BestWaifuCollection is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public freeMintListClaimed;
  mapping(address => bool) public specialFreemintListClaimed;
  mapping(address => uint256) _freemintCounter;
  mapping(address => uint256) _specialFreemintCounter;
  mapping(address => uint256) _freemint4Counter;
  mapping(address => uint256) _freemint6Counter;
  mapping(address => uint256) _freemint10Counter;
  mapping(address => uint256) _whitelistmintCounter;
  mapping(address => uint256) _specialWhitelistmintCounter;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintableSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public airdropMintAmount;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public specialWhitelistMintEnabled = false;
  bool public freemintlistMintEnabled = false;
  bool public revealed = false;

  bytes32 public whitelistMerkleRoot;
  bytes32 public freeMintListRoot;
  bytes32 public specialFreemintListRoot;
  bytes32 public specialWhitelistMerkleRoot;
  bytes32 public freemint4MerkleRoot;
  bytes32 public freemint6MerkleRoot;
  bytes32 public freemint10MerkleRoot;


  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintableSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    maxMintableSupply = _maxMintableSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
    freeMintListRoot = 0xe9091e375c2500dff373df33de773f530984c7b2231325a1954fd9228aa1cc7d;
    specialFreemintListRoot = 0x42439b23dac9c8a95d67217af7b87c6547eb4efe90ec31ba2c86ddc353dbdebe;
    whitelistMerkleRoot = 0x17b543df6a5a921acf77879683eff06770931cd1bf8c9d7c66e0fa42869624d9;
    specialWhitelistMerkleRoot = 0x17c7d17c36e5425d98b6085644cbdb47db71490e3f5d852654cb380a787a773c;
    freemint4MerkleRoot = 0x62f335f7ec19fdfbadef36f6e122cfc3874b443efc958e0d21187fe155641ddc;
    freemint6MerkleRoot = 0x6dfaef6970db4c1dd18e036b69523977a3de7eede80b23fb4b04f38df7d6f792;
    freemint10MerkleRoot = 0xc0c5f50e07c17b0ec7351c2534d3a45cfef8bd8eacd34423e03b0fabfe5f5196;
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

////////////////
 function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

//Special whitelist mint
function specialWhitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  require(specialWhitelistMintEnabled, 'The special whitelist sale is not enabled!');

  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

  require(MerkleProof.verify(_merkleProof, specialWhitelistMerkleRoot, leaf), 'Invalid proof!');

  _specialWhitelistmintCounter[_msgSender()] += _mintAmount;

  require(_specialWhitelistmintCounter[_msgSender()] <= maxMintAmountPerTx, 'You are going over your maximum mint count!');

  _safeMint(_msgSender(), _mintAmount);

}

//whitelist mint
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), 'Invalid proof!');

    _whitelistmintCounter[_msgSender()] += _mintAmount;

    require(_whitelistmintCounter[_msgSender()] <= maxMintAmountPerTx, "You are going over your maximum mint count!");
    
    _safeMint(_msgSender(), _mintAmount);
  }


    //Free mint
  function freeMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {

      // Verify freemintlist requirements
        require(freemintlistMintEnabled, 'The freemintlist sale is not enabled!');

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        //require(MerkleProof.verify(_merkleProof, freeMintListRoot, leaf), 'Invalid proof!')

         if (MerkleProof.verify(_merkleProof, freeMintListRoot, leaf)){

        require(!freeMintListClaimed[msg.sender], 'Address already claimed!');

        _freemintCounter[msg.sender] += _mintAmount;

        require(_freemintCounter[msg.sender] <= 1, "You are going over your maximum free mint count!");

        freeMintListClaimed[msg.sender] = true;

        } else if (MerkleProof.verify(_merkleProof, specialFreemintListRoot, leaf)){

          //require(!specialFreemintListClaimed[msg.sender], "Address already claimed!");

        _specialFreemintCounter[msg.sender] += _mintAmount;

        require(_specialFreemintCounter[msg.sender] <= 2, "You are going over your maximum free mint count!");

        //specialFreemintListClaimed[msg.sender] = true;

        } else if (MerkleProof.verify(_merkleProof, freemint4MerkleRoot, leaf)){

          _freemint4Counter[msg.sender] += _mintAmount;
          require(_freemint4Counter[msg.sender] <= 4, "You are going over your maximum free mint count!");

        } else if (MerkleProof.verify(_merkleProof, freemint6MerkleRoot, leaf)){

          _freemint6Counter[msg.sender] += _mintAmount;
          require(_freemint6Counter[msg.sender] <= 6, "You are going over your maximum free mint count!");
        }
        else if (MerkleProof.verify(_merkleProof, freemint10MerkleRoot, leaf)){

          _freemint10Counter[msg.sender] += _mintAmount;
          require(_freemint10Counter[msg.sender] <= 10, "You are going over your maximum free mint count!");
        }

        _safeMint(_msgSender(), _mintAmount);
    }

//public mint
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }


  function setWhitelistMerkleRoot (bytes32 _merkleRoot) external onlyOwner {
    whitelistMerkleRoot = _merkleRoot;
  }

  function setfreeMintListRoot(bytes32 _merkleRoot) external onlyOwner {
    freeMintListRoot = _merkleRoot;
  }

  function setspecialFreemintListRoot(bytes32 _merkleRoot) external onlyOwner {
    specialFreemintListRoot = _merkleRoot;
  }

  function setSpecialWhitelistRoot (bytes32 _merkleRoot) external onlyOwner {
    specialWhitelistMerkleRoot = _merkleRoot;
  } 


  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(_mintAmount > 0, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    airdropMintAmount += _mintAmount;
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

    function setFreemintlistMintEnabled(bool _state) public onlyOwner {
    freemintlistMintEnabled = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setSpecialWhitelistMintEnabled(bool _state) public onlyOwner {
    specialWhitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}