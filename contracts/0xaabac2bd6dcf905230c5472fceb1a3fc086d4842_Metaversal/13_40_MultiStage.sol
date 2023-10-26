//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "../../../supply/SupplyUpgradable.sol";
import "../../../admin-mint/AdminMintUpgradable.sol";
import "../../../whitelist/WhitelistUpgradable.sol";
import "../../../balance-limit/BalanceLimitUpgradable.sol";
import "../../../uri-manager/UriManagerUpgradable.sol";
import "../../../royalties/RoyaltiesUpgradable.sol";
import "../../../price/PriceUpgradable.sol";
import "../../../payments/CustomPaymentSplitterUpgradeable.sol";

contract MultiStage is
    Initializable,
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    SupplyUpgradable,
    AdminMintUpgradable,
    WhitelistUpgradable,
    BalanceLimitUpgradable,
    UriManagerUpgradable,
    RoyaltiesUpgradable,
    PriceUpgradable,
    DefaultOperatorFiltererUpgradeable,
    CustomPaymentSplitterUpgradeable
{
    uint8 public stage;

    function multiStageMint(uint256 amount_, bytes32[] calldata proof_, uint8 stage_)
        external
        payable
        onlyWhitelisted(stage_, msg.sender, proof_)
    {
        require(stage == stage_, "Current stage is not enabled");
        uint8 _stage = uint8(stage_);
        _increaseBalance(_stage, msg.sender, amount_);
        _callMint(msg.sender, amount_);
        _handlePayment(amount_ * price(_stage));
    }

    function publicMint(uint256 amount_)
        external
        payable
    {
        require(stage == 1, "Current stage is not enabled");
        _increaseBalance(1, msg.sender, amount_);
        _callMint(msg.sender, amount_);
        _handlePayment(amount_ * price(1));
    }

    function setStage(uint8 stage_) external onlyAdmin {
        stage = stage_;
    }

    function _callMint(address account_, uint256 amount_)
        internal
        onlyInSupply(amount_)
    {
        require(tx.origin == msg.sender, "No bots");
        _safeMint(account_, amount_);
    }

    function _adminMint(address account_, uint256 amount_) internal override {
        _callMint(account_, amount_);
    }

    function _currentSupply() internal view override returns (uint256) {
        return totalSupply();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
         override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        return _buildUri(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(RoyaltiesUpgradable, ERC721AUpgradeable, IERC721AUpgradeable)
        returns (bool)
    {
        return
            RoyaltiesUpgradable.supportsInterface(interfaceId) ||
            ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}