// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/example/DefaultOperatorFilterer721.sol";

contract Seromon is DefaultOperatorFilterer721, ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelist1Claimed;
  mapping(address => bool) public whitelist2Claimed;
  mapping(address => bool) public whitelist3Claimed;
  mapping(address => bool) public whitelist4Claimed;
  mapping(address => bool) public whitelist5Claimed;
  mapping(address => bool) public whitelist6Claimed;
  mapping(address => bool) public whitelist7Claimed;
  mapping(address => bool) public whitelist8Claimed;
  mapping(address => bool) public whitelist9Claimed;
  mapping(address => bool) public whitelist10Claimed;
  mapping(address => bool) public whitelist11Claimed;
  mapping(address => bool) public whitelist12Claimed;
  mapping(address => bool) public whitelist13Claimed;
  mapping(address => bool) public whitelist14Claimed;
  mapping(address => bool) public whitelist15Claimed;
  mapping(address => bool) public whitelist16Claimed;
  mapping(address => bool) public whitelist17Claimed;
  mapping(address => bool) public whitelist18Claimed;
  mapping(address => bool) public whitelist19Claimed;
  mapping(address => bool) public whitelist20Claimed;
  
  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public currentmaxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelist1MintEnabled = false;
  bool public whitelist2MintEnabled = false;
  bool public whitelist3MintEnabled = false;
  bool public whitelist4MintEnabled = false;
  bool public whitelist5MintEnabled = false;
  bool public whitelist6MintEnabled = false;
  bool public whitelist7MintEnabled = false;
  bool public whitelist8MintEnabled = false;
  bool public whitelist9MintEnabled = false;
  bool public whitelist10MintEnabled = false;
  bool public whitelist11MintEnabled = false;
  bool public whitelist12MintEnabled = false;
  bool public whitelist13MintEnabled = false;
  bool public whitelist14MintEnabled = false;
  bool public whitelist15MintEnabled = false;
  bool public whitelist16MintEnabled = false;
  bool public whitelist17MintEnabled = false;
  bool public whitelist18MintEnabled = false;
  bool public whitelist19MintEnabled = false;
  bool public whitelist20MintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _currentmaxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    currentmaxSupply=_currentmaxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }
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

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= currentmaxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelist1Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist1 requirements
  require(whitelist1MintEnabled, 'WL not enabled!');
  require(!whitelist1Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist1Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist2Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist2 requirements
  require(whitelist2MintEnabled, 'WL not enabled!');
  require(!whitelist2Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist2Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist3Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist3 requirements
  require(whitelist3MintEnabled, 'WL not enabled!');
  require(!whitelist3Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist3Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist4Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist4 requirements
  require(whitelist4MintEnabled, 'WL not enabled!');
  require(!whitelist4Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist4Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist5Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist5 requirements
  require(whitelist5MintEnabled, 'WL not enabled!');
  require(!whitelist5Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist5Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist6Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist6 requirements
  require(whitelist6MintEnabled, 'WL not enabled!');
  require(!whitelist6Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist6Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist7Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist7 requirements
  require(whitelist7MintEnabled, 'WL not enabled!');
  require(!whitelist7Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist7Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist8Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist8 requirements
  require(whitelist8MintEnabled, 'WL not enabled!');
  require(!whitelist8Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist8Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist9Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist9 requirements
  require(whitelist9MintEnabled, 'WL not enabled!');
  require(!whitelist9Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist9Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist10Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist10 requirements
  require(whitelist10MintEnabled, 'WL not enabled!');
  require(!whitelist10Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist10Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist11Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist11 requirements
  require(whitelist11MintEnabled, 'WL not enabled!');
  require(!whitelist11Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist11Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist12Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist12 requirements
  require(whitelist12MintEnabled, 'WL not enabled!');
  require(!whitelist12Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist12Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist13Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist13 requirements
  require(whitelist13MintEnabled, 'WL not enabled!');
  require(!whitelist13Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist13Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist14Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist14 requirements
  require(whitelist14MintEnabled, 'WL not enabled!');
  require(!whitelist14Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist14Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist15Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist15 requirements
  require(whitelist15MintEnabled, 'WL not enabled!');
  require(!whitelist15Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist15Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist16Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist16 requirements
  require(whitelist16MintEnabled, 'WL not enabled!');
  require(!whitelist16Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist16Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist17Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist17 requirements
  require(whitelist17MintEnabled, 'WL not enabled!');
  require(!whitelist17Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist17Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist18Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist18 requirements
  require(whitelist18MintEnabled, 'WL not enabled!');
  require(!whitelist18Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist18Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist19Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist19 requirements
  require(whitelist19MintEnabled, 'WL not enabled!');
  require(!whitelist19Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist18Claimed[_msgSender()] = true;
  _safeMint(_msgSender(), _mintAmount);
  }
  function whitelist20Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify whitelist20 requirements
  require(whitelist20MintEnabled, 'WL not enabled!');
  require(!whitelist20Claimed[_msgSender()], 'Already Claimed!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  whitelist20Claimed[_msgSender()] = true;
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
    require(_exists(_tokenId), 'nonexistent token');

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

  function setWhitelist1MintEnabled(bool _state) public onlyOwner {
    whitelist1MintEnabled = _state;
  }
  function setWhitelist2MintEnabled(bool _state) public onlyOwner {
    whitelist2MintEnabled = _state;
  }
  function setWhitelist3MintEnabled(bool _state) public onlyOwner {
   whitelist3MintEnabled = _state;
   }
  function setWhitelist4MintEnabled(bool _state) public onlyOwner {
  whitelist4MintEnabled = _state;
  }
  function setWhitelist5MintEnabled(bool _state) public onlyOwner {
  whitelist5MintEnabled = _state;
  }
  function setWhitelist6MintEnabled(bool _state) public onlyOwner {
  whitelist6MintEnabled = _state;
  }
  function setWhitelist7MintEnabled(bool _state) public onlyOwner {
  whitelist7MintEnabled = _state;
  }
  function setWhitelist8MintEnabled(bool _state) public onlyOwner { 
  whitelist8MintEnabled = _state;
  }
  function setWhitelist9MintEnabled(bool _state) public onlyOwner { 
  whitelist9MintEnabled = _state;
  }
  function setWhitelist10MintEnabled(bool _state) public onlyOwner {
  whitelist10MintEnabled = _state;
  }
  function setWhitelist11MintEnabled(bool _state) public onlyOwner {
  whitelist11MintEnabled = _state;
  }
  function setWhitelist12MintEnabled(bool _state) public onlyOwner {
  whitelist12MintEnabled = _state;
  }
  function setWhitelist13MintEnabled(bool _state) public onlyOwner {
  whitelist13MintEnabled = _state;
  }
  function setWhitelist14MintEnabled(bool _state) public onlyOwner {
  whitelist14MintEnabled = _state;
  }
  function setWhitelist15MintEnabled(bool _state) public onlyOwner {
  whitelist15MintEnabled = _state;
  }
  function setWhitelist16MintEnabled(bool _state) public onlyOwner {
  whitelist16MintEnabled = _state;
  }
  function setWhitelist17MintEnabled(bool _state) public onlyOwner {
  whitelist17MintEnabled = _state;
  }
  function setWhitelist18MintEnabled(bool _state) public onlyOwner {
  whitelist18MintEnabled = _state;
  }
  function setWhitelist19MintEnabled(bool _state) public onlyOwner {
  whitelist19MintEnabled = _state;
  }
  function setWhitelist20MintEnabled(bool _state) public onlyOwner {
  whitelist20MintEnabled = _state;
  }
  
  

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
  function setCurrentMaxSupply(uint256 _supply) public onlyOwner {
    require(_supply <= maxSupply && _supply >= totalSupply());
    currentmaxSupply = _supply;
  }
  function resetmaxSupply() public onlyOwner {
      maxSupply = currentmaxSupply;

  }
  
address public constant SeromonMain = 0x51d947Bd36633eB971C7b4e9eD7fe8215b965Eb0;
address public constant SeromonStandard = 0x5A2c128A1036bD65da175673577180d1Cd5Bc70F;
address public constant CommunityReturn = 0x715C7835d25D6F963b0d420d9A37Ef2511a38075;
address public constant Donation = 0x9D6C07d8f031badb16eA955A55F3f75C9c2749B0;

function withdrawAll() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);
    _withdraw(SeromonMain, balance*59/100);
    _withdraw(SeromonStandard, balance*30/100);
    _withdraw(CommunityReturn, balance*10/100);
    _withdraw(Donation, address(this).balance);
}

function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
}
}