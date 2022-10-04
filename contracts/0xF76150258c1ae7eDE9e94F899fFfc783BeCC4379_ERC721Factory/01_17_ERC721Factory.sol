// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.8 <0.8.10;

import "./ERC721Tradable.sol";
import "./IERC721Tradable.sol";
import "./IERC721Factory.sol";

contract ERC721Factory is IERC721Factory {
  function createERC721(
    string calldata _collectionName,
    string calldata _baseMetadataURI
  ) public override returns (address contractAddress) {
    IERC721Tradable newERC721 = new ERC721Tradable(
      msg.sender,
      _collectionName,
      "WAXNFT",
      _baseMetadataURI
    );
    contractAddress = address(newERC721);
  }
}