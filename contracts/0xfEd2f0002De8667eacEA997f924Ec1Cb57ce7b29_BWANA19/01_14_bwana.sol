// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact [email protected]
contract BWANA19 is ERC721, AccessControl, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;
  string baseURI = "ipfs://QmSeDVwJoTPrVXr624q5t77EQdJBPR2zgc1s55FUpVZnE7/";
  uint256 price = 0.099 ether;
  uint256 qty = 99;

  constructor() ERC721("BWANA19", "BWANA19") {
    _grantRole(DEFAULT_ADMIN_ROLE, 0x0a3C1bA258c0E899CF3fdD2505875e6Cc65928a8);
    transferOwnership(0xee10697780d890eb4e4d46c3925fB62147DC5995);
  }

  function safeMint(address to) public payable {
    require(msg.value == price);
    uint256 tokenId = _tokenIdCounter.current();
    require(tokenId < qty, "Minted out");
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
    (bool result, ) = payable(0xee10697780d890eb4e4d46c3925fB62147DC5995).call{
      value: msg.value
    }("");
    require(result);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    baseURI = uri;
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}