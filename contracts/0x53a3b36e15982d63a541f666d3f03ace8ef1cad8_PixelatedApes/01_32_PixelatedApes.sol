//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./StagedWhitelistUpgradable.sol";
import "./StagedLimitBalanceUpgradable.sol";
import "./BaseUriManagerUpgradable.sol";
import "./royalties/ERC2981ContractWideRoyalties.sol";
import "./CustomPaymentSplitter.sol";

contract PixelatedApes is
    ERC721AUpgradeable,
    StagedWhitelistUpgradable,
    StagedLimitBalanceUpgradable,
    BaseUriManagerUpgradable,
    OwnableUpgradeable,
    ERC2981ContractWideRoyalties
{
    using StringsUpgradeable for uint256;
    using LimitBalances for LimitBalances.Data;

    enum Stage {
        Disabled,
        Vip,
        Whitelist,
        Public
    }

    struct StageConfig {
        Whitelist.Data whitelist;
        LimitBalances.Data limitBalances;
    }

    Stage public stage;
    LimitBalances.Data maxSupply;

    function initialize(
        string memory baseUri_,
        bytes32 vipMerkleTreeRoot_,
        uint256 vipMintLimit_,
        bytes32 whitelistMerkleTreeRoot_,
        uint256 whitelistMintLimit_,
        uint256 publicMintLimit_,
        uint256 maxSupply_,
        address paymentSplitter_
    ) public initializer {
        __ERC721A_init("ThePixelatedApes", "TPA");
        __StagedWhitelist_init_unchained();
        __StagedLimitBalance_init_unchained();
        __BaseUriManager_init_unchained(baseUri_);
        __AdminManager_init_unchained();
        __Ownable_init();
        maxSupply.limit = maxSupply_;
        _setRoyalties(paymentSplitter_, 1000);
        updateMerkleTreeRoot(uint8(Stage.Vip), vipMerkleTreeRoot_);
        updateLimit(uint8(Stage.Vip), vipMintLimit_);
        updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
        updateLimit(uint8(Stage.Whitelist), whitelistMintLimit_);
        updateLimit(uint8(Stage.Public), publicMintLimit_);
    }

    function vipMint(uint256 amount_, bytes32[] calldata proof_) external {
        require(stage == Stage.Vip, "VIP sale not enabled");
        _stageMint(Stage.Vip, amount_, proof_);
    }

    function whitelistMint(uint256 amount_, bytes32[] calldata proof_)
        external
    {
        require(stage == Stage.Whitelist, "Whitelist sale not enabled");
        _stageMint(Stage.Whitelist, amount_, proof_);
    }

    function publicMint(uint256 amount_) external {
        require(stage == Stage.Public, "Public sale not enabled");
        increaseBalance(uint8(Stage.Public), msg.sender, amount_);
        _callMint(msg.sender, amount_);
    }

    function adminMint(
        address[] calldata accounts_,
        uint256[] calldata amounts_
    ) external onlyAdmin {
        uint256 accountsLength = accounts_.length;
        require(accountsLength == amounts_.length, "Bad request");
        for (uint256 i; i < accountsLength; i++) {
            _callMint(accounts_[i], amounts_[i]);
        }
    }

    function setStage(Stage stage_) external onlyAdmin {
        stage = stage_;
    }

    function _stageMint(
        Stage stage_,
        uint256 amount_,
        bytes32[] calldata proof_
    ) private isWhitelisted(uint8(stage_), msg.sender, proof_) {
        increaseBalance(uint8(stage_), msg.sender, amount_);
        _callMint(msg.sender, amount_);
    }

    function _callMint(address account_, uint256 amount_) private {
        require(tx.origin == msg.sender, "No Bots");
        maxSupply.increaseBalance(address(this), amount_);
        _safeMint(account_, amount_);
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

        return string(abi.encodePacked(_baseUri, tokenId.toString(), ".json"));
    }

    function setRoyalties(address recipient, uint256 value) external onlyAdmin {
        _setRoyalties(recipient, value);
    }

     function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Base, ERC721AUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setMaxSupply(uint256 maxSupply_) external onlyAdmin {
        maxSupply.limit = maxSupply_;
    }
}