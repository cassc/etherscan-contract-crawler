// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/[email protected]/utils/Counters.sol";
import "@openzeppelin/[email protected]/utils/Strings.sol";
import "@openzeppelin/[email protected]/utils/cryptography/ECDSA.sol";
import "[email protected]/src/DefaultOperatorFilterer.sol";

contract NorthApes is Ownable, ERC721Enumerable, ERC721Royalty, DefaultOperatorFilterer {
  using Counters for Counters.Counter;
  using ECDSA for bytes32;

  uint256 private constant MAX_SUPPLY = 5555;
  uint96 private constant ROYALTY = 555; // 5.55%
  uint256 private constant MINT_PRICE = 5000000000000000; // 0.005 ETH
  address private constant SIGNER = 0xAAa8a66095004f07287fec7e7A2e220F142a24A1;

  address private _treasury;
  Counters.Counter private _ids;

  mapping (address => bool) public redeemedWhitelistSpot;

  event SetTreasury(address oldTreasury, address newTreasury);

  constructor(address treasury) ERC721("North Apes", "NA") {
    setTreasury(treasury);
    _mint(address(this), 0);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721Royalty) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function approve(address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(to) {
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function setTreasury(address treasury) public onlyOwner {
    emit SetTreasury(_treasury, treasury);
    _treasury = treasury;
    _setDefaultRoyalty(treasury, ROYALTY);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireMinted(tokenId);
    return string(abi.encodePacked("https://northapes.com/assets/apes/", Strings.toString(tokenId), "/metadata.json"));
  }

  function contractURI() external pure returns (string memory) {
    return "https://northapes.com/assets/contract-metadata.json";
  }

  function mint(bool whitelist, bytes memory signature) external payable {
    address sender = _msgSender();
    require(keccak256(abi.encode(block.chainid, address(this), sender, whitelist)).toEthSignedMessageHash().recover(signature) == SIGNER, "NorthApes::mint: invalid signature");
    _ids.increment();
    uint256 id = _ids.current();
    require(id < MAX_SUPPLY, "NorthApes::mint: sold out");

    if (whitelist) {
      require(msg.value == 0, "NorthApes::mint: whitelist spots mint for free");
      require(!redeemedWhitelistSpot[sender], "NorthApes::mint: already redeemed whitelist spot");
      redeemedWhitelistSpot[sender] = true;
    } else {
      require(msg.value == MINT_PRICE, "NorthApes::mint: sent amount does not match price");
      (bool success, ) = _treasury.call{ value: address(this).balance }(new bytes(0));
      require(success, "NorthApes::mint: ETH transfer failed");
    }

    _mint(sender, id);
  }
}