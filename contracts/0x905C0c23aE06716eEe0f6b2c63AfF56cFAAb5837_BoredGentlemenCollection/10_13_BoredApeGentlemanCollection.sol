// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DefaultOperatorFilterer.sol";

contract BoredGentlemenCollection is ERC1155, DefaultOperatorFilterer, Ownable {
  string public name;
  string public symbol;
  uint256 public totalSupply;


  mapping(uint256 => string) public tokenURI;

  constructor() ERC1155("") {
    name = "Bored Gentlemen Collection";
    symbol = "BGC";
  }

  function mint(uint256 _amount, uint256 _tokenId) external onlyOwner {
    _mint(msg.sender, _tokenId, _amount, "");
    totalSupply = totalSupply + _amount;
  }

  function setURI(uint256 _id, string memory _uri) external onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint256 _id) public view override returns (string memory) {
    return tokenURI[_id];
  }

     function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

      function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}