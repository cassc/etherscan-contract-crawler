// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ERC721A, IERC721A, ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract AmazonksItems is Ownable, Pausable, ERC721A("Amazonks Items", "PRIME"), ERC721AQueryable {
  /* -------------------------------------------------------------------------- */
  /*                                  Variables                                 */
  /* -------------------------------------------------------------------------- */

  // amazonks boxes contract
  address public boxes;

  // metadata baseURI
  string public baseURI;

  // related contracts
  mapping(address => bool) public controllers;

  /* -------------------------------------------------------------------------- */
  /*                                 Constructor                                */
  /* -------------------------------------------------------------------------- */

  constructor(address newBoxes, string memory newBaseURI) {
    boxes = newBoxes;
    baseURI = newBaseURI;
  }

  /* -------------------------------------------------------------------------- */
  /*                                    Sale                                    */
  /* -------------------------------------------------------------------------- */

  function claim(uint256[] calldata ids) external payable {
    IBoxes(boxes).burn(msg.sender, ids);
    super._safeMint(msg.sender, ids.length);
  }

  function burn(address from, uint256[] calldata ids) external {
    require(controllers[msg.sender], "Sender is not a controller");

    for (uint256 i = 0; i < ids.length; i++) {
      require(super.ownerOf(ids[i]) == from, "Sender is not the owner of the token");
      super._burn(ids[i]);
    }
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

  function setBoxes(address newBoxes) external onlyOwner {
    boxes = newBoxes;
  }

  function setPaused() external onlyOwner {
    if (super.paused()) super._unpause();
    else super._pause();
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
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

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
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

interface IBoxes {
  function burn(address from, uint256[] calldata ids) external;
}