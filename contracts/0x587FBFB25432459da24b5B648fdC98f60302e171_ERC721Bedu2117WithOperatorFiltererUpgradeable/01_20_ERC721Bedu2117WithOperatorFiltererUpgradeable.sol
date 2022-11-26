// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ERC721Bedu2117Upgradeable.sol";
import "./opensea/DefaultOperatorFiltererUpgradeable.sol";

contract ERC721Bedu2117WithOperatorFiltererUpgradeable is Initializable, ERC721Bedu2117Upgradeable, DefaultOperatorFiltererUpgradeable {
    string private _testURI;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory defaultURI_,
        string memory mainURI_
    ) public override virtual initializer {
        __ERC721Bedu2117_init(name_, symbol_, defaultURI_, mainURI_);
        __DefaultOperatorFilterer_init();
    }

    function setApprovalForAll(
        address operator_,
        bool approved_
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperatorApproval(operator_) {
        super.setApprovalForAll(operator_, approved_);
    }

    function approve(
        address operator_,
        uint256 tokenId_
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperatorApproval(operator_) {
        super.approve(operator_, tokenId_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from_) {
        super.transferFrom(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from_) {
        super.safeTransferFrom(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from_) {
        super.safeTransferFrom(from_, to_, tokenId_, data_);
    }
}