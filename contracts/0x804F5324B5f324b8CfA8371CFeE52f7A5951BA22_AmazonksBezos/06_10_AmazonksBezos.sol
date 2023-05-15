// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ERC721A, IERC721A, ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract AmazonksBezos is Ownable, Pausable, ERC721A("Amazonks Beezos", "BEZOS"), ERC721AQueryable {
  using Strings for uint256;

  /* -------------------------------------------------------------------------- */
  /*                                  Variables                                 */
  /* -------------------------------------------------------------------------- */

  address public items; // amazonks items contract

  string public unrevealedURI; // metadata unrevealedURI

  string public baseURI; // metadata baseURI

  mapping(address => bool) public controllers;

  /* -------------------------------------------------------------------------- */
  /*                                 Constructor                                */
  /* -------------------------------------------------------------------------- */

  constructor(address newItems, string memory newUnrevealedURI) {
    items = newItems;
    unrevealedURI = newUnrevealedURI;
  }

  /* -------------------------------------------------------------------------- */
  /*                                    Sale                                    */
  /* -------------------------------------------------------------------------- */

  function claim(uint256[] calldata ids) external payable {
    require(ids.length % 2 == 0, "Not an even number of items");

    IItems(items).burn(msg.sender, ids);
    super._safeMint(msg.sender, ids.length / 2);
  }

  function totalMinted() public view returns (uint256) {
    return super._totalMinted();
  }

  function totalBurned() public view returns (uint256) {
    return super._totalBurned();
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Maintenance                                */
  /* -------------------------------------------------------------------------- */

  function setItems(address newItems) external onlyOwner {
    items = newItems;
  }

  function setPaused() external onlyOwner {
    if (super.paused()) super._unpause();
    else super._pause();
  }

  function setUnrevealedURI(string memory newUnrevealedURI) external onlyOwner {
    unrevealedURI = newUnrevealedURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    delete unrevealedURI;
    baseURI = newBaseURI;
  }

  function setControllers(address[] calldata addrs, bool state) external onlyOwner {
    for (uint256 i; i < addrs.length; i++) controllers[addrs[i]] = state;
  }

  /* -------------------------------------------------------------------------- */
  /*                                  Overrides                                 */
  /* -------------------------------------------------------------------------- */

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
    require(super._exists(tokenId), "ERC721Metadata: query for nonexisting tokenId");
    return bytes(unrevealedURI).length > 0 ? unrevealedURI : string(abi.encodePacked(baseURI, tokenId.toString()));
  }

  function isApprovedForAll(address _owner, address operator) public view override(ERC721A, IERC721A) returns (bool) {
    return controllers[operator] || super.isApprovedForAll(_owner, operator);
  }

  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override whenNotPaused {}

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}

interface IItems {
  function burn(address from, uint256[] calldata ids) external;
}