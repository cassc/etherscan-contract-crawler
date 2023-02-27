// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract CryptoHinaDolls is ERC721AQueryable, ERC2981, AccessControl, DefaultOperatorFilterer {
    using Strings for uint256;
    string baseURI = 'https://s3.ap-northeast-1.amazonaws.com/public.cryptohinadolls.com/part1/';

    constructor(address _feereceiver) ERC721A("Crypto-Hina-Dolls", "CHD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        ownerAddress = msg.sender;
        _setDefaultRoyalty(_feereceiver, 500);
    }

    address ownerAddress;

    // URIの設定・変更
    function changeURI(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _uri;
    }

    // royaltyの変更
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // 数量を指定してmint
    function ownerMint(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _safeMint(msg.sender, _amount, '');
    }

    // tokenURIを読まれた時、getURIをよぶ
    function tokenURI(uint256 tokenId)
        public
        view
        override (ERC721A, IERC721A)
        returns(string memory)
    {
        return getURI(tokenId);
    }

    // baseURI + id.jsonを返す。
    function getURI(uint256 tokenId) public view returns(string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    // override
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