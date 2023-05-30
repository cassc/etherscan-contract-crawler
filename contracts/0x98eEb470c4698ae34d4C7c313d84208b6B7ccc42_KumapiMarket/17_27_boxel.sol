// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract zoomanXsasayon is ERC1155, AccessControl, ERC2981, DefaultOperatorFilterer {
    using Strings for uint256;
    bytes32 MINTER_ROLE = keccak256('MINTER_ROLE');
    string baseURI;

    constructor(string memory _baseURI) ERC1155("zoomanXsasayon") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        baseURI = _baseURI;
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function changeRoyalty(address _receiver, uint96 _feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function changeURI(string memory _baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    function mint(uint256 _tokenId, address _to) public onlyRole(MINTER_ROLE) {
        _mint(_to, _tokenId, 1, "");
    }

    function uri(uint256 tokenId)
        public
        view
        override
        returns(string memory)
    {
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}