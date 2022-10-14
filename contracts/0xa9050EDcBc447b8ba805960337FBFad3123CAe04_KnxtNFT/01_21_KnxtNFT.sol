// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./KnxtNFTAdministrable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

error TotalSupplyExceeded();

contract KnxtNFT is ERC721AQueryable, ERC2981, KnxtNFTAdministrable {
  string internal _baseTokenURI;
  uint256 _collectionSize;

  constructor(string memory baseTokenURI, uint256 collectionSize, address royaltyReceiverAddress, uint96 royaltyFraction) ERC721A("KnxtNFT", "KNXT") {
    _baseTokenURI = baseTokenURI;
    _collectionSize = collectionSize;

    _setDefaultRoyalty(royaltyReceiverAddress, royaltyFraction);
  }

  // Reveal utils
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseTokenURI(string memory baseTokenURI) external onlyRole(ADMINISTRATOR_ROLE) {
      _baseTokenURI = baseTokenURI;
  }

  function setRoyalties(address receiver, uint96 feeNumerator) external onlyRole(ADMINISTRATOR_ROLE) {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  // Validators
  function _assertEnoughSupplyForQuantity(uint256 quantity) private view {
    if (totalSupply() + quantity > _collectionSize) {
      revert TotalSupplyExceeded();
    }
  }

  // Domain
  function airdrop(address recipientAddress, uint256 quantity) external onlyAirdropperOrAdministrator {
    _assertEnoughSupplyForQuantity(quantity);

    _mint(recipientAddress, quantity);
  }
  
  function batchAirdrop(address[] memory recipientAddresses) external onlyAirdropperOrAdministrator {
    _assertEnoughSupplyForQuantity(recipientAddresses.length);

    for (uint i = 0; i < recipientAddresses.length; ++i) {
      _mint(recipientAddresses[i], 1);  
    }
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721A, ERC2981, AccessControlEnumerable) returns (bool) {
      return super.supportsInterface(interfaceId);
  }
}