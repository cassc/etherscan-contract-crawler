// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./RoyaltyReceiver.sol";

/// @author no-op.eth (nft-lab.xyz)
/// @title Phto Curated - fine art photography (phto.io)
contract PhtoCurated is ERC1155, ERC1155Burnable, Ownable, IERC2981 {
  /** Name of collection */
  string public constant name = "Phto Curated";
  /** Symbol of collection */
  string public constant symbol = "PHTO";
  /** URI for the contract metadata */
  string public contractURI;
  /** Royalty information */
  mapping(uint256 => RoyaltyReceiver) public royalties;

  /** For URI conversions */
  using Strings for uint256;

  constructor(string memory _uri) ERC1155(_uri) {}

  /// @notice Sets the base URI
  /// @param val Updated base URI
  function setBaseURI(string memory val) external onlyOwner {
    _setURI(val);
  }

  /// @notice Sets the base metadata URI
  /// @param val The new URI
  function setCollectionURI(string memory val) external onlyOwner {
    contractURI = val;
  }

  /// @notice Returns a given token's URI
  /// @param id Token ID
  function uri(uint256 id) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(id), id.toString()));
  }

  /// @notice Notify other contracts of supported interfaces
  /// @param interfaceId Magic bits
  /// @return Yes/no
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  /// @notice Get the royalty info for a given ID
  /// @param _tokenId NFT ID to check
  /// @param _salePrice Price sold for
  /// @return receiver The address receiving the royalty
  /// @return royaltyAmount The royalty amount to be received
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view override returns (address receiver, uint256 royaltyAmount) {
    RoyaltyReceiver memory _receiverData = royalties[_tokenId];
    receiver = _receiverData.receiver;
    royaltyAmount = _salePrice * _receiverData.share / 100;
  }

  /// @notice Update royalties for specified IDs
  /// @param ids The IDs in question
  /// @param receiver The royalty receiver
  /// @param share The share for a given receiver
  function updateRoyalties(uint256[] calldata ids, address receiver, uint256 share) external onlyOwner {
    for (uint256 i = 0; i < ids.length; i++) {
      royalties[ids[i]] = RoyaltyReceiver(receiver, share);
    }
  }

  /// @notice Recover any funds
  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  /// @notice Mint a batch to sender
  /// @param ids The IDs to be minted
  /// @param amounts The amount of corresponding ID to mint
  function mint(uint256[] calldata ids, uint256[] calldata amounts) external onlyOwner {
    _mintBatch(msg.sender, ids, amounts, "0x0000");
  }

  /// @notice Mint a batch to specified address
  /// @param ids The IDs to be minted
  /// @param amounts The amount of corresponding ID to mint
  /// @param to The address to send mints to
  function mint(uint256[] calldata ids, uint256[] calldata amounts, address to) external onlyOwner {
    _mintBatch(to, ids, amounts, "0x0000");
  }
}