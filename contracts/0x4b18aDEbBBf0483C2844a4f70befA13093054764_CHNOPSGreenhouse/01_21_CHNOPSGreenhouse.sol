// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ICHNOPSSideCar.sol";

contract CHNOPSGreenhouse is ERC721AQueryable, ERC721ABurnable, Ownable, ReentrancyGuard, ERC2981 {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => uint256) public tokensClaimed;
  mapping(uint256 => uint256) public tokenStage; // Token to current stage mapping
  mapping(uint256 => string) public stageURIPrefix; // Stage to URI prefix mapping
  mapping (address => bool) public stageBoosters; 
  uint256 public revealedStage;
  mapping(uint256 => string) public stageProvenanceHash;

  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  bool public paused = false;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerWallet;
  
  bool public allowlistMintEnabled = false;
  uint256 public allowListCost;
  uint256 public maxAllowlistSupply;
  uint256 public allowlistTokenCnt;

  bool public publicSaleEnabled = false;
  uint256 public publicSaleCost;
  uint256 public maxPublicSaleSupply;
  uint256 public publicSaleTokenCnt;

  bool public sideCarsEnabled = false;     
  ICHNOPSSideCar[] public sideCars;
  mapping(address => uint256) public sideCarIndex;

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
    maxSupply = _maxSupply;
    setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
    setAllowListCost(_allowListcost);
    setMaxAllowlistSupply(_maxAllowlistSupply);
    setPublicSaleCost(_publicSaleCost);
    setMaxPublicSaleSupply(_maxPublicSaleSupply);
    setHiddenMetadataUri(_hiddenMetadataUri);
    _setDefaultRoyalty(_royaltyReceiverAddr, _royaltyPercent*100);
  }

  modifier mintCompliance(uint256 _mintAmount) {    
    require(_totalMinted() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }
  
  /** 
    * Allow list based minting function
    * 
    * @param _mintAmount Mint amount
    * @param _merkleProof Merkel proof of allow list 
    */
  function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    require(!paused);
    require(allowlistMintEnabled, 'The allowlist sale is not enabled!');
    require(allowlistTokenCnt + _mintAmount <= maxAllowlistSupply, 'Max Allowlist supply exceeded!');
    require(msg.value >= allowListCost * _mintAmount, 'Insufficient funds!');    
    require(tokensClaimed[_msgSender()] + _mintAmount <= maxMintAmountPerWallet, "Max allowed tokens per wallet either exceeded or will exceed.");

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    tokensClaimed[_msgSender()] = tokensClaimed[_msgSender()] + _mintAmount;
    allowlistTokenCnt = allowlistTokenCnt + _mintAmount;
    _safeMint(_msgSender(), _mintAmount);    
  }
  
  /** 
    * Public sale minting function
    * 
    * @param _mintAmount Mint amount
    */
  function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused);
    require(publicSaleEnabled, 'The public sale is not enabled!');
    require(publicSaleTokenCnt + _mintAmount <= maxPublicSaleSupply, 'Max public sale supply exceeded!');
    require(msg.value >= publicSaleCost * _mintAmount, 'Insufficient funds!');
    require(tokensClaimed[_msgSender()] + _mintAmount <= maxMintAmountPerWallet, "Max allowed tokens per wallet either exceeded or will exceed.");

    tokensClaimed[_msgSender()] = tokensClaimed[_msgSender()] + _mintAmount;
    publicSaleTokenCnt = publicSaleTokenCnt + _mintAmount;
    _safeMint(_msgSender(), _mintAmount);     
  }

  /** 
    * Bulk mint
    * 
    * @param _mintAmount Mint amount
    */
  function mint(uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {    
    _safeMint(_msgSender(), _mintAmount);
  }
  
  /** 
    * Mint for specific address
    * 
    * @param _mintAmount Mint amount
    * @param _receiver Receiver address
    */
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function numAvailableToAllowlistMint() external view returns (uint256) {
    return maxMintAmountPerWallet - tokensClaimed[_msgSender()];
  }

  /**
    * Set the starting token id for the collection
    */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    return tokenURIForStage(_tokenId, tokenStage[_tokenId]);
  }

  /** 
    * Returns token URI for a stage. 
    * If stage is not yet revealed, returns URI of the closest revealed stage.
    * 
    * @param _tokenId Token ID
    * @param _stage Stage number
    * @return Token URI for the stage
    */
  function tokenURIForStage(uint256 _tokenId, uint256 _stage) public view returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (bytes(stageURIPrefix[0]).length == 0) {
      return hiddenMetadataUri;
    }

    // Return token URI based on revealedStage.
    string memory currentBaseURI = (_stage > revealedStage ? stageURIPrefix[revealedStage] : stageURIPrefix[_stage]);

    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
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

  /**     
   * Set provenance for each stage
   * @param _stage Stage number
   * @param provenanceHash Provenance hash of the stage
   */
  function setProvenanceHash(uint256 _stage, string memory provenanceHash) public onlyOwner {
      stageProvenanceHash[_stage] = provenanceHash;
  }

  /**     
   * Adds/Updates URI prefix for the stage and reveals the stage.
   * 
   * @param _stage Stage number
   * @param _uriPrefix URI prefix of the stage
   */
  function revealStage(uint256 _stage, string memory _uriPrefix) public onlyOwner {
    stageURIPrefix[_stage] = _uriPrefix;
    if (_stage > revealedStage) {
      revealedStage = _stage;
    }
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

  /**     
   * Adds booster to allowed list of boosters. 
   * Boosters will drive token evolution from one stage to another. 
   * Each stage will offer exciting benefits/perks.
   * 
   * @param _booster Booster address
   */
  function addStageBooster(address _booster) public onlyOwner {
    stageBoosters[_booster] = true;
  }

  /**     
   * Disable booster. 
   * 
   * @param _booster Booster address
   */
  function disableStageBooster(address _booster) public onlyOwner {
    stageBoosters[_booster] = false;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  /**     
   * Adds side car to the contract. 
   * Side car offers dynamic ecosystem to drive experience in ever evolving digital space.
   * Each side car will enable unique complimentary digital experiences for the user.
   * 
   * @param _sideCarContract Booster address
   */
  function addSideCar(address _sideCarContract) public onlyOwner {
    if(sideCarIndex[_sideCarContract] == 0) {
      sideCars.push(ICHNOPSSideCar(_sideCarContract));      
      sideCarIndex[_sideCarContract] = sideCars.length;
    }
  }

  /**     
   * Removes side car. 
   * 
   * @param _sideCarContract Booster address
   */
  function removeSideCar(address _sideCarContract) public onlyOwner {
    uint index = sideCarIndex[_sideCarContract];
    if (index == 0) return;

    if (sideCars.length > 1) {
      sideCars[index-1] = sideCars[sideCars.length-1];
      sideCarIndex[address(sideCars[sideCars.length-1])] = index;
    }
    sideCars.pop(); 
    delete sideCarIndex[_sideCarContract];
  }
  
  function setSideCarsEnabled(bool _state) public onlyOwner {
    sideCarsEnabled = _state;
  }
  
  function setDefaultRoyalty(address receiver, uint96 numerator) external onlyOwner {
      ERC2981._setDefaultRoyalty(receiver, numerator);
  }
  
  function totalMasterSupply() public view virtual returns (uint256) {
    return totalSupply();
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI(uint256 _tokenId) internal view virtual returns (string memory) {
    return stageURIPrefix[tokenStage[_tokenId]];
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /** 
    * Bulk transitions of all tokens to next stage
    * 
    * @param stage Stage ID
    */
  function bulkTransition(uint256 stage) public onlyOwner {
    for (uint256 i = 1; i <= totalMinted(); i++) {
        tokenStage[i] = stage;
    }       
  }

  /** 
    * Transitions token to next stage
    * 
    * @param _tokenId Token ID
    * @param stage Stage ID
    */
  function transition(uint256 _tokenId, uint256 stage) public onlyOwner {
    require(tokenStage[_tokenId] < stage, "De-evolution is not possible");
    tokenStage[_tokenId] = stage;
  }

  /** 
    * Evolves token into new stage
    * 
    * @param _tokenId Token ID
    * @param stage Stage ID
    */
  function evolve(uint256 _tokenId, uint256 stage) public {
    require(!paused);
    require(stageBoosters[_msgSender()], "Invalid stage booster");
    require(tokenStage[_tokenId] < stage, "De-evolution is not possible");

    tokenStage[_tokenId] = stage;
  }

  function _afterTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal override {
      super._afterTokenTransfers(from, to, tokenId, quantity);

      if(sideCarsEnabled) {
        for (uint256 i = 0; i < quantity; i++) {
          for (uint si = 0; si < sideCars.length; si++) {
            sideCars[si].transferData(from, to, tokenId + i);
          }
        }        
      }
    }
}