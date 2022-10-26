// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Airdrop.sol";


contract MarketResearch000 is ERC721Airdrop {
  address private _owner;
  constructor() ERC721Airdrop("DidYouSeeThis?", "DIDUC") {
    _owner = msg.sender;
  }

  function bulkMint(address[] calldata receivers, uint256 startTokenId) public {
    require(_owner == msg.sender, "not contract owner");
    _bulkMint(receivers, startTokenId);
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return "https://nft.didyouseethis.xyz/campaigns/000/metadata/";
  }
}