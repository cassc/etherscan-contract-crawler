// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract ERC721Airdrop is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Metadata,
    Ownable
{
  function airdrop(address[] memory receivers, bytes32[] memory tokenURIs, bytes calldata _data) public onlyOwner{
    uint256 l = receivers.length;
    require(l == tokenURIs.length, "ERC721Airdrop: receivers and tokenURIs length mismatch");
    // we get the last token id and start from there
    uint256 tokenId = _owners.length;
    for(uint256 i = 0; i < l; i++){
      // we add the index to the tokenId so that we don't need to call length each loop
      _mintAndTransfer(msg.sender, receivers[i], tokenId + i, _data);
      _setTokenURI(tokenId + i, tokenURIs[i]);
    }
  }

  function mint(bytes32 _tokenURI, address _to) external onlyOwner {
    uint256 tokenId = _owners.length;
    _mint(_to, tokenId);
    _setTokenURI(tokenId, _tokenURI);
  }

  function mintAndTransfer(address _to, bytes32 _tokenURI, bytes calldata _data) external onlyOwner {
    uint256 tokenId = _owners.length;
    _mintAndTransfer(msg.sender, _to, tokenId, _data);
    _setTokenURI(tokenId, _tokenURI);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721Metadata) {
    super._burn(tokenId);
  }

  function exists(uint256 _id) external view returns (bool) {
    return _owners[_id] != ZERO_ADDRESS;
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return interfaceId == 0x80ac58cd // type(IERC721).interfaceId
        || interfaceId == 0x780e9d63 // type(IERC721Enumerable).interfaceId
        || interfaceId == 0x5b5e139f; // type(IERC721Metadata).interfaceId
  }

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
  }

}