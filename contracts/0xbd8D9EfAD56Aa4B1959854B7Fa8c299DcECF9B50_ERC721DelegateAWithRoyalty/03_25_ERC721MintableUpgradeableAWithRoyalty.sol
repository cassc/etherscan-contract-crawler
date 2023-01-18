// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "../interface/IERC721MintableUpgradeableWithRoyalty.sol";

abstract contract ERC721MintableUpgradeableAWithRoyalty is
    ERC721EnumerableUpgradeable,
    IERC721MintableUpgradeableWithRoyalty,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC2981Upgradeable
{
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    function addOperator(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(OPERATOR, account);
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR, msg.sender), "Must be operator");
        _;
    }

    function exists(uint256 tokenId) public view override returns (bool) {
        return super._exists(tokenId);
    }

    function mint(address to, uint256 tokenId)
        public
        virtual
        override
        onlyOperator
    {
        super._mint(to, tokenId);
    }

    function bulkMint(address[] memory _tos, uint256[] memory _tokenIds)
        public
        onlyOperator
    {
        require(_tos.length == _tokenIds.length);
        uint8 i;
        for (i = 0; i < _tos.length; i++) {
            mint(_tos[i], _tokenIds[i]);
        }
    }

    function setDefaultRoyalty(
        address royaltyReceiver_,
        uint96 royaltyFraction_
    ) external onlyOperator {
        super._setDefaultRoyalty(royaltyReceiver_, royaltyFraction_);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOperator {
        super._setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable,
            ERC2981Upgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}