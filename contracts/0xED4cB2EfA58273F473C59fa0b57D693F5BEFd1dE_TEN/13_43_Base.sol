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
import "./interfaces/IBase.sol";

contract Base is
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
    CustomPaymentSplitterUpgradeable,
    IBase
{
    uint8 public stage;

    function __Base_init(Args memory args) internal initializer initializerERC721A  {
        __ERC721A_init(args.tokenConfig.name, args.tokenConfig.symbol);
         __DefaultOperatorFilterer_init();
        __Ownable_init();
        __AdminManager_init_unchained();
        __Supply_init_unchained(args.tokenConfig.supply);
        __AdminMint_init_unchained();
        __Whitelist_init_unchained();
        __BalanceLimit_init_unchained();
        __UriManager_init_unchained(
            args.tokenConfig.prefix,
            args.tokenConfig.suffix
        );
        __CustomPaymentSplitter_init(args.payees, args.shares);
        __Royalties_init_unchained(args.royaltiesRecipient, args.royaltyValue);

        for(uint256 i; i < args.stages.length; i++) {
            StageConfig memory stage = args.stages[i];
            uint8 index = uint8(i) + 1;
            if(stage.price > 0) setPrice(index, stage.price);
            if(stage.limit > 0) updateBalanceLimit(index, stage.limit);
            if(stage.merkleTreeRoot != bytes32(0)) updateMerkleTreeRoot(index, stage.merkleTreeRoot);
        }
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

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public  virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}