// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BapesGenesisKeyGold is ERC721A, Ownable, AccessControl {
  IERC721 private bgk1;
  IERC721 private bgk2;

  string metadataURI;
  bool isMintPaused = false;
  bool isPaused = false;
  address recipient;

  constructor(string memory _metadataURI) ERC721A("Bapes Genesis Key Gold", "BGKG") {
    bgk1 = IERC721(0x3A472c4D0dfbbb91ed050d3bb6B3623037c6263c);
    bgk2 = IERC721(0xC5F919d729051d2BfF3a71C159096828B0dd9F45);

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

  function mint(
    uint256 _mintAmount,
    uint256[] memory _bgk1Tokens,
    uint256[] memory _bgk2Tokens
  ) external {
    require(!isMintPaused, "Minting is paused.");

    uint256 bgkRequired = _mintAmount * 3;
    uint256 bgk1Balance = bgk1.balanceOf(_msgSender());
    uint256 bgk2Balance = bgk2.balanceOf(_msgSender());

    if (bgk1Balance >= bgkRequired) {
      for (uint256 i = 0; i < bgkRequired; i++) {
        bgk1.safeTransferFrom(_msgSender(), recipient, _bgk1Tokens[i]);
      }

      _safeMint(_msgSender(), _mintAmount);
    } else if (bgk2Balance >= bgkRequired) {
      for (uint256 i = 0; i < bgkRequired; i++) {
        bgk2.safeTransferFrom(_msgSender(), recipient, _bgk2Tokens[i]);
      }

      _safeMint(_msgSender(), _mintAmount);
    } else if ((bgk1Balance + bgk2Balance) >= bgkRequired) {
      uint256 remaining = bgkRequired - bgk1Balance;

      for (uint256 i = 0; i < bgk1Balance; i++) {
        bgk1.safeTransferFrom(_msgSender(), recipient, _bgk1Tokens[i]);
      }

      for (uint256 i = 0; i < remaining; i++) {
        bgk2.safeTransferFrom(_msgSender(), recipient, _bgk2Tokens[i]);
      }

      _safeMint(_msgSender(), _mintAmount);
    } else {
      revert("You do not have enough BGKs to morph into selected amount of Gold.");
    }
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

  function updateRecipient(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
    recipient = _address;
  }
}