// contracts/SFAirdrop.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract SFAirdrop is ERC721A, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    // addresses
    address _owner;

    // integers
    string private _tokenBaseURI;

    constructor(string memory tokenBaseUri, string memory tokenName, string memory tokenSymbol) ERC721A(tokenName, tokenSymbol) {
        _owner = msg.sender;
        _tokenBaseURI = tokenBaseUri;
    }

    function setBaseUri(string memory tokenBaseUri) external onlyOwner {
        _tokenBaseURI = tokenBaseUri;
    }

    /*
    FUNCTION OVERRIDES
    */

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        payable
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*
    MINTING FUNCTIONS
    */

    /**
     * @dev Public mint function
     */
    function airdrop(address[] calldata recipients) external onlyOwner {
        for(uint i; i < recipients.length;){
            _safeMint(recipients[i], 1);
            unchecked { i++; }
        }
    }

    // Read functions
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenBaseURI;
    }

    /**
     * @dev Withdraw ETH to owner
     */
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }
}