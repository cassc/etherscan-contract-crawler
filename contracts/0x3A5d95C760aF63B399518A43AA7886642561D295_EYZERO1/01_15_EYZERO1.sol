// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract EYZERO1 is ERC721A, Ownable, AccessControl, ReentrancyGuard {
  using Strings for uint256;

  uint256 private constant maxSupply = 910;
  uint256 private maxSupplyTotal = 910;
  uint256 private price = 0.19 ether;
  bool public paused = true;
  string public metadataURI;
  address public withdrawWallet;

  constructor(string memory _metadataURI) ERC721A("EY-ZERO1", "EY01") {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    setMetadataURI(_metadataURI);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256) public view virtual override returns (string memory) {
    return metadataURI;
  }

  function getOwnerTokens(address _owner) external view returns (uint256[] memory) {
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

  function publicMint(uint256 _mintAmount) external payable {
    require(!paused, "Minting is paused.");
    require((totalSupply() + _mintAmount) <= maxSupplyTotal, "Mint amount exceeds allocated supply.");
    require(msg.value >= (price * _mintAmount), "Insufficient balance to mint.");

    _safeMint(_msgSender(), _mintAmount);
  }

  // admin
  function setMetadataURI(string memory _metadataURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    metadataURI = _metadataURI;
  }

  function mintFor(uint256 _mintAmount, address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!paused, "Minting is paused.");
    require((totalSupply() + _mintAmount) <= maxSupplyTotal, "Mint amount exceeds allocated supply.");

    _safeMint(_receiver, _mintAmount);
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    require(withdrawWallet != address(0), "Withdraw wallet is not set.");

    (bool success, ) = payable(withdrawWallet).call{value: address(this).balance}("");

    require(success, "Withdraw failed.");
  }

  function updateWithdrawWallet(address _withdrawWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
    withdrawWallet = _withdrawWallet;
  }

  function updatePrice(uint256 _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
    price = _price;
  }

  function updateMaxSupplyTotal(uint256 _number) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // collection can be capped, if needed, but can never increase from initial total
    require(_number <= maxSupply, "Public supply can not exceed total defined.");

    maxSupplyTotal = _number;
  }

  function togglePause(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
    paused = _state;
  }
}