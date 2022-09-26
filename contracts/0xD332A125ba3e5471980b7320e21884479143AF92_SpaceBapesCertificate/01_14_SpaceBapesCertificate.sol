// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SpaceBapesCertificate is ERC721A, Ownable, AccessControl {
  using Strings for uint256;

  IERC721 private bgkGold;
  IERC721 private bgkDiamond;

  string public metadataURI;
  bool public isMintPaused = false;
  bool public isTransferPaused = false;
  uint256 public bapesFutureMintPerWallet = 1;
  bytes32 private bapesFutureMerkleRoot;
  mapping(address => bool) private bgkMintedWallets;
  mapping(address => uint256) private bapesFutureMintedWallets;

  constructor(string memory _metadataURI) ERC721A("Space Bapes Certificate", "SBC") {
    bgkGold = IERC721(0xbAD387f3Cb3b096A0DE13C8d9E49646376DA338e);
    bgkDiamond = IERC721(0x482cb3C8BE6984001b40b1b3a88332842580b1A4);

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    updateMetadataURI(_metadataURI);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfers(
    address,
    address,
    uint256,
    uint256
  ) internal view override {
    require(!isTransferPaused, "Contract is paused.");
  }

  function tokenURI(uint256) public view virtual override returns (string memory) {
    return metadataURI;
  }

  function addressToString() internal view returns (string memory) {
    return Strings.toHexString(uint160(_msgSender()), 20);
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

  function bgkMint() external {
    require(!isMintPaused, "Minting is paused.");
    require(!bgkMintedWallets[_msgSender()], "This wallet has already minted.");

    uint256 bgkGoldBalance = bgkGold.balanceOf(_msgSender());
    uint256 bgkDiamondBalance = bgkDiamond.balanceOf(_msgSender());
    uint256 mintAmount = (bgkGoldBalance * 2) + (bgkDiamondBalance * 3);

    require((bgkGoldBalance + bgkDiamondBalance) > 0, "This wallet does not have the BGK Gold or BGK Diamond.");

    bgkMintedWallets[_msgSender()] = true;

    _safeMint(_msgSender(), mintAmount);
  }

  function bapesFutureMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external {
    uint256 minted = bapesFutureMintedWallets[_msgSender()];

    require(!isMintPaused, "Minting is paused.");
    require(minted < bapesFutureMintPerWallet, "This wallet has already minted.");

    bytes32 leaf = keccak256(abi.encodePacked(addressToString(), "-", _mintAmount.toString()));

    require(
      MerkleProof.verify(_merkleProof, bapesFutureMerkleRoot, leaf),
      "Invalid proof, this wallet is not eligible to mint selected amount of NFTs."
    );

    bapesFutureMintedWallets[_msgSender()] = bapesFutureMintPerWallet;

    _safeMint(_msgSender(), _mintAmount);
  }

  function mintFor(uint256 _mintAmount, address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!isMintPaused, "Minting is paused");

    _safeMint(_receiver, _mintAmount);
  }

  function updateMetadataURI(string memory _metadataURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    metadataURI = _metadataURI;
  }

  function toggleTransfer(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isTransferPaused = _state;
  }

  function toggleMint(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isMintPaused = _state;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
    bapesFutureMerkleRoot = _merkleRoot;
  }
}