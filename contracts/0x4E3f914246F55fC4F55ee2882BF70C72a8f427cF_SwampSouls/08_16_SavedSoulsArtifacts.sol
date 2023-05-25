// SPDX-License-Identifier: None

pragma solidity ^0.8.19;

import {ERC1155} from "solady/src/tokens/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SavedSoulsArtifacts is ERC1155, Ownable {
  string public tokenBaseUri = "";

  constructor(address deployer) {
    _transferOwnership(deployer);
  }

  function burn(address from, uint256 id, uint256 amount) external {
    if (msg.sender != from && !isApprovedForAll(from, msg.sender))
      revert NotOwnerNorApproved();

    _burn(from, id, amount);
  }

  function uri(
    uint256 id
  ) public view virtual override(ERC1155) returns (string memory) {
    return string(abi.encodePacked(tokenBaseUri, id));
  }

  function setBaseUri(string memory newBaseUri) public onlyOwner {
    tokenBaseUri = newBaseUri;
  }

  function mintBatch(
    address[] calldata to,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external onlyOwner {
    if (to.length != ids.length) revert ArrayLengthsMismatch();
    if (to.length != amounts.length) revert ArrayLengthsMismatch();

    for (uint256 i = 0; i < to.length; ) {
      _mint(to[i], ids[i], amounts[i], "");

      unchecked {
        ++i;
      }
    }
  }
}