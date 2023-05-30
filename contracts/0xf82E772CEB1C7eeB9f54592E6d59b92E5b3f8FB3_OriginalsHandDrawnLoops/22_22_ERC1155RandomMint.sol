// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

abstract contract ERC1155RandomMint is ERC1155Supply {

  /** @dev This is a static array */
  uint256[25] public mintableTokenCount;

  mapping(address => uint256) public numberOfTokensMintedByAddress;

  uint256 public totalTokenSupply;
  uint256 public numTokensMinted;

  /**
  * @dev Configure the mintable token ids and their corresponding supply.
  */
  constructor(uint256[] memory _mintableTokenMaximumSupply) {
    for(uint256 i = 0; i < _mintableTokenMaximumSupply.length; i++ ) {
      mintableTokenCount[i] = _mintableTokenMaximumSupply[i];
      totalTokenSupply += _mintableTokenMaximumSupply[i];
    }
  }

  function _mint(address _to, uint256 _amount) internal {
    require(mintableSupply() > 0, "Not enough supply to mint all amount required");

    for(uint256 i=0; i < _amount; i++ ) {
      uint256 seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _msgSender(), i)));
      uint256 tokenIndex = seed % mintableSupply();
      uint256 tokenId = tokenIdAtIndex(tokenIndex);

      _internalMintTokenId(_to, tokenId, 1);
    }
  }

  function _mintBatchOfTokenIds(address _to, uint8[] memory _tokenIds, uint8[] memory _amounts) internal {
    require(_tokenIds.length == _amounts.length, "Length of tokenId and amounts must be equal");

    for(uint8 i=0; i<_tokenIds.length; i++ ) {
      _internalMintTokenId(_to, _tokenIds[i], _amounts[i]);
    }
  }

  function _internalMintTokenId(address _to, uint256 tokenId, uint256 _amount) internal {
    require(mintableTokenCount[tokenId] >= _amount, "TokenId not mintable");

    mintableTokenCount[tokenId] -= _amount;
    numTokensMinted += _amount;

    numberOfTokensMintedByAddress[_to] += _amount;
    super._mint(_to, tokenId, _amount, "0x");
  }

  function mintableSupply() public view returns (uint256) {
    return totalTokenSupply - numTokensMinted;
  }

  function tokenIdAtIndex(uint256 index) public view returns (uint256) {
    for(uint256 i = 0; i < mintableTokenCount.length; i++ ) {
      if (index < mintableTokenCount[i]) {
        return i;
      }
      index -= mintableTokenCount[i];
    }
  }
}