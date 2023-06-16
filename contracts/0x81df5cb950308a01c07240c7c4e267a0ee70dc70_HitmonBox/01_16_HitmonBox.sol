// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract HitmonBox is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;

  string public uriPrefix = "ipfs://QmSd2Ytt9YnCxZR4384HKXdseKMsRaWnmBBcFLeAZWnmsh/";
  string public uriSuffix = ".json";
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = false;

  uint256 public startTime;
  bool public timerActive;
  uint256 public constant TIMER_DURATION = 24 hours;
  IERC20 usdcToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

 

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint256 allowance = usdcToken.allowance(msg.sender, address(this));
    require(allowance >= cost * _mintAmount, "USDT allowance not granted");
    // Transfer USDC to the contract as payment for the NFT minting
    require(usdcToken.transferFrom(msg.sender, address(this), cost * _mintAmount), "USDT transfer failed");

    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    if(!timerExpired()){
        require(IERC721(0xba72b008D53D3E65f6641e1D63376Be2F9C1aD05).balanceOf(msg.sender) >= 1,"Not a Holder :( wait for Public Mint");
    }
     _safeMint(_msgSender(), _mintAmount);
   
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function startTimer() public {
        require(!timerActive, "Timer is already active");
        startTime = block.timestamp;
        timerActive = true;
    }
    
    function stopTimer() public {
        require(timerActive, "Timer is not active");
        timerActive = false;
    }
    
    function timerExpired() public view returns (bool) {
        return timerActive && block.timestamp >= startTime + TIMER_DURATION;
    }

  function withdraw() public onlyOwner nonReentrant {
    usdcToken.transfer(msg.sender,usdcToken.balanceOf(address(this)));
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}