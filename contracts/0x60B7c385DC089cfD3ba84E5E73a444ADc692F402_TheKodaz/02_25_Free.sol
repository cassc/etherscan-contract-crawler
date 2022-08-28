//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../../supply/SupplyUpgradable.sol";
import "../../../admin-mint/AdminMintUpgradable.sol";
import "../../../whitelist/WhitelistUpgradable.sol";
import "../../../balance-limit/BalanceLimitUpgradable.sol";
import "../../../uri-manager/UriManagerUpgradable.sol";
import "../../../royalties/RoyaltiesUpgradable.sol";

contract Free is
    Initializable,
    ERC721AUpgradeable,
    OwnableUpgradeable,
    SupplyUpgradable,
    AdminMintUpgradable,
    WhitelistUpgradable,
    BalanceLimitUpgradable,
    UriManagerUpgradable,
    RoyaltiesUpgradable
{
    enum Stage {
        Disabled,
        Whitelist,
        Public
    }

    Stage public stage;

    function whitelistMint(uint256 amount_, bytes32[] calldata proof_)
        external
        onlyWhitelisted(uint8(Stage.Whitelist), msg.sender, proof_)
    {
        require(stage == Stage.Whitelist, "Whitelist sale not enabled");
        _increaseBalance(uint8(Stage.Whitelist), msg.sender, amount_);
        _callMint(msg.sender, amount_);
    }

    function publicMint(uint256 amount_) external {
        require(stage == Stage.Public, "Public sale not enabled");
        _increaseBalance(uint8(Stage.Public), msg.sender, amount_);
        _callMint(msg.sender, amount_);
    }

    function setStage(Stage stage_) external onlyAdmin {
        stage = stage_;
    }

    function _callMint(address account_, uint256 amount_)
        private
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
        override
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
        override(RoyaltiesUpgradable, ERC721AUpgradeable)
        returns (bool)
    {
        return
            RoyaltiesUpgradable.supportsInterface(interfaceId) ||
            ERC721AUpgradeable.supportsInterface(interfaceId);
    }
}