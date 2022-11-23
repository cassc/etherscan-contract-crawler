// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

import './interfaces/IFusion.sol';
import './libs/DefaultOperatorFilterer.sol';

contract Fusion is IFusion, ERC721URIStorage, DefaultOperatorFilterer, Ownable {
    string public baseURI;

    mapping(address => bool) private _operators;

    constructor(string memory baseURI_) ERC721('Infinity NFT', 'INF') {
        baseURI = baseURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(address recipient, uint256 tokenId) external onlyOperator {
        _safeMint(recipient, tokenId);
    }

    modifier onlyOperator() {
        require(_operators[_msgSender()], 'Unauthorized');
        _;
    }

    function setOperators(address[] calldata users, bool remove)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            _operators[users[i]] = !remove;
        }
    }

    function burn(uint256 tokenId) external virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not token owner or approved'
        );
        _burn(tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}