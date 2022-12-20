// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./SignedTokenVerifier.sol";
import "./ReentrancyGuard.sol";
import "./DefaultOperatorFilterer.sol";
import "./ERC2981.sol";

abstract contract AbstractERC1155Factory is Pausable, ERC1155Supply, ERC1155Burnable, Ownable, SignedTokenVerifier, ReentrancyGuard, DefaultOperatorFilterer, ERC2981 {

    string name_;
    string symbol_;   

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }    

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }    

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }         

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }  

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
    return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
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