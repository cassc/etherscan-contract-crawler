// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


interface ERC20Burnable is IERC20 {
  function burn(address account, uint256 amount) external;
}

contract CoinMarketCat is DefaultOperatorFilterer, ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;


  address public proxyRegistryAddress;
  address public treasury;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => uint256) public mintedAmount;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  uint256 public phase = 0; // 0: sale not started, 1: company reserve, 2: whitelist, 3: recess, 4: public sale, 5: finished
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public phaseSupply;
  uint256 public maxMintAmountPerWallet;
  uint256 public treasuryRatio;
  
  bool public revealed = false;

  ERC20Burnable public Tears;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerWallet,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    phaseSupply = 10000;
    setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
    setHiddenMetadataUri(_hiddenMetadataUri);
    treasuryRatio = 80;
    treasury = 0x0063E959968E974134d44d77F150c5648bdd7b8f;
  }

  function decimals() public view virtual returns (uint8) {
    return 0;
  }

  modifier mintCompliance(address _receiver, uint256 _mintAmount) {
    require(_mintAmount > 0 && mintedAmount[_receiver] + _mintAmount <= maxMintAmountPerWallet, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(totalSupply() + _mintAmount <= phaseSupply, "Phase supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  function reserveForCompany(uint256 _mintAmount) public onlyOwner {
    _safeMint(_msgSender(), _mintAmount);
  }

  function _singleMint(address _receiver) internal {
    require(mintedAmount[_receiver] < maxMintAmountPerWallet, "Minting limit exceeded!");
    _safeMint(_receiver, 1);
    mintedAmount[_receiver] += 1;
    if (totalSupply() == maxSupply) {
      phase = 5;
    } else if (totalSupply() == phaseSupply) {
      phase = 3;
    }
  }

  function _multipleMint(address _receiver, uint256 _mintAmount) internal {
    for (uint i = 0; i < _mintAmount; i++) {
      _safeMint(_receiver, 1);
    }
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_msgSender(), _mintAmount) mintPriceCompliance(_mintAmount) {
    require(phase == 2, "Whitelist minting is not enabled.");
    require(!whitelistClaimed[_msgSender()], "Current address has already claimed whitelist minting.");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[_msgSender()] = true;
    _singleMint(_msgSender());
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_msgSender(), _mintAmount) mintPriceCompliance(_mintAmount) {
    require(phase == 4, "Public minting is not enabled.");
    for (uint i = 0; i < _mintAmount; i++) {
      _singleMint(_msgSender());
    }
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_msgSender(), _mintAmount) onlyOwner {
    _multipleMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownershipOf(currentTokenId);

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
    require(_exists(_tokenId), "nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
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

  function setPhase(uint _phase) public onlyOwner {
    phase = _phase;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setTears(address _tears) public onlyOwner {
    Tears = ERC20Burnable(_tears);
  }

  function setTreasury(address _treasury) public onlyOwner {
    treasury = _treasury;
  }

  function setTreasuryRatio(uint256 _treasuryRatio) public onlyOwner {
    treasuryRatio = _treasuryRatio;
  }

  function setPhaseSupply(uint256 _phaseSupply) public onlyOwner {
    phaseSupply = _phaseSupply;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool treasuryCall, ) = payable(treasury).call{value: address(this).balance * treasuryRatio / 1000}("");
    require(treasuryCall, "Treasury withdraw failed");
    (bool ownerCall, ) = payable(owner()).call{value: address(this).balance}("");
    require(ownerCall, "Owner withdraw failed");
  }
}