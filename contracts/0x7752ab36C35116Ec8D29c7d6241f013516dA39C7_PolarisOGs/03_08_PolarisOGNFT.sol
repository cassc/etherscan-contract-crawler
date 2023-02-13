// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract PolarisOGs is ERC721A, DefaultOperatorFilterer, Ownable {
	
    string public baseUri;
	
    constructor() ERC721A("PolarisOGs", "POLARISOGS") {}

    function mint(uint256 quantity) external payable onlyOwner {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }
    	
	function setBaseURI(string memory _newURI) public onlyOwner {
        baseUri = _newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
	
	function withdrawAll() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw(uint256 amount) public payable onlyOwner {
        payable(msg.sender).transfer(amount);
    }
    
    function adminBurn(uint256 tokenId) public onlyOwner {
       _burn(tokenId);
    }
	
	/**
	 * 
	 * 		   This contract is configured to use the DefaultOperatorFilterer, which automatically registers the
	 *         token and subscribes it to OpenSea's curated filters.
	 *         Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that
	 *         the msg.sender (operator) is allowed by the OperatorFilterRegistry. Adding the onlyAllowedOperatorApproval
	 *         modifier to the approval methods ensures that owners do not approve operators that are not allowed.
	 */
 
	function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
		payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}