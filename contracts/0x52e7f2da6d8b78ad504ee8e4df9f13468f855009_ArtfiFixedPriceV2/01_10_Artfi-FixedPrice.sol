// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/Artfi-IMarketplace.sol";
import "./interfaces/Artfi-IManager.sol";
import "./interfaces/Artfi-ICollection.sol";

struct Sale {
    uint256 tokenId;
    address tokenContract;
    uint256 quantity;
    uint256 price;
    address seller;
    uint256 createdAt;
    address buyer;
    uint256 soldAt;
}

struct SellData {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    uint256 quantity;
    uint256 price;
    address seller;
    string currency;
}

struct LazyMintData {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    uint256 quantity;
    uint256 price;
    address seller;
    address buyer;
    string currency;
}

struct BuyNFT {
    uint256 offerId;
    address buyer;
    uint256 quantity;
    uint256 payment;
}

struct Payout {
    address currency;
    address seller;
    address buyer;
    uint256 tokenId;
    address tokenAddress;
    uint256 quantity;
    address[] refundAddresses;
    uint256[] refundAmount;
    bool soldout;
}

/**
 *@title Fixed Price contract.
 *@dev Fixed Price is an implementation contract of initializable contract.
 */
contract ArtfiFixedPriceV2 is Initializable, ReentrancyGuardUpgradeable {
    error GeneralError(string errorCode);

    //*********************** Attaching libraries ***********************//
    // using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    //*********************** Declarations ***********************//
    address private _admin;

    uint256 public constant PERCENT_UNIT = 1e4;

    ArtfiIMarketplace private _marketplace;
    ArtfiIManager private _marketplaceManager;

    mapping(uint256 => Sale) private _sale;
    mapping(uint256 => string) private _saleCurrency;
    mapping(string => bool) private _isSalesupportedTokens;
    string[] private _supportedTokens;

    //*********************** Events ***********************//
    event eFixedPriceSale(
        uint256 offerId,
        uint256 tokenId,
        address contractAddress,
        address owner,
        uint256 quantity,
        uint256 price
    );
    event eUpdateSalePrice(uint256 offerId, uint256 price);
    event eCancelSale(uint256 offerId);
    event ePurchase(
        uint256 offerId,
        address buyer,
        address currency,
        uint256 quantity,
        bool isSaleCompleted
    );

    event ePayoutTransfer(
        address indexed withdrawer,
        uint256 indexed amount,
        address indexed currency
    );

    //*********************** Modifiers ***********************//
    modifier isAdmin() {
        if (msg.sender != _admin) revert GeneralError("AF:101");
        _;
    }

    modifier isArtfiMarketplace() {
        if (msg.sender != address(_marketplace)) revert GeneralError("AF:106");
        _;
    }

    modifier isAdminOrManager() {
        if (msg.sender != _admin && msg.sender != address(_marketplaceManager))
            revert GeneralError("AF:106");
        _;
    }

    //*********************** Admin Functions ***********************//
    /**
     *@notice Initializes the contract by setting address of marketplace and marketplace manager contract
     *@dev used instead of constructor.
     *@param marketplace_ address of marketplace contract.
     *@param marketplaceManager_ address of marketplaceManager contract.
     */

    function initialize(
        address marketplace_,
        address marketplaceManager_,
        uint8 version_
    ) external reinitializer(version_) {
        __ReentrancyGuard_init();
        _marketplace = ArtfiIMarketplace(marketplace_);
        _marketplaceManager = ArtfiIManager(marketplaceManager_);
        _admin = msg.sender;
    }

    /**
     *@notice enables or disables the token for sale .
     *@param tokenName_ name of token.
     *@param enable_ checks the token is enabled.
     */
    function enableDisableSaleToken(
        string memory tokenName_,
        bool enable_
    ) external isAdminOrManager {
        if (!_marketplaceManager.tokenExist(tokenName_))
            revert GeneralError("AF:112");
        if (bytes(tokenName_).length == 0) revert GeneralError("AF:114");
        if (enable_) {
            if (_isSalesupportedTokens[tokenName_] == enable_)
                revert GeneralError("AF:111");
            _isSalesupportedTokens[tokenName_] = enable_;
            _supportedTokens.push(tokenName_);
        } else {
            for (uint256 i = 0; i < _supportedTokens.length; i++) {
                if (
                    keccak256(abi.encodePacked(_supportedTokens[i])) ==
                    keccak256(abi.encodePacked(tokenName_))
                ) {
                    string memory temp = _supportedTokens[i];
                    uint256 lastIndex = _supportedTokens.length - 1;
                    _supportedTokens[i] = _supportedTokens[lastIndex];
                    _supportedTokens[lastIndex] = temp;

                    _supportedTokens.pop();

                    break;
                }
            }
        }
    }

    //*********************** Getter Functions ***********************//

    /**
     *@notice gets details of sale.
     *@param offerId_ offerId of token.
     *@return sale_ contains tokenId,address of tokenContract,quantity of nfts,price,seller address,buyer address,
     *soldQuantity,purchaseQuantity,purchase offer.
     */
    function getSaleDetails(
        uint256 offerId_
    ) external view returns (Sale memory sale_) {
        sale_ = _sale[offerId_];
    }

    function isSaleSupportedTokens(
        string memory tokenName_
    ) external view returns (bool tokenExist_) {
        tokenExist_ = _isSalesupportedTokens[tokenName_];
    }

    //*********************** Setter Functions ***********************//
    /**
     *@notice sells NFT
     *@param tokenId_ Id of token
     *@param tokenAddress_ Address of token
     *@param price_ price of NFT
     *@param quantity_ Quantity of tokens
     *@param currency_ currency used.
     *@return offerId_ OfferId of NFT.
     */
    function sellNft(
        uint256 tokenId_,
        address tokenAddress_,
        uint256 price_,
        uint256 quantity_,
        string calldata currency_
    ) public returns (uint256 offerId_) {
        (ContractType contractType, bool isOwner) = _marketplaceManager
            .isOwnerOfNFT(msg.sender, tokenId_, tokenAddress_);
        if (
            ArtfiIMarketplace.ContractType(uint256(contractType)) ==
            ArtfiIMarketplace.ContractType.UNSUPPORTED
        ) revert GeneralError("AF:118");
        if (_marketplaceManager.isPaused()) revert GeneralError("AF:128");
        if (_marketplaceManager.isBlocked(msg.sender))
            revert GeneralError("AF:126");
        if (!isOwner) revert GeneralError("AF:104");
        if (price_ <= 0) revert GeneralError("AF:302");
        if (quantity_ <= 0) revert GeneralError("AF:303");
        offerId_ = ArtfiIMarketplace(_marketplace).createSale(
            tokenId_,
            ArtfiIMarketplace.ContractType(uint256(contractType)),
            ArtfiIMarketplace.OfferType.SALE
        );

        SellData memory sellData = SellData(
            offerId_,
            tokenId_,
            tokenAddress_,
            quantity_,
            price_,
            msg.sender,
            currency_
        );
        _sell(sellData);
        emit eFixedPriceSale(
            offerId_,
            tokenId_,
            tokenAddress_,
            msg.sender,
            quantity_,
            price_
        );
    }

    // /**
    //  *@notice Mints & Sell NFTs
    //  *@param mintData_ contains uri, creater addresses, royalties percentage, minter address.
    //  *@param price_ price of NFT
    //  *@param currency_ currency used for purchase .
    //  *@return tokenId_ tokenId of NFT
    //  *@return offerId_ offerId of NFT
    //  */
    // function mintSellNft(
    //     ArtfiIMarketplace.MintData memory mintData_,
    //     uint256 price_,
    //     string memory currency_
    // ) external returns (uint256 tokenId_, uint256 offerId_) {
    //     if (_marketplaceManager.isPaused()) revert GeneralError("AF:128");
    //     if (_marketplaceManager.isBlocked(msg.sender))
    //         revert GeneralError("AF:126");
    //     uint256 tokenId = ArtfiIMarketplace(_marketplace).mintNft(mintData_);
    //     tokenId_ = tokenId;

    //     offerId_ = sellNft(
    //         tokenId,
    //         mintData_.tokenAddress,
    //         price_,
    //         mintData_.quantity,
    //         currency_
    //     );
    // }

    /**
     *@notice Updates Price during sale
     *@param offerId_ offerId of NFT
     *@param updatedPrice_ updated price.
     *@param currency_ currency used for purchase.
     */
    function updateSalePrice(
        uint256 offerId_,
        uint256 updatedPrice_,
        string memory currency_
    ) external {
        if (_marketplaceManager.isPaused()) revert GeneralError("AF:128");
        if (_marketplaceManager.isBlocked(msg.sender))
            revert GeneralError("AF:126");
        ArtfiIMarketplace.Offer memory offer = ArtfiIMarketplace(_marketplace)
            .getOfferStatus(offerId_);
        if (offer.offerType != ArtfiIMarketplace.OfferType.SALE)
            revert GeneralError("AF:121");
        if (offer.status != ArtfiIMarketplace.OfferState.OPEN)
            revert GeneralError("AF:301");
        _updateSalePrice(offerId_, currency_, updatedPrice_, msg.sender);
        emit eUpdateSalePrice(offerId_, updatedPrice_);
    }

    /**
     *@notice Cancels Sale of NFT.
     *@param offerId_ OfferId of NFT
     */
    function cancelSale(uint256 offerId_) external {
        if (_marketplaceManager.isPaused()) revert GeneralError("AF:128");
        if (_marketplaceManager.isBlocked(msg.sender))
            revert GeneralError("AF:126");
        if (
            (msg.sender != _sale[offerId_].seller) &&
            (!_marketplaceManager.isAdmin(msg.sender))
        ) revert GeneralError("AF:103");
        ArtfiIMarketplace.Offer memory offer = ArtfiIMarketplace(_marketplace)
            .getOfferStatus(offerId_);
        if (offer.offerType != ArtfiIMarketplace.OfferType.SALE)
            revert GeneralError("AF:121");
        if (offer.status != ArtfiIMarketplace.OfferState.OPEN)
            revert GeneralError("AF:301");
        ArtfiIMarketplace(_marketplace).endSale(
            offerId_,
            ArtfiIMarketplace.OfferState.CANCELLED
        );

        emit eCancelSale(offerId_);
    }

    /**
     *@notice enables the purchase of NFT.
     *@param offerId_ OfferId of NFT.
     */
    function buyNft(uint256 offerId_) external payable nonReentrant {
        if (bytes(_saleCurrency[offerId_]).length == 0) {
            if (_sale[offerId_].price > msg.value)
                revert GeneralError("AF:304");
        }
        if (_marketplaceManager.isPaused()) revert GeneralError("AF:128");
        if (_marketplaceManager.isBlocked(msg.sender))
            revert GeneralError("AF:126");
        ArtfiIMarketplace.Offer memory offer = ArtfiIMarketplace(_marketplace)
            .getOfferStatus(offerId_);
        if (offer.offerType != ArtfiIMarketplace.OfferType.SALE)
            revert GeneralError("AF:121");
        if (offer.status != ArtfiIMarketplace.OfferState.OPEN)
            revert GeneralError("AF:301");
        Payout memory payoutData = _buyNft(
            BuyNFT(offerId_, msg.sender, 1, _sale[offerId_].price)
        );

        _payout(
            ArtfiIMarketplace.Payout(
                payoutData.currency,
                payoutData.refundAddresses,
                payoutData.refundAmount
            )
        );

        ArtfiIMarketplace(_marketplace).transferNFT(
            payoutData.seller,
            payoutData.buyer,
            payoutData.tokenId,
            payoutData.tokenAddress
        );

        if (payoutData.soldout) {
            ArtfiIMarketplace(_marketplace).endSale(
                offerId_,
                ArtfiIMarketplace.OfferState.ENDED
            );
            emit ePurchase(offerId_, msg.sender, payoutData.currency, 1, true);
        } else {
            emit ePurchase(offerId_, msg.sender, payoutData.currency, 1, false);
        }
    }

    // /**
    //  *@notice mints the NFT while purchasing.
    //  *@dev this NFT will be minted to the buyer and the purchase amount will be transferred to the owner.
    //  *@param lazyMintData_ contains contains uri, creater addresses, royalties percentage, minter address,buyer address.
    //  */
    // function lazyMint(
    //     LazyMintData memory lazyMintData_
    // ) external isArtfiMarketplace {
    //     Sale memory sale = _sale[lazyMintData_.offerId];
    //     sale.tokenId = lazyMintData_.tokenId;
    //     sale.tokenContract = lazyMintData_.tokenContract;
    //     sale.quantity = lazyMintData_.quantity;
    //     sale.price = lazyMintData_.price;
    //     sale.seller = lazyMintData_.seller;
    //     sale.createdAt = block.timestamp;
    //     sale.buyer = lazyMintData_.buyer;
    //     sale.soldAt = block.timestamp;

    //     _saleCurrency[lazyMintData_.offerId] = lazyMintData_.currency;

    //     emit eFixedPriceSale(
    //         lazyMintData_.offerId,
    //         lazyMintData_.tokenId,
    //         lazyMintData_.tokenContract,
    //         lazyMintData_.seller,
    //         lazyMintData_.quantity,
    //         lazyMintData_.price
    //     );

    //     emit ePurchase(
    //         lazyMintData_.offerId,
    //         lazyMintData_.buyer,
    //         address(0),
    //         lazyMintData_.quantity,
    //         true
    //     );
    // }

    // function _msgSender()
    //     internal
    //     view
    //     virtual
    //     override(ERC2771Context)
    //     returns (address sender)
    // {
    //     return ERC2771Context._msgSender();
    // }

    // function _msgData()
    //     internal
    //     view
    //     virtual
    //     override(ERC2771Context)
    //     returns (bytes calldata)
    // {
    //     return ERC2771Context._msgData();
    // }

    //*********************** Internal Functions ***********************//
    function _sell(SellData memory sell_) internal {
        _sale[sell_.offerId].tokenId = sell_.tokenId;
        _sale[sell_.offerId].tokenContract = sell_.tokenContract;
        _sale[sell_.offerId].quantity = sell_.quantity;
        _sale[sell_.offerId].price = sell_.price;
        _sale[sell_.offerId].seller = sell_.seller;
        _sale[sell_.offerId].createdAt = block.timestamp;
        _saleCurrency[sell_.offerId] = sell_.currency;
    }

    //Update Price
    function _updateSalePrice(
        uint256 offerId_,
        string memory currency_,
        uint256 updatedPrice_,
        address seller_
    ) internal {
        if (seller_ != _sale[offerId_].seller) revert GeneralError("AF:103");
        _sale[offerId_].price = updatedPrice_;
        _saleCurrency[offerId_] = currency_;
    }

    //Purchase
    function _buyNft(
        BuyNFT memory buyNft_
    ) internal returns (Payout memory payout_) {
        Sale memory sale = _sale[buyNft_.offerId];
        CryptoTokens memory tokenDetails;

        uint256 offerId = buyNft_.offerId;
        // uint256 serviceFee = _percent(
        //   sale.price,
        //   _marketplaceManager.serviceFeePercent()
        // );
        if (bytes(_saleCurrency[buyNft_.offerId]).length == 0) {
            if (buyNft_.payment != ((_sale[offerId].price)))
                revert GeneralError("AF:304");
        } else {
            if (!_isSalesupportedTokens[_saleCurrency[buyNft_.offerId]])
                revert GeneralError("AF:118");
            tokenDetails = _marketplaceManager.getTokenDetail(
                _saleCurrency[buyNft_.offerId]
            );
            uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                .allowance(msg.sender, address(this));
            if (allowance != ((_sale[offerId].price)))
                revert GeneralError("AF:124");

            bool successTransfer = IERC20Upgradeable(tokenDetails.tokenAddress)
                .transferFrom(
                    msg.sender,
                    address(this),
                    (_sale[offerId].price)
                );

            if (!successTransfer) revert GeneralError("AF:130");
        }
        (
            address[] memory recipientAddresses,
            uint256[] memory paymentAmount,
            ,

        ) = _marketplaceManager.calculatePayout(
                CalculatePayout(
                    sale.tokenId,
                    sale.tokenContract,
                    sale.seller,
                    _sale[offerId].price,
                    buyNft_.quantity
                )
            );
        payout_ = Payout(
            tokenDetails.tokenAddress,
            sale.seller,
            buyNft_.buyer,
            sale.tokenId,
            sale.tokenContract,
            1,
            recipientAddresses,
            paymentAmount,
            true
        );
        _sale[buyNft_.offerId].buyer = buyNft_.buyer;
        _sale[buyNft_.offerId].soldAt = block.timestamp;
    }

    function _percent(
        uint256 value_,
        uint256 percentage_
    ) internal pure virtual returns (uint256) {
        uint256 result = (value_ * percentage_) / PERCENT_UNIT;
        return (result);
    }

    function _payout(ArtfiIMarketplace.Payout memory payoutData_) internal {
        for (uint256 i = 0; i < payoutData_.refundAddresses.length; i++) {
            if (payoutData_.refundAddresses[i] != address(0)) {
                if (address(0) == payoutData_.currency) {
                    payable(payoutData_.refundAddresses[i]).sendValue(
                        payoutData_.refundAmounts[i]
                    );
                } else {
                    IERC20Upgradeable(payoutData_.currency).safeTransfer(
                        payoutData_.refundAddresses[i],
                        payoutData_.refundAmounts[i]
                    );
                }
                emit ePayoutTransfer(
                    payoutData_.refundAddresses[i],
                    payoutData_.refundAmounts[i],
                    payoutData_.currency
                );
            }
        }
    }
}