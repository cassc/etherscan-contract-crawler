// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract zoomanXkumapi is ERC721AQueryable, ERC2981, AccessControl, DefaultOperatorFilterer {
    using Strings for uint256;
    string baseURI;

    constructor(address _feereceiver, string memory _baseURI) ERC721A("zoo-manXkumapi", "zoo-manXkumapi") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setDefaultRoyalty(_feereceiver, 1000);
        baseURI = _baseURI;
    }

    function changeRoyalty(address _receiver, uint96 _feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function ownerMint(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _safeMint(msg.sender, _amount, '');
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override (ERC721A, IERC721A)
        returns(string memory)
    {
        return getURI(tokenId);
    }

    function getURI(uint256 tokenId) public view returns(string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A,ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) payable {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperator(from) payable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
        payable
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}