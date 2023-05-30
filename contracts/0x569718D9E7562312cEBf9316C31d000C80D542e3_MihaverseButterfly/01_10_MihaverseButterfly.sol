// SPDX-License-Identifier: MIT

/*******************************************************************************
*..............................................................................*
*..............█████........................................█████..............*
*............██   ░░█████..............................█████░░   ██............*
*............██░░░░░██...█████....................█████...██░░░░░██............*
*..............█████..........███..............███..........█████..............*
*................................██..........██................................*
*.........█████████████............██......██............█████████████.........*
*......███░░░░░░░░░░░░░███.......██████████████.......███░░░░░░░░░░░░░██.......*
*....██░░░░░░░░░░░░░░░░░░░██..███░░░░      ░░░░███..██░░░░░░░░░░░░░░░░░░██.....*
*....██░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░    ░░░░░░░░██░░░░░░░░░░░░░░░░░░░░██.....*
*....██░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░██.....*
*....██░░░░░░░░░░░░░░░░░░░██░░░░░███░░░░░░░░███░░░░░██░░░░░░░░░░░░░░░░░░██.....*
*....██░░░░░░░░░░░░░░░░░░░██░░░░░███░░░░░░░░███░░░░░██░░░░░░░░░░░░░░░░░░██.....*
*....██░░░░░░░░░░░░░░░░░░░██░░░░░███░░░░░░░░███░░░░░██░░░░░░░░░░░░░░░░░░██.....*
*......██░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░██.......*
*........██████████░░░░░░░██░░░██████████████████░░░██░░░░░░░░████████.........*
*.................██████████░░░██░░░░░░░░░░░░░░██░░░██████████.................*
*............█████░░░░░░░░██░░░██░░░░░░░░░░░░░░██░░░██░░░░░░░░█████............*
*.........███░░░░░░░░░░░░░██░░░░░██░░░░░░░░░░██░░░░░██░░░░░░░░░░░░░███.........*
*.......██░░░░░░░░░░░░░░░░██░░░░░░░██████████░░░░░░░██░░░░░░░░░░░░░░░░██.......*
*.......██░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░██.......*
*.......██░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░██.......*
*.......██░░░░░░░░░░░░░░░░░░░░███░░░░░░░░░░░░░░███░░░░░░░░░░░░░░░░░░░░██.......*
*.......██░░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░██.......*
*.........███░░░░░░░░░░░░░░░░░███..██████████..███░░░░░░░░░░░░░░░░░███.........*
*............██░░░░░░░░░░█████....................█████░░░░░░░░░░██............*
*..............██████████..............................██████████..............*
*..............................................................................*
*..............................................................................*
*..............................................................................*
*******************************************************************************/

/// @title MIHAVERSE Butterfly Contract
/// @author MIHA

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MihaverseButterfly is 
     ERC721A, 
     IERC2981,
     Ownable, 
     ReentrancyGuard 
{
  using Strings for uint256;

  bytes32 public merkleRoot;

  address public royaltyAddress;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenUri = '';

  uint256 public maxSupply = 1112; // +1 to save on gas cost of <= vs <
  uint256 public royalty = 100; // Must be a whole number 7.5% is 75

  bool public paused = false;
  bool public revealed = false;
  bool public frozen = false; //Freeze Metadata

  mapping(address => bool) public addressClaimed; 

  constructor() 
  ERC721A("Mihaverse Butterfly", "MBTFL") {
    royaltyAddress = msg.sender;
  }

/// @dev === MODIFIER ===
  modifier mintCompliance() {
    require(!paused, 'The contract is paused!');
    require(totalSupply() + 1 < maxSupply, 'Sold out!');
    require(!addressClaimed[_msgSender()], 'Address already claimed!');
    _;
  }

/// @dev === Minting Function - Input ====
  function mint(bytes32[] calldata _merkleProof) external payable
  mintCompliance() 
  nonReentrant
  {
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid signature!');

    addressClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), 1);
  }

  function mintForAddress(uint256 _amount, address _receiver) public payable onlyOwner {
    require(totalSupply() + _amount < maxSupply, 'Sold out!');

    _safeMint(_receiver, _amount);
  }

/// @dev === Override ERC721A ===
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'Nonexistent token!');

    if (revealed == false) {
      return hiddenUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

/// @dev === Owner Control/Configuration Functions ===
  function pause() public onlyOwner {
    paused = !paused;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    require(!frozen, 'Metadata is frozen!');
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    require(!frozen, 'Metadata is frozen!');
    uriSuffix = _uriSuffix;
  }

  function setHiddenUri(string memory _uriHidden) public onlyOwner {
    require(!frozen, 'Metadata is frozen!');
    hiddenUri = _uriHidden;
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function freeze() public onlyOwner {
    frozen = true;
  }

  function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
    royaltyAddress = _royaltyAddress;
  }

  function setRoyaly(uint256 _royalty) external onlyOwner {
        royalty = _royalty;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

/// @dev === INTERNAL READ-ONLY ===
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

/// @dev === Withdraw ====
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

//IERC2981 Royalty Standard
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external view override returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (royaltyAddress, (salePrice * royalty) / 1000);
    }                                                

/// @dev === Support Functions ==
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}