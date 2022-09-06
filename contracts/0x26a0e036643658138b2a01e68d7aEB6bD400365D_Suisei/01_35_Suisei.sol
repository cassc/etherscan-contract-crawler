//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@divergencetech/ethier/contracts/thirdparty/opensea/OpenSeaGasFreeListing.sol";
import "./supply/SupplyUpgradable.sol";
import "./admin-mint/AdminMintUpgradable.sol";
import "./whitelist/WhitelistUpgradable.sol";
import "./balance-limit/BalanceLimitUpgradable.sol";
import "./uri-manager/UriManagerUpgradable.sol";
import "./royalties/RoyaltiesUpgradable.sol";
import "./price/PriceUpgradable.sol";
import "./CustomPaymentSplitterUpgradeable.sol";
import "./ISuseiStaking.sol";

contract Suisei is
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
    CustomPaymentSplitterUpgradeable
{
    enum Stage {
        Disabled,
        Vip,
        Whitelist,
        Public
    }

    Stage public stage;
    ISuseiStaking public staking;

    function initialize(
        string memory uriPrefix_,
        string memory uriSuffix_,
        uint256 maxSupply_,
        bytes32 whitelistMerkleTreeRoot_,
        uint256 whitelistMintLimit_,
        bytes32 vipMerkleTreeRoot_,
        uint256 vipMintLimit_,
        uint256 publicMintLimit_,
        address royaltiesRecipient_,
        uint256 royaltiesValue_,
        address[] memory shareholders_,
        uint256[] memory shares_
    ) public initializerERC721A initializer {
        __ERC721A_init("Suisei Pioneers", "SUI-PIO");
        __Ownable_init();
        __AdminManager_init_unchained();
        __Supply_init_unchained(maxSupply_);
        __AdminMint_init_unchained();
        __Whitelist_init_unchained();
        __Price_init_unchained();
        __BalanceLimit_init_unchained();
        __UriManager_init_unchained(uriPrefix_, uriSuffix_);
        __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
        __CustomPaymentSplitter_init(shareholders_, shares_);
        updateMerkleTreeRoot(uint8(Stage.Vip), vipMerkleTreeRoot_);
        updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
        updateBalanceLimit(uint8(Stage.Vip), vipMintLimit_);
        updateBalanceLimit(uint8(Stage.Whitelist), whitelistMintLimit_);
        updateBalanceLimit(uint8(Stage.Public), publicMintLimit_);
        setPrice(uint8(Stage.Whitelist), 0.18 ether);
        setPrice(uint8(Stage.Public), 0.28 ether);
    }

    function isApprovedForAll(address owner_, address operator_)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (bool)
    {
        return
            super.isApprovedForAll(owner_, operator_) ||
            OpenSeaGasFreeListing.isApprovedForAll(owner_, operator_) ||
            msg.sender == address(staking);
    }

    function vipMint(
        uint256 amount_,
        bytes32[] calldata proof_,
        bool stake_
    ) external onlyWhitelisted(uint8(Stage.Vip), msg.sender, proof_) {
        require(stage == Stage.Whitelist, "Whitelist sale not enabled");
        _increaseBalance(uint8(Stage.Vip), msg.sender, amount_);
        _handleIfStaking(amount_, stake_);
    }

    function wlMint(
        uint256 amount_,
        bytes32[] calldata proof_,
        bool stake_
    )
        external
        payable
        onlyWhitelisted(uint8(Stage.Whitelist), msg.sender, proof_)
    {
        require(stage == Stage.Whitelist, "Whitelist sale not enabled");
        uint8 _stage = uint8(Stage.Whitelist);
        _increaseBalance(_stage, msg.sender, amount_);
        _handleIfStaking(amount_, stake_);
        _handlePayment(amount_ * price(_stage));
    }

    function publicMint(uint256 amount_, bool stake_) external payable {
        require(stage == Stage.Public, "Public sale not enabled");
        uint8 _stage = uint8(Stage.Public);
        _increaseBalance(_stage, msg.sender, amount_);
        _handleIfStaking(amount_, stake_);
        _handlePayment(amount_ * price(_stage));
    }

    function setStage(Stage stage_) external onlyAdmin {
        stage = stage_;
    }

    function _handleIfStaking(uint256 amount_, bool stake_) internal {
        address recipient = msg.sender;
        if (stake_) {
            recipient = address(staking);
            uint256 start = _nextTokenId();
            uint256[] memory arr = new uint256[](amount_);
            for (uint256 i; i < amount_; i++) {
                arr[i] = start + i;
            }
            staking.stakeFor(arr, msg.sender);
        }
        _callMint(recipient, amount_);
    }

    function _startTokenId()
        internal
        pure
        override(ERC721AUpgradeable)
        returns (uint256)
    {
        return 1;
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
        override(ERC721AUpgradeable)
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

    function setStaking(ISuseiStaking staking_) external onlyAdmin {
        staking = staking_;
    }
}