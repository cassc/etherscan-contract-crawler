// SPDX-License-Identifier: MIT
// Features: Public sale (Max allowed public sale mints, public sale price, public sale enablement flag)

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract NFTTester is ERC721AQueryable, ERC721ABurnable, Ownable, ReentrancyGuard, ERC2981 {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => uint256) public tokensClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public allowListCost;
  uint256 public publicSaleCost;
  uint256 public maxSupply;
  uint256 public maxAllowlistSupply;
  uint256 public maxPublicSaleSupply;
  uint256 public allowlistTokenCnt;
  uint256 public publicSaleTokenCnt;
  uint256 public maxMintAmountPerWallet;

  bool public allowlistMintEnabled = false;
  bool public publicSaleEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _allowListcost,
    uint256 _publicSaleCost,    
    uint256 _maxSupply,
    uint256 _maxAllowlistSupply,
    uint256 _maxPublicSaleSupply,
    uint256 _maxMintAmountPerWallet,
    string memory _hiddenMetadataUri,
    address _royaltyReceiverAddr,
    uint96 _royaltyPercent
  ) ERC721A(_tokenName, _tokenSymbol) {
    setAllowListCost(_allowListcost);
    setPublicSaleCost(_publicSaleCost);
    maxSupply = _maxSupply;
    setMaxAllowlistSupply(_maxAllowlistSupply);
    setMaxPublicSaleSupply(_maxPublicSaleSupply);
    setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
    setHiddenMetadataUri(_hiddenMetadataUri);
    _setDefaultRoyalty(_royaltyReceiverAddr, _royaltyPercent*100);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    // require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(_totalMinted() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintAllowlistCompliance(uint256 _mintAmount) {
    require(allowlistTokenCnt + _mintAmount <= maxAllowlistSupply, 'Max Allowlist supply exceeded!');
    _;
  }

  modifier mintPublicSaleCompliance(uint256 _mintAmount) {
    require(publicSaleTokenCnt + _mintAmount <= maxPublicSaleSupply, 'Max public sale supply exceeded!');
    _;
  }
  
  function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintAllowlistCompliance(_mintAmount) {
    // Verify allowlist requirements
    require(allowlistMintEnabled, 'The allowlist sale is not enabled!');
    require(msg.value >= allowListCost * _mintAmount, 'Insufficient funds!');    
    require(tokensClaimed[_msgSender()] + _mintAmount <= maxMintAmountPerWallet, "Max allowed tokens per wallet either exceeded or will exceed.");

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    tokensClaimed[_msgSender()] = tokensClaimed[_msgSender()] + _mintAmount;
    allowlistTokenCnt = allowlistTokenCnt + _mintAmount;
    _safeMint(_msgSender(), _mintAmount);    
  }
  
  function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPublicSaleCompliance(_mintAmount) {
      require(publicSaleEnabled, 'The public sale is not enabled!');
      require(msg.value >= publicSaleCost * _mintAmount, 'Insufficient funds!');
      require(tokensClaimed[_msgSender()] + _mintAmount <= maxMintAmountPerWallet, "Max allowed tokens per wallet either exceeded or will exceed.");

      tokensClaimed[_msgSender()] = tokensClaimed[_msgSender()] + _mintAmount;
      publicSaleTokenCnt = publicSaleTokenCnt + _mintAmount;
      _safeMint(_msgSender(), _mintAmount);      
  }

  function numAvailableToAllowlistMint() external view returns (uint256) {
    return maxMintAmountPerWallet - tokensClaimed[_msgSender()];
  }

  function mint(uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
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

  function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

  /**
  @notice Sets the default ERC2981 royalty values.
  */
  function setDefaultRoyalty(address receiver, uint96 numerator) external onlyOwner
  {
      ERC2981._setDefaultRoyalty(receiver, numerator);
  }
  
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setAllowListCost(uint256 _cost) public onlyOwner {
    allowListCost = _cost;
  }

  function setPublicSaleCost(uint256 _cost) public onlyOwner {
    publicSaleCost = _cost;
  }

  function setMaxAllowlistSupply(uint256 _maxAllowlistSupply) public onlyOwner {
    maxAllowlistSupply = _maxAllowlistSupply;
  }

  function setMaxPublicSaleSupply(uint256 _maxPublicSaleSupply) public onlyOwner {
    maxPublicSaleSupply = _maxPublicSaleSupply;
  }

  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
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

  function setAllowlistMintEnabled(bool _state) public onlyOwner {
    allowlistMintEnabled = _state;
  }

  function setPublicSaleEnabled(bool _state) public onlyOwner {
    publicSaleEnabled = _state;
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