// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./D4AERC721.sol";
import "./interface/ID4AERC721Factory.sol";
import "./utils/DefaultOperatorFiltererUpgradeable.sol";

contract D4AERC721WithFilter is D4AERC721, DefaultOperatorFiltererUpgradeable{
  function initialize(string memory name, string memory symbol) public override initializer {
    __D4AERC721_init(name, symbol);
    __DefaultOperatorFilterer_init();

  }
  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);

  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);

  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
      super.safeTransferFrom(from, to, tokenId, data);
    }

}

contract D4AERC721WithFilterFactory is ID4AERC721Factory{
  using Clones for address;
  D4AERC721 impl;
  event NewD4AERC721WithFilter(address addr);
  constructor() {
    impl = new D4AERC721WithFilter();
  }

  function createD4AERC721(string memory _name, string memory _symbol) public returns(address){
    address t = address(impl).clone();
    D4AERC721WithFilter(t).initialize(_name, _symbol);
    D4AERC721WithFilter(t).changeAdmin(msg.sender);
    D4AERC721WithFilter(t).transferOwnership(msg.sender);
    emit NewD4AERC721WithFilter(t);
    return t;
  }
}