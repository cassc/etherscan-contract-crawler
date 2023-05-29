// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

interface IParent {
    
    function ownerOf(uint256 tokenId) external view returns (address);
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);

}
contract SuperDudes is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public parentClaims;
  uint256 public noPaidNfts = 4000;


  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;


  mapping(address => uint256) public tokenBalance;
  mapping(uint256 => bool) public tokenIds;


    //v2 address change this to nft adress needed to hold for claim
  address public v2Address = 0xE24e4d4535F504D6D7957356534E23b4e787289F;

  IParent public v2;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
    v2= IParent(v2Address);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintCompliancePaid(uint256 _mintAmount){
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= noPaidNfts, 'Max paid supply exceeded!');
    _; 
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliancePaid(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliancePaid(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }

  function claimFromParentNFT(uint256 _numberOfTokens) external payable {
    uint256 currentSupply = totalSupply();
    uint256 balanceAddr = v2.balanceOf(msg.sender);
    uint256 balanceToken = tokenBalance[msg.sender];
    require(!paused, "Contract is paused");
    require(currentSupply >= noPaidNfts, "user cannot claim");
    require(_numberOfTokens > 0, "cannot mint zero");
    require(balanceToken + _numberOfTokens <= balanceAddr, "max limit reached");
    require(currentSupply + _numberOfTokens <= maxSupply, "Purchase would exceed max supply");
    

    uint256[] memory tempTokenids = v2.walletOfOwner(msg.sender);

    for (uint256 i = balanceToken; i < (balanceToken + _numberOfTokens); i++) {
        if(tokenIds[tempTokenids[i]] == true){
            continue;
        }

        tokenBalance[msg.sender]+=1;
        parentClaims+=1;
        tokenIds[tempTokenids[i]] = true;
        _safeMint(msg.sender, 1);
    }
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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

  function setNoPaidNFT(uint256 _newAmount) public onlyOwner {
    noPaidNfts = _newAmount;
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

  function setV2Contract(address _newV2Contract) external onlyOwner {
    v2Address = _newV2Contract;
  }

  function withdraw() public onlyOwner nonReentrant {
    // This will pay Operations and various Branches of team.
    // 
    // 
    // =============================================================================

    (bool ds, ) = payable(0xbC5810603F74F407662888fDF275dfe75E3CF213).call{value: address(this).balance * 96 / 100}('');
    require(ds);

    
    // =============================================================================


    // This will transfer the remaining contract balance to the owner, which is 4%.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(0x6a80Ee76D9cba41a1Cc24A2fA39fed0b1e37AD99).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}