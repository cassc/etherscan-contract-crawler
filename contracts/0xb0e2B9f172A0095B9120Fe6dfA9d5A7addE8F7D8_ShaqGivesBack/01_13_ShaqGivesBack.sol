//
// ███████╗██╗  ██╗ █████╗  ██████╗      ██████╗ ██╗██╗   ██╗███████╗███████╗
// ██╔════╝██║  ██║██╔══██╗██╔═══██╗    ██╔════╝ ██║██║   ██║██╔════╝██╔════╝
// ███████╗███████║███████║██║   ██║    ██║  ███╗██║██║   ██║█████╗  ███████╗
// ╚════██║██╔══██║██╔══██║██║▄▄ ██║    ██║   ██║██║╚██╗ ██╔╝██╔══╝  ╚════██║
// ███████║██║  ██║██║  ██║╚██████╔╝    ╚██████╔╝██║ ╚████╔╝ ███████╗███████║
// ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══▀▀═╝      ╚═════╝ ╚═╝  ╚═══╝  ╚══════╝╚══════╝
//
//                  ██████╗  █████╗  ██████╗██╗  ██╗
//                  ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝
//                  ██████╔╝███████║██║     █████╔╝
//                  ██╔══██╗██╔══██║██║     ██╔═██╗
//                  ██████╔╝██║  ██║╚██████╗██║  ██╗
//                  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
//                    In partnership with Notables
//
// Supported by @shufflemint
// SPDX-License-Identifier: MIT



pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ShaqGivesBack is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  uint256 constant public maxSupply = 10000;
  uint256 constant public maxMintAmount = 5;
  uint256 constant public wlAllowance = 3;
  bool public publicActive = false;
  bool public presaleActive = false;
  uint256 constant public teamClaimAmount = 30;
  bool public teamClaimed = false;
  // Set merkleRoot for whitelist
  bytes32 public whitelistMerkleRoot;

  // mapping to track whitelist that already claimed
  mapping(address => uint) public addressClaimed;

  // Payment Addresses
  address constant notables = 0xC135026969aa9765055eAe9DA120491a1df649b8;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    _tokenIds.increment();
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // presale
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
    require(presaleActive, "Sale has not started yet.");
    require(_mintAmount > 0, "Quantity cannot be zero");
    require(addressClaimed[_msgSender()] + _mintAmount <= wlAllowance, "Exceeds whitelist supply");
    require(totalSupply() + _mintAmount <= maxSupply, "Quantity requested exceeds max supply");
    require(msg.value >= cost * _mintAmount, "Ether value sent is below the price");

    // Verify merkle proof
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid proof");

    // Mark address as having claimed
    addressClaimed[_msgSender()] += _mintAmount;

    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 mintIndex = _tokenIds.current();
      _mint(msg.sender, mintIndex);

      // increment id counter
      _tokenIds.increment();
    }
  }

  function publicMint(uint256 _mintAmount) public payable {
    require(publicActive, "Sale has not started yet.");
    require(_mintAmount > 0, "Quantity cannot be zero");
    require(_mintAmount <= maxMintAmount, "Exceeds 5, the max qty per mint");
    require(totalSupply() + _mintAmount <= maxSupply, "Quantity requested exceeds max supply.");
    require(msg.value >= cost * _mintAmount, "Ether value sent is below the price");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 mintIndex = _tokenIds.current();
      _mint(msg.sender, mintIndex);

      // increment id counter
      _tokenIds.increment();
    }
  }

  function teamClaim() public onlyOwner {
    require(totalSupply() + teamClaimAmount <= maxSupply, "Quantity requested exceeds max supply.");
    require(!teamClaimed, "Team has claimed");
    for (uint256 i = 1; i <= teamClaimAmount; i++) {
      uint256 mintIndex = _tokenIds.current();
      _mint(msg.sender, mintIndex);

    _tokenIds.increment();
    }
  teamClaimed = true;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function enablePresale(bool _state) public onlyOwner {
    presaleActive = _state;
  }

  function enablePublic(bool _state) public onlyOwner {
    publicActive = _state;
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIds.current() - 1;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(notables).call{value: address(this).balance}("");
    require(os);
  }

  function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
      whitelistMerkleRoot = _whitelistMerkleRoot;
  }

}