// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './DefaultOperatorFilterer.sol';


contract BoBlurFarmer is ERC721A, Ownable, DefaultOperatorFilterer, ReentrancyGuard {
  using Strings for uint256;

  string public tokenName = "BoBlur Farmer";
  string public tokenSymbol = "BOBLUR";
  uint256 public maxSupply = 5000;
  uint256 public maxReservedSupply = 0;

  uint256 public maxMintAddress = 5;
  uint256 public maxWLMintAddress = 1;
  bytes32 public merkleRoot;
  mapping(address => bool) public mintClaimed; 

  bool public paused = false;
  bool public whitelistMintEnabled = true;
  bool public revealed = false;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri = "";

  uint256 public wlEthCost = 0.002 ether;
  uint256 public wlBlurCost = 1 ether;
  uint256 public ethCost = 0.005 ether;
  uint256 public blurCost = 3 ether;

  ERC20 public MyToken;

  constructor(address token) ERC721A(tokenName, tokenSymbol) {
    MyToken = ERC20(token);
  }

  function mintWithBlur(uint256 _mintAmount, bytes32[] calldata _merkleProof) public {
		if (whitelistMintEnabled == true){
			bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
      require(_mintAmount > 0 && _mintAmount <= maxWLMintAddress, 'Invalid mint amount!');
    }
		
    require(!paused, 'The contract is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAddress, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= (maxSupply - maxReservedSupply), 'Max supply exceeded!');
    require(!mintClaimed[_msgSender()], 'Address already claimed!');
    require(MyToken.allowance(msg.sender, address(this)) >= updateMintBlurCost(_mintAmount), "Not enough of ERC20 token");//To ensure they will deposit the right amount
    
    MyToken.transferFrom(msg.sender, owner(), updateMintBlurCost(_mintAmount));

    mintClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= updateMintCost(_mintAmount), 'Insufficient funds!');
    _;
  }

   function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintPriceCompliance(_mintAmount) {
		if (whitelistMintEnabled == true){
			bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
      require(_mintAmount > 0 && _mintAmount <= maxWLMintAddress, 'Invalid mint amount!');
    }
		
		require(!paused, 'The contract is paused!');
		require(_mintAmount > 0 && _mintAmount <= maxMintAddress, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= (maxSupply - maxReservedSupply), 'Max supply exceeded!');
		require(!mintClaimed[_msgSender()], 'Address already claimed!');

    mintClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function teamMint(uint256 _mintAmount, address _receiver) public onlyOwner {
	require((totalSupply() + _mintAmount) <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
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

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setToken(address token) public onlyOwner {
    MyToken = ERC20(token);
  }

  function setWLBlurCost(uint256 _cost) public onlyOwner {
    wlBlurCost = _cost;
  }

  function setWLEthCost(uint256 _wlCost) public onlyOwner {
    wlEthCost = _wlCost;
  }

  function setBlurCost(uint256 _cost) public onlyOwner {
    blurCost = _cost;
  }

  function setEthCost(uint256 _wlCost) public onlyOwner {
    ethCost = _wlCost;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxReservedSupply(uint256 _newMaxReservedSupply) public onlyOwner {
    require(_newMaxReservedSupply <= (maxSupply - totalSupply()));
    maxReservedSupply = _newMaxReservedSupply;
  }

  function setmaxMintAddress(uint256 _maxMintAddress) public onlyOwner {
    maxMintAddress = _maxMintAddress;
  }

  function setMaxWLMintAddress(uint256 _maxMintAddress) public onlyOwner {
    maxWLMintAddress = _maxMintAddress;
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

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

	// A function of hope -> 
  function withdraw() public onlyOwner nonReentrant {
   (bool os, ) = payable(owner()).call{value: address(this).balance}('');
   require(os);
  }

  // Internal ->
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function updateMintCost(uint256 _amount) internal view returns (uint256 _cost) {
    if (whitelistMintEnabled) {
      return wlEthCost * (_amount -1);
    }

    return ethCost * _amount;
    
  }

   function updateMintBlurCost(uint256 _amount) internal view returns (uint256 _cost) {
    if (whitelistMintEnabled) {
      return wlBlurCost * _amount;
    }

    return blurCost * _amount;
    
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

 function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override
    payable
     onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        payable
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}