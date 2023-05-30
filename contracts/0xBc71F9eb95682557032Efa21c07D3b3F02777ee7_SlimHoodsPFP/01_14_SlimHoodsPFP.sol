// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**

  .d88888b  dP oo            dP     dP                          dP
  88.    "' 88               88     88                          88
  `Y88888b. 88 dP 88d8b.d8b. 88aaaaa88a .d8888b. .d8888b. .d888b88 .d8888b.
        `8b 88 88 88'`88'`88 88     88  88'  `88 88'  `88 88'  `88 Y8ooooo.
  d8'   .8P 88 88 88  88  88 88     88  88.  .88 88.  .88 88.  .88       88
   Y88888P  dP dP dP  dP  dP dP     dP  `88888P' `88888P' `88888P8 `88888P'

  Hi fren!

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721Wrapper.sol";

contract SlimHoodsPFP is ERC721Wrapper, ERC2981, Ownable {
  string public baseURI;

  constructor(
    address slimHoodsAddr,
    string memory initialBaseURI,
    address payable royaltiesReceiver
  ) ERC721Wrapper("SlimHoods PFP", "SLMHDS-PFP", slimHoodsAddr) {
    baseURI = initialBaseURI;
    setRoyaltyInfo(royaltiesReceiver, 500);
  }

  // Accessors

  function setBaseURI(string calldata uri) public onlyOwner {
    baseURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  // Wraps

  function wrap(uint256 id) public {
    _wrap(id);
  }

  function unwrap(uint256 id) public {
    _unwrap(id);
  }

  function exists(uint256 id) public view returns (bool) {
    return _exists(id);
  }

  function rescueSlimHood(uint256 id, address destination) public onlyOwner {
    collection.safeTransferFrom(address(this), destination, id);
  }

  // IERC2981

  function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
    _setDefaultRoyalty(receiver, numerator);
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}