// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable not-rely-on-time, max-states-count

// inheritance list
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "../../lib/TokenHelper.sol";
import "../../interface/other/ITokenWithdraw.sol";
import "../../interface/module/shop/IGameFiShopV1.sol";

// libs
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// interfaces
import "../../interface/core/IGameFiCoreV2.sol";

contract GameFiShopV1 is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    BaseRelayRecipient,
    TokenHelper,
    ITokenWithdraw,
    IGameFiShopV1
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;

    address internal _gameFiCore;

    CountersUpgradeable.Counter internal _totalShops;
    mapping(uint256 => Shop) internal _shops;
    mapping(string => EnumerableSetUpgradeable.UintSet) internal _shopTags;

    modifier onlyAdmin() {
        IGameFiCoreV2(_gameFiCore).isAdmin(_msgSender());
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Constructor method (https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers).
     * @param gameFiCore_ GameFiCore contract address.
     */
    function initialize(address gameFiCore_) external override initializer {
        require(gameFiCore_.isContract(), "GameFiShopV1: gameFiCore must be a contract");

        __ReentrancyGuard_init();
        __ERC721Holder_init();
        __ERC1155Holder_init();
        __TokenHelper_init();

        _gameFiCore = gameFiCore_;
    }

    /**
     * @dev Withdraw stuck tokens.
     * @param standart Withdraw token standard.
     * @param token Withdraw token.
     */
    function withdrawToken(TokenStandart standart, TransferredToken memory token) external override onlyAdmin {
        _tokenTransfer(standart, token, _msgSender());

        emit WithdrawToken({sender: _msgSender(), standart: standart, token: token, timestamp: block.timestamp});
    }

    // TODO порядок методов пересмотреть
    // TODO standart -> standard

    /**
     * @dev Creates a new shop entity.
     * @param newShop New shop data.
     * @return shopId Created shop ID.
     */
    function createShop(Shop memory newShop) external override onlyAdmin returns (uint256 shopId) {
        uint256 newShopId = _totalShops.current();
        _shops[newShopId] = newShop;

        _shopTags[newShop.tag].add(newShopId);

        _totalShops.increment();

        emit CreateShop({sender: _msgSender(), shopId: newShopId, shop: newShop, timestamp: block.timestamp});

        return newShopId;
    }

    /**
     * @dev Edit existing shop entity.
     * @param shopId Target shop id.
     * @param shop New data of the shop.
     */
    function editShop(uint256 shopId, Shop memory shop) external override onlyAdmin {
        _checkShop(shopId);

        _shopTags[_shops[shopId].tag].remove(shopId);
        _shops[shopId] = shop;
        _shopTags[shop.tag].add(shopId);

        emit EditShop({sender: _msgSender(), shopId: shopId, shop: shop, timestamp: block.timestamp});
    }

    /**
     * @dev Execute shop order and make swap.
     * @param shopId Target shop identifier.
     */
    function buyToken(uint256 shopId) external override {
        _buyToken(shopId);
    }

    /**
     * @dev Execute shop order and make swap (batch version).
     * @param shopIds Target shop identifiers.
     */
    function buyTokenBatch(uint256[] memory shopIds) external {
        for (uint256 i = 0; i < shopIds.length; i++) {
            _buyToken(shopIds[i]);
        }
    }

    function _buyToken(uint256 shopId) internal {
        _checkShop(shopId);

        Shop memory shop = _shops[shopId];

        require(shop.status == ShopStatus.OPEN, "GameFiShopV1: shop must be open");

        // swap tokens
        if (shop.tokenInOffer.amount != 0) {
            _tokenTransferFrom(shop.tokenInStandart, shop.tokenInOffer, _msgSender(), address(this));
        }
        _tokenTransferFrom(shop.tokenOutStandart, shop.tokenOutOffer, address(this), _msgSender());

        emit BuyToken({sender: _msgSender(), shopId: shopId, timestamp: block.timestamp});
    }

    /**
     * @dev Returns Shop struct by id.
     * @param shopId Target shop identifier.
     */
    function shopDetails(uint256 shopId) external view override returns (Shop memory) {
        return _shops[shopId];
    }

    /**
     * @dev Returns the number of shops in existence.
     * @return Total number of shops.
     */
    function totalShops() external view override returns (uint256) {
        return _totalShops.current();
    }

    /**
     * @dev Returns the number of shops in existence by tag.
     * @param tag Target tag.
     * @return Total number of shops by tag.
     */
    function totalShopsOfTag(string memory tag) external view returns (uint256) {
        return _shopTags[tag].length();
    }

    /**
     * @dev Returns the shop index by tag and index.
     * @param tag Target tag.
     * @param index Target index.
     * @return shopId Shop id by tag and index.
     */
    function shopOfTagByIndex(string memory tag, uint256 index) external view returns (uint256 shopId) {
        return (_shopTags[tag].at(index));
    }

    /**
     * @dev Returns linked GameFiCore contract.
     * @return GameFiCore address.
     */
    function gameFiCore() external view override returns (address) {
        return _gameFiCore;
    }

    function _checkShop(uint256 shopId) internal view {
        require(shopId < _totalShops.current(), "GameFiShopV1: nonexistent shop");
    }

    //
    // GSN
    //

    /**
     * @dev Sets trusted forwarder contract (see https://docs.opengsn.org/).
     * @param newTrustedForwarder New trusted forwarder contract.
     */
    function setTrustedForwarder(address newTrustedForwarder) external override onlyAdmin {
        _setTrustedForwarder(newTrustedForwarder);
    }

    /**
     * @dev Returns recipient version of the GSN protocol (see https://docs.opengsn.org/).
     * @return Version string in SemVer.
     */
    function versionRecipient() external pure override returns (string memory) {
        return "1.0.0";
    }
}