// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BapesStanLeeCertificate is ERC721A, Ownable, AccessControl {
  IERC721 private bgkGold;
  IERC721 private bgkDiamond;

  string metadataURI;
  bool isMintPaused = false;
  bool isPaused = false;

  constructor(string memory _metadataURI) ERC721A("Bapes Stan Lee Certificate", "SGC") {
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
    require(!isPaused, "Contract is paused.");
  }

  function tokenURI(uint256) public view virtual override returns (string memory) {
    return metadataURI;
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

  function mint() external {
    require(!isMintPaused, "Minting is paused.");

    uint256 bgkGoldBalance = bgkGold.balanceOf(_msgSender());
    uint256 bgkDiamondBalance = bgkDiamond.balanceOf(_msgSender());

    require(
      (bgkGoldBalance + bgkDiamondBalance) > 0,
      "This wallet does not have the required BGK Gold or BGK Diamond."
    );

    uint256 mintAmount = (bgkGoldBalance) + (bgkDiamondBalance * 2);

    _safeMint(_msgSender(), mintAmount);
  }

  function mintFor(uint256 _mintAmount, address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!isMintPaused, "Minting is paused");

    _safeMint(_receiver, _mintAmount);
  }

  function updateMetadataURI(string memory _metadataURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    metadataURI = _metadataURI;
  }

  function togglePause(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isPaused = _state;
  }

  function toggleMint(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isMintPaused = _state;
  }
}