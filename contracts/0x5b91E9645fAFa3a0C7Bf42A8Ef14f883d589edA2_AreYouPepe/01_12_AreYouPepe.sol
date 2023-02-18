/*

__________████████_____██████
_________█░░░░░░░░██_██░░░░░░█
________█░░░░░░░░░░░█░░░░░░░░░█
_______█░░░░░░░███░░░█░░░░░░░░░█
_______█░░░░███░░░███░█░░░████░█
______█░░░██░░░░░░░░███░██░░░░██
_____█░░░░░░░░░░░░░░░░░█░░░░░░░░███
____█░░░░░░░░░░░░░██████░░░░░████░░█
____█░░░░░░░░░█████░░░████░░██░░██░░█
___██░░░░░░░███░░░░░░░░░░█░░░░░░░░███
__█░░░░░░░░░░░░░░█████████░░█████████
_█░░░░░░░░░░█████_████___████_█████___█
_█░░░░░░░░░░█______█_███__█_____███_█___█
█░░░░░░░░░░░░█___████_████____██_██████
░░░░░░░░░░░░░█████████░░░████████░░░█
░░░░░░░░░░░░░░░░█░░░░░█░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░██░░░░█░░░░░░██
░░░░░░░░░░░░░░░░░░██░░░░░░░███████
░░░░░░░░░░░░░░░░██░░░░░░░░░░█░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░█████████░░░░░░░░░░░░░░██
░░░░░░░░░░█▒▒▒▒▒▒▒▒███████████████▒▒█
░░░░░░░░░█▒▒███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█
░░░░░░░░░█▒▒▒▒▒▒▒▒▒█████████████████
░░░░░░░░░░████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█
░░░░░░░░░░░░░░░░░░██████████████████
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
██░░░░░░░░░░░░░░░░░░░░░░░░░░░██
▓██░░░░░░░░░░░░░░░░░░░░░░░░██
▓▓▓███░░░░░░░░░░░░░░░░░░░░█
▓▓▓▓▓▓███░░░░░░░░░░░░░░░██
▓▓▓▓▓▓▓▓▓███████████████▓▓█
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█

*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./MerkleProof.sol";

contract AreYouPepe is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  using Strings for uint256;

  uint256 public maxSupplyWhitelist; /* Whitelist mint supply */
  uint256 public maxSupplyPublic; /* Public mint supply */

  uint256 public maxMintAmountPerWallet; /* Max per wallet */
  uint256 public maxFreeMintAmountPerWallet; /* Max free per wallet */

  uint256 public teamSupply; // Team supply
  
  /* Metadata Jargin */
  string public uriPrefix;
  string public hiddenMetadataUri;
  uint256 public maxSupply;
  string public uriSuffix = '.json';

  /* Keeping the pepe's safe */
  mapping(address => bool) freeMint;
  mapping(address => bool) freeWhitelistMint;
  uint256 public publicMintCost;
  uint256 public whitelistMintCost;
  bytes32 public merkleRoot;

  /* Are you pepe? */
  bool public paused = true;
  bool public revealed = false;

  constructor(
      uint256 _publicMintCost,
      uint256 _whitelistMintCost,
      uint256 _maxSupply,
      string memory _uriPrefix,
      string memory _hiddenURI
    ) ERC721A(
        "Are You Pepe",
        "YOUPEPE"
    ) {
    maxSupply = _maxSupply;
    uriPrefix = _uriPrefix;
    hiddenMetadataUri = _hiddenURI;
    publicMintCost = _publicMintCost;
    whitelistMintCost = _whitelistMintCost;
    maxFreeMintAmountPerWallet = 1;
    teamSupply = 2;
    _safeMint(msg.sender, 1);
  }

  /**
  @dev Burn thy NFT
  */
  function burn(uint256 tokenId) external {
    require(ownerOf(tokenId) == _msgSender(), "You are not the owner!");
    _burn(tokenId, true);
  }

  /**
  @dev Mint thy Pepe
  */
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {
    require(!paused, 'Alas, the door is closed, dear friend.');
    if(freeMint[_msgSender()]) {
      require(msg.value >= _mintAmount * publicMintCost, 'Insufficient Funds!');
    }
    else {
      require(msg.value >= (_mintAmount - 1) * publicMintCost, 'Insufficient Funds!');
      freeMint[_msgSender()] = true;
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  /**
  @dev Check if thy MAY BE PEPE
  */
  function checkPepelist(bytes32[] calldata proof) public view returns (bool) {
    return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
  }

  /**
  @dev Mint pepelist
  */
  function pepelistMint(uint256 _mintAmount, bytes32[] calldata proof) public payable mintCompliance(_mintAmount) nonReentrant {

    require(!paused, 'Alas, the door is closed, dear friend.');
    require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "We are most sorry, but thy name is not on the list");

    if(freeWhitelistMint[_msgSender()]) {
      // Free mint used up
      require(msg.value >= _mintAmount * whitelistMintCost, 'Insufficient Funds!');
    }
    else {
      // Update price include a free mint
      require(msg.value >= (_mintAmount - 1) * whitelistMintCost, 'Insufficient Funds!');
      freeWhitelistMint[_msgSender()] = true;
    }

    _safeMint(_msgSender(), _mintAmount);
  }

  /**
  @dev Mint for team members
  */
  function teamMint(address[] memory _staff_address) public onlyOwner payable {
    require(_staff_address.length <= teamSupply, '');
    for (uint256 i = 0; i < _staff_address.length; i ++) {
      _safeMint(_staff_address[i], 1);
    }
  }

  /**
  @dev Set the starting token ID to 1
  */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
  @dev Sets the token URI
  */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, "/", _tokenId.toString(), uriSuffix))
    : '';
  }

  /**
  @dev Set NFT reveal
  */
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  /**
  @dev Set merkle root for whitelist
  */
  function setMerkleRoots(bytes32 root) external onlyOwner {
      merkleRoot = root;
    }

  /**
  @dev Unrevealed metadata url
  */
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  /**
  @dev Set the uri suffix
  */
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  /**
  @dev Set the uri suffix (i.e .json)
  */
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  /**
  @dev Set mint price
  */
  function setMintCost(uint256 _cost, uint256 _wlCost) public onlyOwner {
      publicMintCost = _cost;
      whitelistMintCost = _wlCost;
  }

  /**
  @dev Mint compliance calculations
  */
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount <= 17, "Max 17 per transaction");
    require(totalSupply() + _mintAmount <= maxSupply, 'Max Supply Exceeded!');
    _;
  }

  /**
  @dev Set sale is active (paused / unpaused)
  */
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  /**
  @dev Set max supply
  */
  function setMaxSupply(uint256 _buffer) public onlyOwner {
    maxSupply = _buffer;
  }

  /**
  @dev Sets the amount allocated for team members
  */
  function setTeamAmount(uint256 _teamSupply) public onlyOwner {
    teamSupply = _teamSupply;
  }



  /**
  @dev Withdraw function
  */
  function withdraw() public onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  /**
  @dev OpenSea
  */
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
  public payable
  override
  onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}