// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title: ERC721DelegateAWithRoyalty
/// @author: Pacy

import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "./lib/ERC721MintableUpgradeableAWithRoyalty.sol";
import "./interface/IERC721Delegate.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract ERC721DelegateAWithRoyalty is
    ERC721MintableUpgradeableAWithRoyalty,
    IERC721Delegate,
    DefaultOperatorFiltererUpgradeable
{
    string public baseURI;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) public initializer {
        ERC721Upgradeable.__ERC721_init(name_, symbol_);
        OwnableUpgradeable.__Ownable_init();
        AccessControlUpgradeable.__AccessControl_init();
        AccessControlUpgradeable._setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._setupRole(OPERATOR, msg.sender);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        ERC2981Upgradeable.__ERC2981_init();
        ERC2981Upgradeable._setDefaultRoyalty(
            msg.sender,
            500
        );
        setBaseURI(baseURI_);
    }

    function setBaseURI(string memory baseURI_) public onlyOperator {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
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