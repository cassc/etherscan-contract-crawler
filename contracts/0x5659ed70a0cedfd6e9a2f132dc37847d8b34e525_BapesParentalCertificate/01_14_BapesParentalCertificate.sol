// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BapesParentalCertificate is ERC721A, Ownable, AccessControl {
  using Strings for uint256;

  bool private paused = false;
  string private metadataURI;
  bytes32 private merkleRoot;
  address private burnAllowed;
  mapping(address => bool) private mintedWallets;

  constructor(string memory _metadataURI) ERC721A("Bapes Parental Certificate", "BPC") {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    updateMetadataURI(_metadataURI);
  }

  function addressToString() internal view returns (string memory) {
    return Strings.toHexString(uint160(_msgSender()), 20);
  }

  function getOwnerTokens(address _owner) internal view returns (uint256[] memory) {
    uint256 ownerBalance = balanceOf(_owner);
    uint256[] memory ownerTokens = new uint256[](ownerBalance);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerBalance && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownerTokens[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownerTokens;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256) public view virtual override returns (string memory) {
    return metadataURI;
  }

  function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external {
    require(!paused, "Minting is paused");
    require(!mintedWallets[_msgSender()], "This wallet has already minted the PC");

    bytes32 leaf = keccak256(abi.encodePacked(addressToString(), "-", _mintAmount.toString()));

    require(
      MerkleProof.verify(_merkleProof, merkleRoot, leaf),
      "Invalid proof, this wallet is not eligible for selected amount of BapesParentalCertificate"
    );

    mintedWallets[_msgSender()] = true;

    _safeMint(_msgSender(), _mintAmount);
  }

  // admin
  function updateMetadataURI(string memory _metadataURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    metadataURI = _metadataURI;
  }

  function updateBurnAllowed(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
    burnAllowed = _address;
  }

  function mintFor(uint256 _mintAmount, address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!paused, "Minting is paused");

    _safeMint(_receiver, _mintAmount);
  }

  function togglePause(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    paused = _state;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    merkleRoot = _merkleRoot;
  }

  function burn(uint256 _amount, address _address) external returns (bool) {
    require(msg.sender == burnAllowed, "This address is not allowed to burn");
    require(balanceOf(_address) >= _amount, "Not enough PC");

    uint256[] memory tokens = getOwnerTokens(_address);

    for (uint256 i = 0; i < _amount; i++) {
      _burn(tokens[i]);
    }

    return true;
  }
}