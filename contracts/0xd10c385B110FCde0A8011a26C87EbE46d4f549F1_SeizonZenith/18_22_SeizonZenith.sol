// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@chocolate-factory/contracts/admin-manager/AdminManagerUpgradable.sol";
import "@chocolate-factory/contracts/admin-mint/AdminMintUpgradable.sol";
import "@chocolate-factory/contracts/uri-manager/UriManagerUpgradable.sol";
import "@chocolate-factory/contracts/royalties/RoyaltiesUpgradable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract SeizonZenith is
    Initializable,
    OwnableUpgradeable,
    ERC1155Upgradeable,
    AdminMintUpgradable,
    RoyaltiesUpgradable,
    DefaultOperatorFiltererUpgradeable
{
    string public constant name = "SEIZON - ZENITH";

    function initialize(
        address royaltiesRecipient_,
        uint256 royaltiesValue_,
        string calldata uri_
    ) public initializer {
        __Ownable_init_unchained();
        __ERC1155_init_unchained(uri_);
        __AdminManager_init_unchained();
        __AdminMint_init_unchained();
        __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
        __DefaultOperatorFilterer_init();
    }

    function _adminMint(address account_, uint256 amount_) internal override {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 1;
        amounts[0] = amount_;
        _mintBatch(account_, ids, amounts, "");
    }

    function setURI(string calldata uri_) external onlyAdmin {
        _setURI(uri_);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(RoyaltiesUpgradable, ERC1155Upgradeable)
        returns (bool)
    {
        return
            RoyaltiesUpgradable.supportsInterface(interfaceId) ||
            ERC1155Upgradeable.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
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