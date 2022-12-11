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
    freeMintListRoot = 0xa555a2072e1be42743bc3a08317b68e93d87cb1bc96e10bccadd184e41036920;
    specialFreemintListRoot = 0xb4f75c0b06b0832f04882793d81e5465b955aea3f9d1df2a685a59a30a257e2f;
    whitelistMerkleRoot = 0x70f9ec1d4659184eb8a9298693da1a84295907039abdc1091225b445caf13a46;
    specialWhitelistMerkleRoot = 0x3cd36ab4ce77e1c9f4fbd27457788a81f5bf91890085dfb0d6f5708e002ad64c;
    freemint4MerkleRoot = 0xbefcac7747a66449d8e6f39de303f0f692c0cfdb3dc89dbdef167dc6022eed67;
    freemint6MerkleRoot = 0xde6d7a1f4867366cddc0ada940b220c10d67cf76715e579e62102cd8082b8e52;
    freemint10MerkleRoot = 0x31bb1875b1ce77899b7fa33f0b951e9a523c8755336d652c40b0236c9208127a;
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

        if (
          MerkleProof.verify(_merkleProof, freeMintListRoot, leaf)
          || MerkleProof.verify(_merkleProof, specialFreemintListRoot, leaf)
          || MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf)
          || MerkleProof.verify(_merkleProof, specialWhitelistMerkleRoot, leaf)
          || MerkleProof.verify(_merkleProof, freemint4MerkleRoot, leaf)
          || MerkleProof.verify(_merkleProof, freemint6MerkleRoot, leaf)
          || MerkleProof.verify(_merkleProof, freemint10MerkleRoot, leaf)
        ){
          _safeMint(_msgSender(), _mintAmount);
        }
        else {
          revert("You cannot do this!");
        }
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