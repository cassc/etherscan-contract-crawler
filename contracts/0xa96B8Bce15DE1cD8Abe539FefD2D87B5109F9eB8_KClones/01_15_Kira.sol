// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
contract KClones is ERC721, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 5000;
    uint256 private _currentId;

    string public baseURI;

    constructor(
        string memory _initialBaseURI
    ) ERC721("KClones", "KClones") {
        baseURI = _initialBaseURI;
    }

    function totalSupply() public view returns (uint256) {
        return _currentId;
    }

    function currentSupply() external view returns (uint) {
        return _currentId;
    }
    // Accessors

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory base = _baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString()))
                : "";
    }
    // Metadata

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function ownerMint(address to, uint256 amount) public onlyOwner {
        _internalMint(to, amount);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function saveTokens(
        IERC20 tokenAddress,
        uint256 amount
    ) external onlyOwner {

        tokenAddress.transfer(owner(), amount);
    }

    function _internalMint(address to, uint256 amount) private {
        require(
            _currentId + amount <= MAX_SUPPLY,
            "Will exceed maximum supply"
        );

        for (uint256 i = 1; i <= amount; i++) {
            _currentId++;
            _safeMint(to, _currentId);
        }
    }

    function airdropNfts(address[] memory recipients) public onlyOwner {
        require(_currentId + recipients.length <= MAX_SUPPLY, "Will exceed maximum supply");
        for (uint256 i; i < recipients.length;) {
            _currentId++;
            _mintLowerGas(recipients[i], _currentId);
            unchecked {
                ++i;
            }
        }
    }

    // OpenSea Operator Filter Registry Functions https://github.com/ProjectOpenSea/operator-filter-registry
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
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
    // End Opensea Operator Filter Registry
}