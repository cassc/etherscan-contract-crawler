// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/eip/ERC721A.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "@thirdweb-dev/contracts/extension/Royalty.sol";

contract ERC721DelayedRevealAirdrop is ERC721A, ContractMetadata, Multicall, Ownable, Royalty {
  using TWStrings for uint256;

  string private prerevealMetadata;
  string private tokenBaseURI;
  uint256 private maxTotalSupply;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxSupply,
    string memory _prerevealMetadata,
    address _royaltyRecipient,
    uint128 _royaltyBps
  ) ERC721A(_name, _symbol) {
    _setupOwner(msg.sender);
    _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    maxTotalSupply = _maxSupply;
    prerevealMetadata = _prerevealMetadata;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

    string memory uri = super.tokenURI(_tokenId);
    if (bytes(uri).length == 0) {
      return prerevealMetadata;
    }

    return uri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return tokenBaseURI;
  }

  function setBaseURI(string memory _uri) external {
    require(msg.sender == owner(), "!owner");
    tokenBaseURI = _uri;
  }

  function airdrop(address[] calldata _addresses, uint256[] calldata _amounts) external {
    require(_addresses.length == _amounts.length, "!len");
    require(msg.sender == owner(), "!owner");
    for (uint256 i = 0; i < _addresses.length; i += 1) {
      _safeMint(_addresses[i], _amounts[i], "");
    }
  }

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override {
    // in the case of minting
    if (from == address(0)) {
      require(startTokenId + quantity <= maxTotalSupply, "!supply");
    }
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
    return interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
      interfaceId == type(IERC2981).interfaceId; // ERC165 ID for ERC2981
  }

  /**
   *  @notice         Lets an owner or approved operator burn the NFT of the given tokenId.
   *  @dev            ERC721A's `_burn(uint256,bool)` internally checks for token approvals.
   *
   *  @param _tokenId The tokenId of the NFT to burn.
   */
  function burn(uint256 _tokenId) external virtual {
    _burn(_tokenId, true);
  }

  /// @dev Returns whether contract metadata can be set in the given execution context.
  function _canSetContractURI() internal view virtual override returns (bool) {
    return msg.sender == owner();
  }

  /// @dev Returns whether owner can be set in the given execution context.
  function _canSetOwner() internal view virtual override returns (bool) {
    return msg.sender == owner();
  }

  /// @dev Returns whether royalty info can be set in the given execution context.
  function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
    return msg.sender == owner();
  }
}