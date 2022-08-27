// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CubeXCard is ERC721A, Ownable, AccessControl {
  using Strings for uint256;

  bool private isPaused = false;
  bool private isMintPaused = true;
  string private metadataURI;
  bytes32 private merkleRoot;
  uint256 public mintPerWallet = 1;
  mapping(address => uint256) private mintedWallets;

  constructor(string memory _metadataURI) ERC721A("CubeX Card", "CXC") {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    updateMetadataURI(_metadataURI);
  }

  function _beforeTokenTransfers(
    address,
    address,
    uint256,
    uint256
  ) internal view override {
    require(!isPaused, "Contract is paused.");
  }

  function addressToString() internal view returns (string memory) {
    return Strings.toHexString(uint160(_msgSender()), 20);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256) public view virtual override returns (string memory) {
    return metadataURI;
  }

  function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public {
    uint256 minted = mintedWallets[_msgSender()];

    require(!isMintPaused, "Minting is paused");
    require(minted < mintPerWallet, "This wallet has already minted");

    bytes32 leaf = keccak256(abi.encodePacked(addressToString(), "-", _mintAmount.toString()));

    require(
      MerkleProof.verify(_merkleProof, merkleRoot, leaf),
      "Invalid proof, this wallet is not eligible for selected amount of NFTs"
    );

    mintedWallets[_msgSender()] = mintPerWallet;

    _safeMint(_msgSender(), _mintAmount);
  }

  function getOwnerTokens(address _owner) public view returns (uint256[] memory) {
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

  function updateMetadataURI(string memory _metadataURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    metadataURI = _metadataURI;
  }

  function mintFor(uint256 _mintAmount, address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!isMintPaused, "Minting is paused");

    _safeMint(_receiver, _mintAmount);
  }

  function togglePause(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isPaused = _state;
  }

  function toggleMint(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isMintPaused = _state;
  }

  function updateMintPerWallet(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    mintPerWallet = _amount;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    merkleRoot = _merkleRoot;
  }
}