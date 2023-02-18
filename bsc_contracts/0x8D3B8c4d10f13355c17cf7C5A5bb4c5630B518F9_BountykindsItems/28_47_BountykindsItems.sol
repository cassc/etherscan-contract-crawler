// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { StringsUpgradeable, ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { ERC721BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import { ERC721EnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import { IBountykindsItems } from "./interfaces/IBountykindsItems.sol";
import { Creator } from "./internal/Creator.sol";
import { Lockable } from "./internal/Lockable.sol";
import { PrimarySale } from "./internal/PrimarySale.sol";
import { NonFungibleType } from "./internal/NonFungibleType.sol";
import { ERC721WithPermit } from "./internal/ERC721WithPermit.sol";
import { ERC721URIStorage } from "./internal/ERC721URIStorage.sol";
import { ERC721TransferFee } from "./internal/ERC721TransferFee.sol";
import { ChainLinkPriceOracle } from "./internal/ChainLinkPriceOracle.sol";
import { Helper } from "./libraries/Helper.sol";
import { CurrencyTransferLib } from "./libraries/CurrencyTransferLib.sol";

import { ReentrancyGuard } from "./utils/ReentrancyGuard.sol";

contract BountykindsItems is
    Creator,
    Lockable,
    PrimarySale,
    NonFungibleType,
    ReentrancyGuard,
    UUPSUpgradeable,
    ERC721WithPermit,
    ERC721URIStorage,
    IBountykindsItems,
    ERC721TransferFee,
    OwnableUpgradeable,
    ChainLinkPriceOracle,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable
{
    using Helper for *;
    using StringsUpgradeable for *;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    address deployer;
    uint256 private _idCounter;
    mapping(uint256 => uint256) private _metadatas;

    modifier onlyUpgrader() {
        if (_msgSender() != deployer) revert NFT__Unauthorized();
        _;
    }

    function initialize(string calldata name_, string calldata symbol_, string calldata baseTokenURI_) external initializer {
        _setBaseURI(baseTokenURI_);
        emit NewBaseTokenURI(baseTokenURI_);

        address sender = _msgSender();
        deployer = sender;

        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ERC721WithPermit_init(name_, symbol_);

        _setCreator(0x250d57521ff5783ab8B69d0fC17d90457ae3caFD);
        _setupPrimarySaleRecipient(0x250d57521ff5783ab8B69d0fC17d90457ae3caFD);
        _setTransferFee(0x250d57521ff5783ab8B69d0fC17d90457ae3caFD, sender, 0);
        _setType(1, address(0), 10_000_000_000_000, 1_000_000, 20);
        _setType(2, address(0), 120_000_000_000, 10, 2);
        _setType(3, address(0), 130_000_000_000, 10, 2);
        _setType(4, address(0), 140_000_000_000, 10, 2);
        _setType(5, address(0), 150_000_000_000, 10, 3);
        _setPriceFeeds(address(0), 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // BNB
        _idCounter = 1;
    }

    function setBaseTokenURI(string calldata baseTokenURI_) external onlyOwner {
        _setBaseURI(baseTokenURI_);
        emit NewBaseTokenURI(baseTokenURI_);
    }

    function _baseURI() internal view virtual override(ERC721Upgradeable, ERC721URIStorage) returns (string memory) {
        return _baseUri;
    }

    function setCreator(address creator_) external override onlyOwner {
        _setCreator(creator_);
    }

    function setPriceFeeds(address token_, address priceFeed_) external onlyOwner {
        _setPriceFeeds(token_, priceFeed_);
    }

    function setTokenPrice(address token_, uint256 tokenPrice_) external onlyOwner {
        _setTokenPrice(token_, tokenPrice_);
    }

    function setupPrimarySaleRecipient(address recipient_) external override onlySale {
        _setupPrimarySaleRecipient(recipient_);
    }

    function setTransferFee(address token_, address beneficiary_, uint256 amount_) external override onlyOwner {
        _setTransferFee(token_, beneficiary_, amount_);
    }

    function setLockUser(address account_, bool status_) external override onlyOwner {
        _setLockUser(account_, status_);
    }

    function setType(uint256 type_, address paymentToken_, uint256 price_, uint256 limit_, uint256 quantity_) external override onlyOwner {
        _setType(type_, paymentToken_, price_, limit_, quantity_);
    }

    function acceptBusinessAddresses(address[] calldata addresses_) external override onlyOwner {
        _acceptBusinessAddresses(addresses_);
    }

    function cancelBusinessAddresses(address[] calldata addresses_) external override onlyOwner {
        _cancelBusinessAddresses(addresses_);
    }

    function buy(uint256 typeNFT_, uint256 quantity_) external payable override nonReentrant {
        address sender = _msgSender();

        _setSold(typeNFT_, quantity_);

        uint256 totalMint = quantity_ * _typeInfo[typeNFT_].quantity;
        uint256 tokenId = _idCounter;
        _batchMint(sender, typeNFT_, tokenId, totalMint);

        TypeInfo memory typeInfo = _typeInfo[typeNFT_];
        uint256 paymentAmount;
        {
            uint256 total = typeInfo.price * quantity_;
            if (total == 0) revert NFT__InvalidType();

            paymentAmount = _getTokenAmountDown(typeInfo.paymentToken, total);

            uint256 refund = msg.value - paymentAmount; // will throw underflow error if value < paymentAmount
            address recipient = _recipient;
            if (typeInfo.paymentToken == address(0)) CurrencyTransferLib.safeTransferNativeToken(recipient, paymentAmount);
            else CurrencyTransferLib.safeTransferERC20(typeInfo.paymentToken, sender, recipient, paymentAmount);

            if (refund == 0) return;

            CurrencyTransferLib.safeTransferNativeToken(sender, refund);
        }

        emit Registered(sender, typeNFT_, tokenId, totalMint, _sold[typeNFT_], typeInfo.paymentToken, paymentAmount);
    }

    function _batchMint(address account_, uint256 typeNFT_, uint256 tokenId_, uint256 totalMint_) internal {
        uint256 creator_ = _creator << 96;

        for (uint256 i; i < totalMint_; ) {
            _safeMint(account_, tokenId_);
            _metadatas[tokenId_] = creator_ | typeNFT_;
        }
        _idCounter = tokenId_;
    }

    function fixOwnerOf(uint256 slot_, uint256[] calldata ids_, address owner_) external onlyOwner {
        uint256 length = ids_.length;

        uint256 creator_ = _creator << 96;
        uint256 id;
        for (uint256 i; i < length; ) {
            id = ids_[i];
            assembly {
                mstore(0, id)
                mstore(32, slot_)
                sstore(keccak256(0, 64), owner_)
            }
            _metadatas[id] = creator_ | 6;
            unchecked {
                ++i;
            }
        }
        // uint256 creator_;
        // creator_ = _creator << 96;

        // assembly {
        //     mstore(32, _metadatas.slot)
        // }

        // for (uint256 i =; i < totalMint_; ) {
        //     assembly {
        //         mstore(0, tokenId_)
        //         sstore(keccak256(0, 64), or(creator_, typeNFT_))
        //         i := add(1, i)
        //         tokenId_ := add(1, tokenId_)
        //     }
        // }
        // _idCounter = tokenId_;
    }

    function recoverToken(address currency_, uint256 amount_) external onlyOwner {
        CurrencyTransferLib.transferCurrency(currency_, address(this), owner(), amount_);
    }

    function metadata(uint256 tokenId_) external view override returns (address owner_, uint256 typeId_) {
        uint256 data = _metadatas[tokenId_];
        unchecked {
            return (data.toAddress({ shifted_: true }), data & ~uint96(0));
        }
    }

    function getTypeNFT(uint256 typeNFT) external view returns (address, uint256, uint256, uint256) {
        return (_typeInfo[typeNFT].paymentToken, _typeInfo[typeNFT].price, _typeInfo[typeNFT].limit, _typeInfo[typeNFT].quantity);
    }

    function getTokenAmount(address paymentToken, uint256 usdAmount) external view returns (uint256) {
        return _getTokenAmountUp(paymentToken, usdAmount);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorage) returns (string memory) {
        _requireMinted(tokenId);

        string memory currentBaseURI = _baseUri;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, "/", address(this).toHexString(), "/", tokenId.toString())) : "";
    }

    function _transfer(address from_, address to_, uint256 tokenId_) internal override(ERC721Upgradeable, ERC721WithPermit) {
        super._transfer(from_, to_, tokenId_);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721TransferFee) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721WithPermit) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address implement_) internal virtual override onlyUpgrader {}

    uint256[47] private __gap;
}