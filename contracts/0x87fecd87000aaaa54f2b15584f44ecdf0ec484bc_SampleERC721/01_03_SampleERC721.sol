// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "openzepplin/utils/Strings.sol";

// Test contract for anyone to mint/burn just used for testing.
contract SampleERC721 is ERC721 {
  constructor() ERC721("Doodles Clone", "DOOD") {
  }

  function tokenURI(uint256 id) public pure override returns (string memory) {
    return string.concat("ipfs://QmPMc4tcBsMqLRuCQtPmPe84bpSjrC3Ky7t3JWuHXYB4aS/", Strings.toString(id));
  }

  function mint(address to, uint id) public {
    _mint(to, id);
  }

  function burn(uint id) public {
    _burn(id);
  }
}