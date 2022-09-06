// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

import "./interfaces/IL1StandardBridge.sol";

contract BridgePassNFT is ERC721, ERC721Royalty, Pausable, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;

  error PAYMENT_TOO_LOW();
  error SOLD_OUT();

  Counters.Counter public supply;

  // Goerli: 0x636af16bf2f682dd3109e60102b8e1a089fedaa8
  address public l1StandardBridge = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;

  string baseUri;

  uint256 public cost = 0.001 ether;

  address public royaltyRecipient = 0x523d007855B3543797E0d3D462CB44B601274819;
  uint96 public royaltyBasisPoints = 500;
  uint256 public maxSupply = 12;

  uint256 public maxMintAmountPerTx = 1;
  uint256 public maxMintPerAccount;

  uint32 public l2Gas = 200_000;

  constructor() ERC721("Bridge Pass Tree of Life", "BPTOL") {
    baseUri = "ipfs://QmeiiLFhhbfqT7uaR91jy8w4E1y4nzo59eRahGQmwovfBd/";

    _setDefaultRoyalty(royaltyRecipient, royaltyBasisPoints);

    maxMintPerAccount = maxSupply;

    transferOwnership(0x523d007855B3543797E0d3D462CB44B601274819);
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function setBaseUri(string memory _baseUri) external onlyOwner {
    baseUri = _baseUri;
  }

  function setcost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  function setRoyaltyRecipient(address _royaltyRecipient) external onlyOwner {
    royaltyRecipient = _royaltyRecipient;
  }

  function setRoyaltyBasisPoints(uint96 _royaltyBasisPoints) external onlyOwner {
    royaltyBasisPoints = _royaltyBasisPoints;
  }

  function setL2Gas(uint32 _l2Gas) external onlyOwner {
    l2Gas = _l2Gas;
  }

  function _baseURI() internal view override(ERC721) returns (string memory) {
    return baseUri;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function safeMint(address to) external onlyOwner {
    if (supply.current() + 1 > maxSupply) {
      revert SOLD_OUT();
    }

    supply.increment();
    uint256 tokenId = supply.current();
    _safeMint(to, tokenId);
  }

  function mint() external payable {
    if (msg.value < cost) {
      revert PAYMENT_TOO_LOW();
    }

    if (supply.current() + 1 > maxSupply) {
      revert SOLD_OUT();
    }

    supply.increment();

    IL1StandardBridge(l1StandardBridge).depositETHTo{ value: msg.value }(msg.sender, l2Gas, "");

    _safeMint(msg.sender, supply.current());
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Royalty) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
    return string(abi.encodePacked(super.tokenURI(_tokenId), ".json"));
  }
}