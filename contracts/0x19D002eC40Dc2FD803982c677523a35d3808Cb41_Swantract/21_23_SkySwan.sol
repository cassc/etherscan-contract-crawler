// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/token/common/ERC2981.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "lib/ERC721A/contracts/ERC721A.sol";
import "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";

error NonExistentToken();
error NotRevealed();
error MaxSupplyReached();

contract SkySwan is ERC721A, ERC2981, Ownable, DefaultOperatorFilterer {

    uint256 constant public MAX_SWAN_SUPPLY = 7777;

    address _royaltyRecipient;

    bool public _reveal = false;

    string _base;
    string _contractURI;

    event Minted(address, uint);

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) {
        _royaltyRecipient = address(this);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentToken();
	// // Show the contract image when the individual swan images are not revealed.
	if (!_reveal) return _contractURI;
        return string(abi.encodePacked(_base, Strings.toString(tokenId)));
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _base = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function safeMint(uint256 quantity) internal {
        if (_totalMinted() >= MAX_SWAN_SUPPLY) revert MaxSupplyReached();
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _safeMint(msg.sender, quantity);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public view override returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        return (_royaltyRecipient, (_salePrice * 1000) / 10000);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
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
        override
	payable
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}