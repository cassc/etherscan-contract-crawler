// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {BaseGovernanceWithUserUpgradable} from "./common/BaseGovernanceWithUserUpgradable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ListingHelper, ISwaprWallet} from "./utils/ListingHelper.sol";
import "./interfaces/ISwaprFee.sol";

/// @title Manages NFT listings and user funds
/// @author swapr
/// @notice Allows only signature based listings
/// @dev Can only be interacted from a recognised marketplace EOA
contract SwaprGL is BaseGovernanceWithUserUpgradable, ListingHelper {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    event Purchased(bool isSplit, Order order, uint[] splitParts);
    event Claimed(bool success, string res);

    uint public listingModTimeLimit;

    ISwaprFee private _swaprFee;

    /// @notice initialize the contract
    /// @param data encoded data containing the wallet address, marketplace address and swapr fee address
    function initialize(bytes calldata data) public initializer {
        (address payable walletAddress, address payable marketplaceAddress, address swaprFeeAddress) = abi.decode(
            data,
            (address, address, address)
        );
        __BaseGovernanceWithUser_init(_msgSender());

        _checkAddress(walletAddress);
        _checkAddress(marketplaceAddress);
        _checkAddress(swaprFeeAddress);

        //You can setup custom roles here in addition to the default gevernance roles
        //e.g _setupRole(MARKETPLACE_ROLE, marketplaceAddress);

        //All state variables must be initialized here in sequence to prevent upgrade conflicts
        swaprWallet = ISwaprWallet(walletAddress);
        _swaprFee = ISwaprFee(swaprFeeAddress);
        theMarketplace = marketplaceAddress;
        timeOffset = 5 minutes; // 5 minutes offset
        listingModTimeLimit = 1 hours; //1 hour
    }

    /// @notice Only admin role can attach a new swapr wallet incase
    /// @param wallet address of the new wallet
    function attachNewWallet(address wallet) external payable {
        _onlyAdmin();
        _checkAddress(wallet);
        swaprWallet = ISwaprWallet(wallet);
    }

    /// @notice Only admin role can attach a new swapr fee contract incase
    /// @param feeContract address of the new fee contract
    function attachNewFeeContract(address feeContract) external payable {
        _onlyAdmin();
        _checkAddress(feeContract);
        _swaprFee = ISwaprFee(feeContract);
    }

    /// @notice To update the marketplace account incase
    /// @param marketplace address of the new marketplace
    function attachNewMarketplace(address marketplace) external payable {
        _onlyAdmin();
        _checkAddress(marketplace);
        theMarketplace = marketplace;
    }

    /// @notice To update the offset time incase
    /// @param timeInSecs new time in seconds
    function updateTimeOffset(uint16 timeInSecs) external payable {
        _onlyAdmin();
        require(timeInSecs > 0 && timeInSecs < 1 hours, "INV_TIME");
        timeOffset = timeInSecs;
    }

    /// @notice sets the max time in which a listing can be modified
    /// @param timeInSecs new time in seconds
    function setListingUpdateTime(uint16 timeInSecs) external payable {
        _onlyAdmin();
        require(timeInSecs > 0 && timeInSecs < 1 hours, "INV_TIME");
        listingModTimeLimit = timeInSecs;
    }

    /// @notice Deposit NFTs to be listed only ERC721 ILock proxies are accepted
    /// @dev depositType == 3 means deposit to list for sale in future
    /// @param data should be signed by the depositor of NFT
    function depositNFTs(bytes calldata data) external {
        _checkSignature(_msgSender(), data);
        (bytes memory message, bytes memory sig) = _decodeBytesToBytesBytes(data);
        (uint depositType, address lock, uint nftId) = abi.decode(message, (uint, address, uint));
        require(depositType == 3, "INV_DTYPE");
        swaprWallet.lockNFT(sig, lock, nftId, _msgSender());
    }

    /// @notice Creates a new listing for Auction or Order type based on data provided
    /// @dev Only proceeds with valid marketplace signature
    /// @param listingType 1 equals Auction, 2 equals Order
    /// @param fee fee to be paid
    /// @param paymentToken address of the token to be used for fee payment
    /// @param data contains the encoded string
    function createListing(uint8 listingType, uint256 fee, address paymentToken, bytes calldata data) external {
        _checkSignature(theMarketplace, data);
        address sender = _msgSender();
        (bytes memory listingData, ) = _decodeBytesToBytesBytes(data);
        (bool isValid, address lock, uint nftId, , bytes memory sig) = _validateListing(
            sender,
            listingType,
            listingData
        );
        require(isValid, "INV_LISTING");
        require(_swaprFee.getFeePaid(sender, paymentToken) >= fee, "LOW_FEE_PAID");
        swaprWallet.lockNFT(sig, lock, nftId, sender);
        _swaprFee.disposeFeeRecord(abi.encode(fee, sender, paymentToken));
    }

    /// @notice Updates a new listing for Auction or Order type based on data provided
    /// @dev Only proceeds with valid marketplace signature
    /// @param listingType 1 equals Auction, 2 equals Order
    /// @param data contains the encoded string
    function updateListing(uint8 listingType, bytes calldata data) external {
        _checkSignature(theMarketplace, data);
        address sender = _msgSender();
        (bytes memory listingDatas, ) = abi.decode(data, (bytes, bytes));
        (bytes memory activeListingData, bytes memory proposedListingData) = abi.decode(listingDatas, (bytes, bytes));
        _checkSignature(sender, activeListingData);
        _checkSignature(sender, proposedListingData);
        uint createdOn;
        if (listingType == 1) {
            //Auction
            Auction memory auction = _extractAuctionInfo(activeListingData);
            createdOn = auction.createdOn;
        } else if (listingType == 2) {
            //Order
            Order memory order = _extractOrderInfo(activeListingData);
            createdOn = order.createdOn;
        }
        require(block.timestamp - createdOn <= listingModTimeLimit, "TIME_EXD");
        (bool isValid, address lock, uint nftId, , bytes memory sig) = _validateListing(
            sender,
            listingType,
            proposedListingData
        );
        require(isValid, "INV_LIST");
        swaprWallet.updateLockedNFT(sig, lock, nftId);
    }

    /// @notice is for Auction type only so that seller or buyer can claim their rightful assets/funds
    /// @dev automatically detects if buyer have wallet deposits or provoke for approval
    /// @dev you can check the deposits by getBalance() or else get approval for funds
    /// @param data must be Auction & Bid type provided with marketplace signature
    function claim(bytes calldata data) external {
        _checkSignature(theMarketplace, data);
        (bytes memory message, ) = _decodeBytesToBytesBytes(data);
        (bytes memory listingData, bytes memory lastBid) = _decodeBytesToBytesBytes(message);

        address claimant = _msgSender();
        (bool success, string memory res) = _validateClaim(claimant, listingData, lastBid);
        require(success, res);
        Bid memory bid = _extractBid(lastBid);
        Auction memory auction = _extractAuctionInfo(listingData);

        if (_verify(claimant, listingData)) {
            //for seller
            PayNow memory payOps = PayNow(
                auction.toEOA,
                auction.acceptedToken,
                bid.bidder,
                claimant,
                swaprWallet.getBalance(bid.bidder, auction.acceptedToken),
                bid.offerPrice
            );
            require(payNow(payOps, auction.depositType), "PMT_FAIL");
        } else if (_verify(claimant, lastBid)) {
            //for buyer
            swaprWallet.releaseNFT(auction.lock, auction.nftId, claimant);
            swaprWallet.disposeNFT(auction.lock, auction.nftId);
        } else {
            success = false;
            res = "INV_CLAIMANT";
            return;
        }
        emit Claimed(success, res);
    }

    /// @notice withdraws deposited NFTs if needed
    /// @dev only for marketplace to prevent listed NFTs being withdrawn
    /// @param data must be provided with marketplace signature
    function withdrawNFT(bytes calldata data) external {
        _checkSignature(theMarketplace, data);
        (bytes memory info, ) = _decodeBytesToBytesBytes(data);
        (address lock, uint256 nftId) = abi.decode(info, (address, uint256));
        address sender = _msgSender();
        _withdraw(sender, lock, nftId);
    }

    /// @notice withdraws native/erc20 deposited funds
    /// @dev anyone can withdraw deposited funds because getBalance() only returns unlocked funds
    /// @param data must be provided with marketplace signature
    function withdrawFunds(bytes calldata data) external {
        _checkSignature(theMarketplace, data);
        (bytes memory info, ) = _decodeBytesToBytesBytes(data);
        (address token, uint withdrawable, address receiver) = abi.decode(info, (address, uint, address));
        _withdraw(token, withdrawable, receiver, _msgSender());
    }

    /// @notice Get active swapr wallet address
    /// @return Address of the wallet contract
    function getWallet() public view returns (address) {
        return address(swaprWallet);
    }

    /// @notice Buyer's function to proceed purchase of Order type listing
    /// @dev automatically detects if buyer have wallet deposits or provoke for approval
    /// @dev you can check the deposits by getBalance() or else get approval for funds
    /// @dev does not require buyer's signature since its direct purchase but requires sellers signature
    /// @dev it also requires the marketplace signature to make sure the Order type data is not forged
    /// @param buyerPurchasedAmount front end dev should maintain the amount purchased by each wallet and send in
    /// @param data must be Order type provided with marketplace signature
    /// @param split SHould not be zero or more than EXP
    function buyNowOrder(uint256 buyerPurchasedAmount, bytes memory data, uint128 split) external payable {
        _checkSignature(theMarketplace, data);
        (bytes memory listingData, ) = _decodeBytesToBytesBytes(data);
        (, bytes memory sig) = _decodeBytesToBytesBytes(listingData);
        bool isSplit;
        Order memory order = _extractOrderInfo(listingData);
        require(swaprWallet.isNFTLocked(order.lock, order.nftId), "ORD_NOT_EXIST");
        require(order.depositType == 2, "INV_DEP_TYPE");
        require(
            split > 0 && split <= EXP && split <= order.remainingPart && split <= order.maxTokenSell,
            "INC_SPLIT_AMT"
        );

        address buyer = _msgSender();
        require(buyerPurchasedAmount < order.maxBuyPerWallet, "PURCH_LMT_EXCD");

        //MakePayment
        uint256 price = (order.fixedPrice * split) / EXP;

        PayNow memory payOps = PayNow(
            order.toEOA,
            order.acceptedToken,
            buyer,
            order.seller,
            swaprWallet.getBalance(buyer, order.acceptedToken),
            price
        );
        require(_payUpfront(payOps, order.depositType, msg.value), "PMT_FAIL");

        if (split < order.remainingPart) {
            uint256[] memory splitParts = new uint[](2);
            address[] memory addresses = new address[](2);
            //seller's part
            uint256 splitRecount = ((split * EXP) / order.remainingPart);
            splitParts[0] = EXP - splitRecount;
            addresses[0] = getWallet();
            //buyer's part
            splitParts[1] = splitRecount;
            addresses[1] = buyer;
            uint256[] memory newIDs = swaprWallet.splitReleaseNFT(order.lock, order.nftId, splitParts, addresses);
            order.nftId = newIDs[0];
            order.remainingPart = order.remainingPart - split; //where remainingPart should be unsold part of the NFT
            if (order.remainingPart > 0) {
                isSplit = true;
            }
            swaprWallet.lockNFT(sig, order.lock, order.nftId, getWallet());
            emit Purchased(isSplit, order, splitParts);
        } else {
            swaprWallet.releaseNFT(order.lock, order.nftId, buyer);
            swaprWallet.disposeNFT(order.lock, order.nftId);
        }
    }

    /// @notice Buyer's function to proceed purchase of Auction type listing
    /// @dev automatically detects if buyer have wallet deposits or provoke for approval
    /// @dev you can check the deposits by getBalance() or else get approval for funds
    /// @param data must be Auction & Bid type provided with marketplace signature
    function buyNowAuction(bytes memory data) external payable {
        _checkSignature(theMarketplace, data);
        (bytes memory message, ) = _decodeBytesToBytesBytes(data);
        (bool isActiveBid, bytes memory listingData, bytes memory lastBid) = abi.decode(message, (bool, bytes, bytes));

        Auction memory auction = _extractAuctionInfo(listingData);
        require(swaprWallet.isNFTLocked(auction.lock, auction.nftId), "AUC_NOT_EXST");
        require(auction.depositType == 1, "INV_DP_TYPE");

        if (isActiveBid) {
            Bid memory bid = _extractBid(lastBid);
            require(block.timestamp < bid.listingEndTime, "AUC_END");
            require(auction.buyNowPrice > bid.offerPrice, "HIGH_BID_PLACD");
        }

        address buyer = _msgSender();

        PayNow memory payOps = PayNow(
            auction.toEOA,
            auction.acceptedToken,
            buyer,
            auction.seller,
            swaprWallet.getBalance(buyer, auction.acceptedToken),
            auction.buyNowPrice
        );
        require(_payUpfront(payOps, auction.depositType, msg.value), "PMT_FAIL");

        swaprWallet.releaseNFT(auction.lock, auction.nftId, buyer);
        swaprWallet.disposeNFT(auction.lock, auction.nftId);
    }

    /// @notice Triggers the payment process for any valid purchase on listing
    /// @dev Can handle Native or ERC payments of any kind
    /// @param payOps refer to type PayNow
    /// @param depositType 1 for Auction, 2 for Order
    /// @return paid true if payment succeeds
    function payNow(PayNow memory payOps, uint256 depositType) public payable returns (bool paid) {
        if (payOps.fromBalance >= payOps.amount) {
            paid = _payFromWallet(payOps, depositType);
        } else {
            paid = _payUpfront(payOps, depositType, msg.value);
        }
    }

    /// @notice performs a payment from buyer to seller for Native/ERC20 tokens
    /// @dev can use if buyer do have funds within swapr wallet
    /// @param _payOps refer to PayNow struct for details
    /// @param depositType 1 for Auction, 2 for Order
    /// @return true if payment succeeds
    function _payFromWallet(PayNow memory _payOps, uint256 depositType) private returns (bool) {
        address feeReceiver = _swaprFee.getFeeReceiver();
        uint256 finalListingFee = depositType == 1
            ? _swaprFee.getFinalAuctionFee(_payOps.amount, _payOps.acceptedToken)
            : _swaprFee.getFinalOrderFee(_payOps.amount, _payOps.acceptedToken);

        if (_payOps.acceptedToken == address(0)) {
            swaprWallet.swapNative(_payOps.from, _payOps.receiver, _payOps.amount);
            swaprWallet.releaseNative(feeReceiver, _payOps.receiver, finalListingFee);
            if (_payOps.toEOA) {
                swaprWallet.releaseNative(_payOps.receiver, _payOps.receiver, _payOps.amount - finalListingFee);
            }
        } else {
            swaprWallet.swapERC(_payOps.acceptedToken, _payOps.from, _payOps.receiver, _payOps.amount);
            swaprWallet.releaseERC(_payOps.acceptedToken, feeReceiver, _payOps.receiver, finalListingFee);
            if (_payOps.toEOA) {
                swaprWallet.releaseERC(
                    _payOps.acceptedToken,
                    _payOps.receiver,
                    _payOps.receiver,
                    _payOps.amount - finalListingFee
                );
            }
        }
        return true;
    }

    /// @notice performs an upfront payment from buyer to seller for Native/ERC20 tokens
    /// @dev can use if buyer do not have any funds within swapr wallet
    /// @param _payOps refer to PayNow struct for details
    /// @param depositType 1 for Auction, 2 for Order
    /// @param value value attached to payable in case of Native currency
    /// @return true if payment succeeds
    function _payUpfront(PayNow memory _payOps, uint256 depositType, uint256 value) private returns (bool) {
        address receiver = _payOps.toEOA ? _payOps.receiver : address(swaprWallet);
        address feeReceiver = _swaprFee.getFeeReceiver();
        uint256 finalListingFee = depositType == 1
            ? _swaprFee.getFinalAuctionFee(_payOps.amount, _payOps.acceptedToken)
            : _swaprFee.getFinalOrderFee(_payOps.amount, _payOps.acceptedToken);

        if (_payOps.acceptedToken == address(0)) {
            require(value >= _payOps.amount, "LOW_VAL");
            payable(feeReceiver).transfer(finalListingFee);
            if (_payOps.toEOA) {
                payable(receiver).transfer(_payOps.amount - finalListingFee);
            } else {
                swaprWallet.depositNativeSwapr{value: _payOps.amount - finalListingFee}(_payOps.receiver);
            }
        } else {
            IERC20MetadataUpgradeable paymentToken = IERC20MetadataUpgradeable(_payOps.acceptedToken);
            require(paymentToken.allowance(_payOps.from, address(this)) >= _payOps.amount, "INSF_ALWNC");
            paymentToken.safeTransferFrom(_payOps.from, feeReceiver, finalListingFee);
            paymentToken.safeTransferFrom(_payOps.from, receiver, _payOps.amount - finalListingFee);
            if (!_payOps.toEOA) {
                swaprWallet.depositERCSwapr(_payOps.acceptedToken, _payOps.receiver, _payOps.amount - finalListingFee);
            }
        }
        return true;
    }

    /// @notice internal implementation for NFT withdraw
    /// @dev can be used for both Auction and Order
    /// @param claimant address of the claimant
    /// @param lock address of the lock contract
    /// @param nftId id of the NFT
    function _withdraw(address claimant, address lock, uint256 nftId) private {
        require(swaprWallet.isNFTLocked(lock, nftId), "NOT_AVAIL");
        swaprWallet.releaseNFT(lock, nftId, claimant);
    }

    /// @notice internal implementation for Native/ERC20 withdraw
    /// @dev can be used for both Auction and Order
    /// @param token address of the token
    /// @param withdrawable amount of the token to withdraw
    /// @param receiver address of the receiver
    /// @param claimant address of the claimant
    function _withdraw(address token, uint256 withdrawable, address receiver, address claimant) private {
        if (token == address(0)) {
            swaprWallet.releaseNative(receiver, claimant, withdrawable);
        } else {
            swaprWallet.releaseERC(token, receiver, claimant, withdrawable);
        }
    }
}