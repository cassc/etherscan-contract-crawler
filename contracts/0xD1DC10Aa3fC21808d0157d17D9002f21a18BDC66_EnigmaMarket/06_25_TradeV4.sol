// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../utils/AuthorizationBitmap.sol";
import "../utils/Types.sol";
import "../interfaces/ITransferProxy.sol";
import "../interfaces/IRoyaltyAwareNFT.sol";
import "../utils/BlockchainUtils.sol";
import "./utils/PlatformFees.sol";

/// @title TradeV4
///
/// @dev This contract is a Transparent Upgradable based in openZeppelin v3.4.0.
///         Be careful when upgrade, you must respect the same storage.

abstract contract TradeV4 is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    enum AssetType { ERC1155, ERC721 }

    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event CustodialAddressChanged(address prevAddress, address newAddress);
    event BuyAsset(address indexed assetOwner, uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event ExecuteBid(address indexed assetOwner, uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event TokenWithdraw(address indexed assetOwner, uint256 indexed authId, uint256 indexed tokenId, uint256 quantity);

    /// @dev deprecated
    uint8 internal _buyerFeePermille;
    /// @dev deprecated
    uint8 internal _sellerFeePermille;
    ITransferProxy public transferProxy;
    address public enigmaNFT721Address;
    address public enigmaNFT1155Address;
    // Address that acts as custodial for platform hold NFTs,
    address public custodialAddress;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // This is a packed array of booleans, to track processed authorizations
    mapping(uint256 => uint256) internal processedAuthorizationsBitMap;

    struct FeeDistributionData {
        uint256 toRightsHolder; // Amount of tokens/ethers that will be sent to the rights holder(royalty receiver)
        uint256 toSeller; // Amount of tokens/ethers that will be sent to the seller
        address rightsHolder; // Rights holder address(tipically the creator, or a smart contract that splits the fees)
        Fees fees;
    }

    /// @notice Struct that contains all the fees of a given sale
    struct Fees {
        uint256 platformFee; // Sum of buyerFee + sellerFee, this is what the platform charges for a sale
        // Amount sent - royalty - platformFee, this is what is left after fees are
        // taken(usually goes to the seller unless this is a primary sale)
        uint256 assetFee;
        uint256 royaltyFee; // Royalty fee (could be split or not), it is intended to go to the artist/creator
        uint256 price; // Amount sent - buyerFee, it should be the price that the seller set on the asset
    }

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        AssetType nftType;
        uint256 unitPrice;
        uint256 amount;
        uint256 tokenId;
        uint256 qty;
    }

    struct WithdrawRequest {
        uint256 authId; // Unique id for this withdraw authorization
        address assetAddress;
        AssetType assetType;
        uint256 tokenId;
        uint256 qty;
    }

    function initializeTradeV4(
        ITransferProxy _transferProxy,
        address _enigmaNFT721Address,
        address _enigmaNFT1155Address,
        address _custodialAddress
    ) internal initializer {
        transferProxy = _transferProxy;
        enigmaNFT721Address = _enigmaNFT721Address;
        enigmaNFT1155Address = _enigmaNFT1155Address;
        custodialAddress = _custodialAddress;
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setCustodialAddress(address _custodialAddress) external onlyOwner returns (bool) {
        emit CustodialAddressChanged(custodialAddress, _custodialAddress);
        custodialAddress = _custodialAddress;
        return true;
    }

    function verifySellerSignature(
        address seller,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint8 sellerFeePermile,
        Signature memory signature
    ) internal pure {
        bytes32 hash =
            keccak256(
                abi.encodePacked(
                    BlockchainUtils.getChainID(),
                    assetAddress,
                    tokenId,
                    paymentAssetAddress,
                    amount,
                    sellerFeePermile
                )
            );
        require(seller == BlockchainUtils.getSigner(hash, signature), "seller sign verification failed");
    }

    /**
     * @notice Verifies the custodial authorization for this withdraw for this assetOwner
     * @param assetCustodial current asset holder
     * @param assetOwner real asset owner address
     * @param wr struct with the withdraw information. What asset and how much of it
     * @param signature struct combination of uint8, bytes32, bytes32 are v, r, s.
     */
    function verifyWithdrawSignature(
        address assetCustodial,
        address assetOwner,
        WithdrawRequest memory wr,
        Signature memory signature
    ) internal pure {
        bytes32 hash =
            keccak256(
                abi.encodePacked(
                    BlockchainUtils.getChainID(),
                    assetOwner,
                    wr.authId,
                    wr.tokenId,
                    wr.assetAddress,
                    wr.qty
                )
            );
        require(assetCustodial == BlockchainUtils.getSigner(hash, signature), "withdraw sign verification failed");
    }

    /**
     * @notice Calculates fees of an operation from the paymentAmount as well as ask for the royalty fees receiver
     * because it is part of the ERC2981 standard
     * @param paymentAmt Amount that the user sent(NOT the price, it is the price + buyer fee)
     * @param buyingAssetAddress the token symbol
     * @param tokenId Token id of the token being sold
     * @param sellerFeePermille Seller fee in Permille(unit per thousand of the total)
     * @param buyerFeePermille Buyer fee in Permille(unit per thousand of the total)
     */
    function calculateFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        uint256 sellerFeePermille,
        uint256 buyerFeePermille
    ) internal view virtual returns (address, Fees memory) {
        Fees memory fees;
        address royaltyFeeReceiver;
        uint256 price = paymentAmt.mul(1000).div((1000 + buyerFeePermille));
        uint256 buyerFee = paymentAmt.sub(price);
        uint256 sellerFee = price.mul(sellerFeePermille).div((1000));
        fees.platformFee = buyerFee.add(sellerFee);

        bool success = IERC165Upgradeable(buyingAssetAddress).supportsInterface(_INTERFACE_ID_ERC2981);
        if (success) {
            (royaltyFeeReceiver, fees.royaltyFee) = IERC2981(buyingAssetAddress).royaltyInfo(tokenId, price);
        } else {
            fees.royaltyFee = 0;
        }
        fees.assetFee = price.sub(sellerFee).sub(fees.royaltyFee);
        fees.price = price;
        return (royaltyFeeReceiver, fees);
    }

    /**
     * @notice Calculates fees of an operation from the paymentAmount and to whom we should distribute it too
     *
     * @param paymentAmt Amount that the user sent(NOT the price, it is the price + buyer fee)
     * @param buyingAssetAddress the token symbol
     * @param tokenId Token id of the token being sold
     * @param sellerFeePermille Seller fee in Permille(unit per thousand of the total)
     * @param buyerFeePermille Buyer fee in Permille(unit per thousand of the total)
     * @param seller Address of the seller
     */
    function getFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        uint256 sellerFeePermille,
        uint256 buyerFeePermille,
        address seller
    ) internal view virtual returns (FeeDistributionData memory) {
        (address royaltyFeesReceiver, Fees memory fees) =
            calculateFees(paymentAmt, buyingAssetAddress, tokenId, sellerFeePermille, buyerFeePermille);
        uint256 toRightsHolder = 0;
        uint256 toSeller = 0;
        bool isPrimarySale;

        try IRoyaltyAwareNFT(buyingAssetAddress).getCreator(tokenId) returns (address creator) {
            isPrimarySale = creator == seller;
        } catch {
            // We are not sure as this is probably an external token, we would take the safe path here
            isPrimarySale = false;
        }

        if (isPrimarySale) {
            toRightsHolder = fees.royaltyFee.add(fees.assetFee);
            // seller receives 0 in this case as all of it is split using the rightsHolder
        } else {
            toSeller = fees.assetFee;
            toRightsHolder = fees.royaltyFee; // This might be 0
        }

        return
            FeeDistributionData({
                toRightsHolder: toRightsHolder,
                toSeller: toSeller,
                rightsHolder: royaltyFeesReceiver,
                fees: fees
            });
    }

    function getFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        address seller,
        PlatformFees calldata platformFees
    ) internal returns (FeeDistributionData memory) {
        require(tokenId == platformFees.tokenId, "TokenId mismatch");
        require(buyingAssetAddress == platformFees.assetAddress, "Asset address mismatch");
        PlatformFeesFunctions.checkValidPlatformFees(platformFees, owner());

        return
            getFees(
                paymentAmt,
                buyingAssetAddress,
                tokenId,
                platformFees.sellerFeePermille,
                platformFees.buyerFeePermille,
                seller
            );
    }

    function tradeNFT(Order memory order) internal virtual {
        safeTransferFrom(order.nftType, order.seller, order.buyer, order.nftAddress, order.tokenId, order.qty);
    }

    function safeTransferFrom(
        AssetType nftType,
        address from,
        address to,
        address nftAddress,
        uint256 tokenId,
        uint256 qty
    ) internal virtual {
        nftType == AssetType.ERC721
            ? transferProxy.erc721safeTransferFrom(nftAddress, from, to, tokenId)
            : transferProxy.erc1155safeTransferFrom(nftAddress, from, to, tokenId, qty, "");
    }

    /**
     * @dev Disable slither warning because there is a nonReentrant check and the address are known
     * https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
     */
    function tradeAssetWithETH(Order memory order, FeeDistributionData memory feeDistributionData) internal virtual {
        tradeNFT(order);
        if (feeDistributionData.fees.platformFee > 0) {
            // TODO: review if we don't need a new field for collecting fees
            // slither-disable-next-line arbitrary-send
            (bool platformSuccess, ) = owner().call{ value: feeDistributionData.fees.platformFee }("");
            require(platformSuccess, "sending ETH to owner failed");
        }

        if (feeDistributionData.toRightsHolder > 0) {
            // TODO: can we trust this new address? don't we need some reentrancy checksor something else?
            // slither-disable-next-line arbitrary-send
            (bool royaltySuccess, ) =
                feeDistributionData.rightsHolder.call{ value: feeDistributionData.toRightsHolder }("");
            require(royaltySuccess, "sending ETH to creator failed");
        }

        if (feeDistributionData.toSeller > 0) {
            // TODO: can we trust this new address? don't we need some reentrancy checksor something else?
            // slither-disable-next-line arbitrary-send
            (bool sellerSuccess, ) = order.seller.call{ value: feeDistributionData.toSeller }("");
            require(sellerSuccess, "sending ETH to seller failed");
        }
    }

    /*********************
     ** PUBLIC FUNCTIONS *
     *********************/

    function buyAssetWithETH(
        Order memory order,
        Signature memory signature,
        PlatformFees calldata platformFees
    ) public payable nonReentrant returns (bool) {
        require(order.amount == msg.value, "Paid invalid ETH amount");
        FeeDistributionData memory feeDistributionData =
            getFees(order.amount, order.nftAddress, order.tokenId, order.seller, platformFees);
        require((feeDistributionData.fees.price >= order.unitPrice * order.qty), "Paid invalid amount");
        // Using the one sent here saves some checks as we need to make sure the same seller fees
        // where included in both singatures, no need for an extra param or assertion
        verifySellerSignature(
            order.seller,
            order.tokenId,
            order.unitPrice,
            address(0),
            order.nftAddress,
            platformFees.sellerFeePermille,
            signature
        );
        order.buyer = msg.sender;
        emit BuyAsset(order.seller, order.tokenId, order.qty, msg.sender);
        tradeAssetWithETH(order, feeDistributionData);
        return true;
    }

    /**
     * @notice Verifies and executes a safe Token withdraw for this sender, if authorized by the custodial
     * @param wr struct with the withdraw information. What asset and how much of it
     * @param signature asset custodial authorization signature
     */
    function withdrawToken(WithdrawRequest memory wr, Signature memory signature) external returns (bool) {
        address assetOwner = msg.sender;
        require(
            !AuthorizationBitmap.isAuthProcessed(processedAuthorizationsBitMap, wr.authId),
            "Authorization signature already processed"
        );
        // Verifies that this asset custodial, is actually authorizing this user withdraw
        verifyWithdrawSignature(custodialAddress, assetOwner, wr, signature);
        AuthorizationBitmap.setAuthProcessed(processedAuthorizationsBitMap, wr.authId);
        safeTransferFrom(wr.assetType, custodialAddress, assetOwner, wr.assetAddress, wr.tokenId, wr.qty);
        emit TokenWithdraw(assetOwner, wr.authId, wr.tokenId, wr.qty);
        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}