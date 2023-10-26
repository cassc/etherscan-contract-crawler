// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {WETH} from "@solmate/tokens/WETH.sol";

import {IParticleExchange} from "../interfaces/IParticleExchange.sol";
import {ReentrancyGuard} from "../libraries/security/ReentrancyGuard.sol";
import {MathUtils} from "../libraries/math/MathUtils.sol";
import {Lien} from "../libraries/types/Structs.sol";
import {Errors} from "../libraries/types/Errors.sol";

contract ParticleExchange is IParticleExchange, Ownable2StepUpgradeable, UUPSUpgradeable, ReentrancyGuard, Multicall {
    using Address for address payable;

    uint256 private constant _MAX_RATE = 100_000; // 1000% APR
    uint256 private constant _MAX_PRICE = 1_000 ether;
    uint256 private constant _MAX_TREASURY_RATE = 1_000; // 10%
    uint256 private constant _AUCTION_DURATION = 36 hours;
    uint256 private constant _MIN_AUCTION_DURATION = 1 hours;

    WETH private immutable weth;

    uint256 private _nextLienId;
    uint256 private _treasuryRate;
    uint256 private _treasury;
    mapping(uint256 lienId => bytes32 lienHash) public liens;
    mapping(address account => uint256 balance) public accountBalance;
    mapping(address marketplace => bool registered) public registeredMarketplaces;

    // required by openzeppelin UUPS module
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    constructor(address wethAddress) {
        weth = WETH(payable(wethAddress));
        _disableInitializers();
    }

    function initialize() external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    /*==============================================================
                               Supply Logic
    ==============================================================*/

    /// @inheritdoc IParticleExchange
    function supplyNft(
        address collection,
        uint256 tokenId,
        uint256 price,
        uint256 rate
    ) external override nonReentrant returns (uint256 lienId) {
        lienId = _supplyNft(msg.sender, collection, tokenId, price, rate);

        // transfer NFT into contract
        /// @dev collection.setApprovalForAll should have been called by this point
        /// @dev receiver is this contract, no need to safeTransferFrom
        IERC721(collection).transferFrom(msg.sender, address(this), tokenId);

        return lienId;
    }

    function _supplyNft(
        address lender,
        address collection,
        uint256 tokenId,
        uint256 price,
        uint256 rate
    ) internal returns (uint256 lienId) {
        if (price > _MAX_PRICE || rate > _MAX_RATE) {
            revert Errors.InvalidParameters();
        }

        // create a new lien
        Lien memory lien = Lien({
            lender: lender,
            borrower: address(0),
            collection: collection,
            tokenId: tokenId,
            price: price,
            rate: rate,
            loanStartTime: 0,
            auctionStartTime: 0
        });

        /// @dev Safety: lienId unlikely to overflow by linear increment
        unchecked {
            liens[lienId = _nextLienId++] = keccak256(abi.encode(lien));
        }

        emit SupplyNFT(lienId, lender, collection, tokenId, price, rate);
    }

    /// @inheritdoc IParticleExchange
    function updateLoan(
        Lien calldata lien,
        uint256 lienId,
        uint256 price,
        uint256 rate
    ) external override validateLien(lien, lienId) nonReentrant {
        if (msg.sender != lien.lender) {
            revert Errors.Unauthorized();
        }

        if (lien.loanStartTime != 0) {
            revert Errors.LoanStarted();
        }

        if (price > _MAX_PRICE || rate > _MAX_RATE) {
            revert Errors.InvalidParameters();
        }

        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: lien.lender,
                    borrower: address(0),
                    collection: lien.collection,
                    tokenId: lien.tokenId,
                    price: price,
                    rate: rate,
                    loanStartTime: 0,
                    auctionStartTime: 0
                })
            )
        );

        emit UpdateLoan(lienId, price, rate);
    }

    /*==============================================================
                              Withdraw Logic
    ==============================================================*/

    /// @inheritdoc IParticleExchange
    function withdrawNft(Lien calldata lien, uint256 lienId) external override validateLien(lien, lienId) nonReentrant {
        if (msg.sender != lien.lender) {
            revert Errors.Unauthorized();
        }

        if (lien.loanStartTime != 0) {
            /// @dev the same tokenId can be used for other lender's active loan, can't withdraw others
            revert Errors.LoanStarted();
        }

        // delete lien
        delete liens[lienId];

        // transfer NFT back to lender
        /// @dev can withdraw at this point means the NFT is currently in contract without active loan
        /// @dev the interest (if any) is already accrued to lender at NFT acquiring time
        /// @dev use transferFrom in case the receiver does not implement onERC721Received
        IERC721(lien.collection).transferFrom(address(this), msg.sender, lien.tokenId);

        emit WithdrawNFT(lienId);
    }

    /// @inheritdoc IParticleExchange
    function withdrawEth(Lien calldata lien, uint256 lienId) external override validateLien(lien, lienId) nonReentrant {
        if (msg.sender != lien.lender) {
            revert Errors.Unauthorized();
        }

        if (lien.loanStartTime == 0) {
            revert Errors.InactiveLoan();
        }

        // verify that auction is concluded (i.e., liquidation condition has met)
        if (lien.auctionStartTime == 0 || block.timestamp <= lien.auctionStartTime + _AUCTION_DURATION) {
            revert Errors.LiquidationHasNotReached();
        }

        // delete lien
        delete liens[lienId];

        // transfer ETH to lender, i.e., seize ETH collateral
        payable(lien.lender).sendValue(lien.price);

        emit WithdrawETH(lienId);
    }

    /*==============================================================
                            Market Sell Logic
    ==============================================================*/

    /// @inheritdoc IParticleExchange
    function sellNftToMarketPull(
        Lien calldata lien,
        uint256 lienId,
        uint256 amount,
        address marketplace,
        address puller,
        bytes calldata tradeData
    ) external payable override validateLien(lien, lienId) nonReentrant {
        _sellNftToMarketCheck(lien, amount, msg.sender, msg.value);
        _sellNftToMarketLienUpdate(lien, lienId, amount, msg.sender);
        _execSellNftToMarketPull(lien, lien.tokenId, amount, marketplace, puller, tradeData);
    }

    /// @inheritdoc IParticleExchange
    function sellNftToMarketPush(
        Lien calldata lien,
        uint256 lienId,
        uint256 amount,
        address marketplace,
        bytes calldata tradeData
    ) external payable override validateLien(lien, lienId) nonReentrant {
        _sellNftToMarketCheck(lien, amount, msg.sender, msg.value);
        _sellNftToMarketLienUpdate(lien, lienId, amount, msg.sender);
        _execSellNftToMarketPush(lien, lien.tokenId, amount, marketplace, tradeData);
    }

    /**
     * @dev Common pre market sell checks, for both pull and push based flow
     */
    function _sellNftToMarketCheck(Lien calldata lien, uint256 amount, address msgSender, uint256 msgValue) internal {
        if (lien.loanStartTime != 0) {
            revert Errors.LoanStarted();
        }
        if (lien.lender == address(0)) {
            revert Errors.BidNotTaken();
        }
        /// @dev: underlying account balancing ensures balance > lien.price - (amount + msg.value) (i.e., no overspend)
        _balanceAccount(msgSender, lien.price, amount + msgValue);
    }

    /**
     * @dev Common operations prior to market sell execution, used for both market sell and bid acceptance flow
     */
    function _sellNftToMarketBeforeExec(address marketplace) internal view returns (uint256) {
        if (!registeredMarketplaces[marketplace]) {
            revert Errors.UnregisteredMarketplace();
        }
        // ETH + WETH balance before NFT sell execution
        return address(this).balance + weth.balanceOf(address(this));
    }

    /**
     * @dev Pull-based sell nft to market internal execution, used for both market sell and bid acceptance flow
     */
    function _execSellNftToMarketPull(
        Lien memory lien,
        uint256 tokenId,
        uint256 amount,
        address marketplace,
        address puller,
        bytes memory tradeData
    ) internal {
        uint256 balanceBefore = _sellNftToMarketBeforeExec(marketplace);

        /// @dev only approve for one tokenId, preventing bulk execute attack in raw trade
        /// @dev puller (e.g. Seaport Conduit) may be different from marketplace (e.g. Seaport Proxy Router)
        IERC721(lien.collection).approve(puller, tokenId);

        // execute raw order on registered marketplace
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = marketplace.call(tradeData);
        if (!success) {
            revert Errors.MartketplaceFailedToTrade();
        }

        _sellNftToMarketAfterExec(lien, tokenId, amount, balanceBefore);
    }

    /**
     * @dev Push-based sell nft to market internal execution, used for both market sell and bid acceptance flow
     */
    function _execSellNftToMarketPush(
        Lien memory lien,
        uint256 tokenId,
        uint256 amount,
        address marketplace,
        bytes memory tradeData
    ) internal {
        uint256 balanceBefore = _sellNftToMarketBeforeExec(marketplace);

        /// @dev directly send NFT to a marketplace router (e.g. Reservoir); based on the data,
        /// the router will match order and transfer back the correct amount of fund
        IERC721(lien.collection).safeTransferFrom(address(this), marketplace, tokenId, tradeData);

        _sellNftToMarketAfterExec(lien, tokenId, amount, balanceBefore);
    }

    /**
     * @dev Common operations after market sell execution, used for both market sell and bid acceptance flow
     */
    function _sellNftToMarketAfterExec(
        Lien memory lien,
        uint256 tokenId,
        uint256 amount,
        uint256 balanceBefore
    ) internal {
        // transform all WETH (from this trade or otherwise collected elsewhere) to ETH
        uint256 wethAfter = weth.balanceOf(address(this));
        if (wethAfter > 0) {
            weth.withdraw(wethAfter);
        }

        // verify that the NFT in lien is sold and the balance increase is correct
        if (
            IERC721(lien.collection).ownerOf(tokenId) == address(this) ||
            address(this).balance - balanceBefore != amount
        ) {
            revert Errors.InvalidNFTSell();
        }
    }

    /**
     * @dev Common post market sell checks, for both pull and push based flow
     */
    function _sellNftToMarketLienUpdate(
        Lien calldata lien,
        uint256 lienId,
        uint256 amount,
        address msgSender
    ) internal {
        // update lien
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: lien.lender,
                    borrower: msgSender,
                    collection: lien.collection,
                    tokenId: lien.tokenId,
                    price: lien.price,
                    rate: lien.rate,
                    loanStartTime: block.timestamp,
                    auctionStartTime: 0
                })
            )
        );

        emit SellMarketNFT(lienId, msgSender, amount, block.timestamp);
    }

    /*==============================================================
                            Market Buy Logic
    ==============================================================*/

    /// @inheritdoc IParticleExchange
    function buyNftFromMarket(
        Lien calldata lien,
        uint256 lienId,
        uint256 tokenId,
        uint256 amount,
        address spender,
        address marketplace,
        bytes calldata tradeData
    ) external override validateLien(lien, lienId) nonReentrant {
        if (msg.sender != lien.borrower) {
            revert Errors.Unauthorized();
        }

        if (lien.loanStartTime == 0) {
            revert Errors.InactiveLoan();
        }

        uint256 accruedInterest = MathUtils.calculateCurrentInterest(lien.price, lien.rate, lien.loanStartTime);

        // since: lien.price = sold amount + margin
        // and:   payback    = sold amount + margin - bought amount - interest
        // hence: payback    = lien.price - bought amount - interest
        /// @dev cannot overspend, i.e., will revert if payback to borrower < 0. Payback < 0
        /// means the borrower loses all the margin, and still owes some interest. Notice that
        /// this function is not payable because rational borrower won't deposit even more cost
        /// to exit an already liquidated position.
        uint256 payback = lien.price - amount - accruedInterest;

        // accrue interest to lender
        _accrueInterest(lien.lender, accruedInterest);

        // payback PnL to borrower
        if (payback > 0) {
            accountBalance[lien.borrower] += payback;
        }

        // update lien (by default, the lien is open to accept new loan)
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: lien.lender,
                    borrower: address(0),
                    collection: lien.collection,
                    tokenId: tokenId,
                    price: lien.price,
                    rate: lien.rate,
                    loanStartTime: 0,
                    auctionStartTime: 0
                })
            )
        );

        // route trade execution to marketplace
        _execBuyNftFromMarket(lien.collection, tokenId, amount, spender, marketplace, tradeData);

        emit BuyMarketNFT(lienId, tokenId, amount);
    }

    function _execBuyNftFromMarket(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address spender,
        address marketplace,
        bytes calldata tradeData
    ) internal {
        if (!registeredMarketplaces[marketplace]) {
            revert Errors.UnregisteredMarketplace();
        }

        if (IERC721(collection).ownerOf(tokenId) == address(this)) {
            revert Errors.InvalidNFTBuy();
        }

        uint256 ethBalanceBefore = address(this).balance;
        uint256 wethBalanceBefore = weth.balanceOf(address(this));

        // execute raw order on registered marketplace
        bool success;
        if (spender == address(0)) {
            // use ETH
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = marketplace.call{value: amount}(tradeData);
        } else {
            // use WETH
            weth.deposit{value: amount}();
            weth.approve(spender, amount);
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = marketplace.call(tradeData);
        }

        if (!success) {
            revert Errors.MartketplaceFailedToTrade();
        }

        // conert back any unspent WETH to ETH
        uint256 wethBalance = weth.balanceOf(address(this));
        if (wethBalance > 0) {
            weth.withdraw(wethBalance);
        }

        // verify that the declared NFT is acquired and the balance decrease is correct
        if (
            IERC721(collection).ownerOf(tokenId) != address(this) ||
            ethBalanceBefore + wethBalanceBefore - address(this).balance != amount
        ) {
            revert Errors.InvalidNFTBuy();
        }
    }

    /*==============================================================
                               Swap Logic
    ==============================================================*/

    /// @inheritdoc IParticleExchange
    function swapWithEth(
        Lien calldata lien,
        uint256 lienId
    ) external payable override validateLien(lien, lienId) nonReentrant {
        if (lien.loanStartTime != 0) {
            revert Errors.LoanStarted();
        }

        if (lien.lender == address(0)) {
            revert Errors.BidNotTaken();
        }

        /// @dev: underlying account balancing ensures balance > lien.price - msg.value (i.e., no overspend)
        _balanceAccount(msg.sender, lien.price, msg.value);

        // update lien
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: lien.lender,
                    borrower: msg.sender,
                    collection: lien.collection,
                    tokenId: lien.tokenId,
                    price: lien.price,
                    rate: lien.rate,
                    loanStartTime: block.timestamp,
                    auctionStartTime: 0
                })
            )
        );

        // transfer NFT to borrower
        IERC721(lien.collection).safeTransferFrom(address(this), msg.sender, lien.tokenId);

        emit SwapWithETH(lienId, msg.sender, block.timestamp);
    }

    /// @inheritdoc IParticleExchange
    function repayWithNft(
        Lien calldata lien,
        uint256 lienId,
        uint256 tokenId
    ) external override validateLien(lien, lienId) nonReentrant {
        if (msg.sender != lien.borrower) {
            revert Errors.Unauthorized();
        }

        if (lien.loanStartTime == 0) {
            revert Errors.InactiveLoan();
        }

        // transfer fund to corresponding recipients
        _execRepayWithNft(lien, lienId, tokenId);

        // transfer NFT to the contract
        /// @dev collection.setApprovalForAll should have been called by this point
        /// @dev receiver is this contract, no need to safeTransferFrom
        IERC721(lien.collection).transferFrom(msg.sender, address(this), tokenId);
    }

    /// @dev unchecked function, make sure lien is valid, caller is borrower and collection is matched
    function _execRepayWithNft(Lien memory lien, uint256 lienId, uint256 tokenId) internal {
        // accrue interest to lender
        uint256 accruedInterest = MathUtils.calculateCurrentInterest(lien.price, lien.rate, lien.loanStartTime);

        // pay PnL to borrower
        // since: lien.price = sold amount + margin
        // and:   payback    = sold amount + margin - interest
        // hence: payback    = lien.price - interest
        uint256 payback = lien.price - accruedInterest;
        if (payback > 0) {
            accountBalance[lien.borrower] += payback;
        }

        // accrue interest to lender
        _accrueInterest(lien.lender, accruedInterest);

        // update lien (by default, the lien is open to accept new loan)
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: lien.lender,
                    borrower: address(0),
                    collection: lien.collection,
                    tokenId: tokenId,
                    price: lien.price,
                    rate: lien.rate,
                    loanStartTime: 0,
                    auctionStartTime: 0
                })
            )
        );

        emit RepayWithNFT(lienId, tokenId);
    }

    /*==============================================================
                            Refinance Logic
    ==============================================================*/

    /// @inheritdoc IParticleExchange
    function refinanceLoan(
        Lien calldata oldLien,
        uint256 oldLienId,
        Lien calldata newLien,
        uint256 newLienId
    ) external payable override validateLien(oldLien, oldLienId) validateLien(newLien, newLienId) nonReentrant {
        if (msg.sender != oldLien.borrower) {
            revert Errors.Unauthorized();
        }

        if (oldLien.loanStartTime == 0) {
            revert Errors.InactiveLoan();
        }

        if (newLien.loanStartTime != 0) {
            // cannot swap to another active loan
            revert Errors.LoanStarted();
        }

        if (newLien.lender == address(0)) {
            revert Errors.BidNotTaken();
        }

        if (oldLien.collection != newLien.collection) {
            // cannot swap to a new loan with different collection
            revert Errors.UnmatchedCollections();
        }

        uint256 accruedInterest = MathUtils.calculateCurrentInterest(
            oldLien.price,
            oldLien.rate,
            oldLien.loanStartTime
        );

        /// @dev old price + msg.value is available now, new price + interest is the need to spend
        /// @dev account balancing ensures balance > new price + interest - (old price + msg.value) (i.e., no overspend)
        _balanceAccount(msg.sender, newLien.price + accruedInterest, oldLien.price + msg.value);

        // accrue interest to the lender
        _accrueInterest(oldLien.lender, accruedInterest);

        // update old lien
        liens[oldLienId] = keccak256(
            abi.encode(
                Lien({
                    lender: oldLien.lender,
                    borrower: address(0),
                    collection: oldLien.collection,
                    tokenId: newLien.tokenId,
                    price: oldLien.price,
                    rate: oldLien.rate,
                    loanStartTime: 0,
                    auctionStartTime: 0
                })
            )
        );

        // update new lien
        liens[newLienId] = keccak256(
            abi.encode(
                Lien({
                    lender: newLien.lender,
                    borrower: oldLien.borrower,
                    collection: newLien.collection,
                    tokenId: newLien.tokenId,
                    price: newLien.price,
                    rate: newLien.rate,
                    loanStartTime: block.timestamp,
                    auctionStartTime: 0
                })
            )
        );

        emit Refinance(oldLienId, newLienId, block.timestamp);
    }

    /*==============================================================
                                 Bid Logic
    ==============================================================*/

    /// @inheritdoc IParticleExchange
    function offerBid(
        address collection,
        uint256 margin,
        uint256 price,
        uint256 rate
    ) external payable override nonReentrant returns (uint256 lienId) {
        if (price > _MAX_PRICE || rate > _MAX_RATE) {
            revert Errors.InvalidParameters();
        }

        // balance the account for the reest of the margin
        _balanceAccount(msg.sender, margin, msg.value);

        // create a new lien
        Lien memory lien = Lien({
            lender: address(0),
            borrower: msg.sender,
            collection: collection,
            tokenId: margin, /// @dev: use tokenId for margin storage
            price: price,
            rate: rate,
            loanStartTime: 0,
            auctionStartTime: 0
        });

        /// @dev Safety: lienId unlikely to overflow by linear increment
        unchecked {
            liens[lienId = _nextLienId++] = keccak256(abi.encode(lien));
        }

        emit OfferBid(lienId, msg.sender, collection, margin, price, rate);
    }

    /// @inheritdoc IParticleExchange
    function updateBid(
        Lien calldata lien,
        uint256 lienId,
        uint256 margin,
        uint256 price,
        uint256 rate
    ) external payable validateLien(lien, lienId) nonReentrant {
        if (msg.sender != lien.borrower) {
            revert Errors.Unauthorized();
        }

        if (lien.lender != address(0)) {
            /// @dev: if lender exists, an NFT is supplied, regardless of loan active or not,
            /// bid is taken and can't be updated
            revert Errors.BidTaken();
        }

        if (price > _MAX_PRICE || rate > _MAX_RATE) {
            revert Errors.InvalidParameters();
        }

        /// @dev: old margin was stored in the lien.tokenId field
        /// @dev: old margin + msg.value is available now; surplus adds to balance, deficit takes from balance
        _balanceAccount(msg.sender, margin, lien.tokenId + msg.value);

        // update lien
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: address(0),
                    borrower: lien.borrower,
                    collection: lien.collection,
                    tokenId: margin, /// @dev: use tokenId for margin storage
                    price: price,
                    rate: rate,
                    loanStartTime: 0,
                    auctionStartTime: 0
                })
            )
        );

        emit UpdateBid(lienId, margin, price, rate);
    }

    /// @inheritdoc IParticleExchange
    function cancelBid(Lien calldata lien, uint256 lienId) external override validateLien(lien, lienId) nonReentrant {
        if (msg.sender != lien.borrower) {
            revert Errors.Unauthorized();
        }

        if (lien.lender != address(0)) {
            /// @dev: if lender exists, an NFT is supplied, regardless of loan active or not,
            /// bid is taken and can't be cancelled
            revert Errors.BidTaken();
        }

        // return margin to borrower
        /// @dev: old margin was stored in the lien.tokenId field
        accountBalance[lien.borrower] += lien.tokenId;

        // delete lien
        delete liens[lienId];

        emit CancelBid(lienId);
    }

    /// @inheritdoc IParticleExchange
    function acceptBidSellNftToMarketPull(
        Lien calldata lien,
        uint256 lienId,
        uint256 tokenId,
        uint256 amount,
        address marketplace,
        address puller,
        bytes calldata tradeData
    ) external override validateLien(lien, lienId) nonReentrant {
        _acceptBidSellNftToMarketCheck(lien, amount);
        _acceptBidSellNftToMarketLienUpdate(lien, lienId, tokenId, amount, msg.sender);
        // transfer NFT into contract
        /// @dev collection.setApprovalForAll should have been called by this point
        /// @dev receiver is this contract, no need to safeTransferFrom
        IERC721(lien.collection).transferFrom(msg.sender, address(this), tokenId);
        _execSellNftToMarketPull(lien, tokenId, amount, marketplace, puller, tradeData);
    }

    /// @inheritdoc IParticleExchange
    function acceptBidSellNftToMarketPush(
        Lien calldata lien,
        uint256 lienId,
        uint256 tokenId,
        uint256 amount,
        address marketplace,
        bytes calldata tradeData
    ) external override validateLien(lien, lienId) nonReentrant {
        _acceptBidSellNftToMarketCheck(lien, amount);
        _acceptBidSellNftToMarketLienUpdate(lien, lienId, tokenId, amount, msg.sender);
        // transfer NFT into contract
        /// @dev collection.setApprovalForAll should have been called by this point
        /// @dev receiver is this contract, no need to safeTransferFrom
        IERC721(lien.collection).transferFrom(msg.sender, address(this), tokenId);
        _execSellNftToMarketPush(lien, tokenId, amount, marketplace, tradeData);
    }

    function _acceptBidSellNftToMarketCheck(Lien memory lien, uint256 amount) internal {
        if (lien.lender != address(0)) {
            /// @dev: if lender exists, an NFT is supplied, regardless of loan active or not,
            /// bid is taken and can't be re-accepted
            revert Errors.BidTaken();
        }

        // transfer the surplus to the borrower
        /// @dev: lien.tokenId stores the margin
        /// @dev: revert if margin + sold amount can't cover lien.price, i.e., no overspend
        accountBalance[lien.borrower] += lien.tokenId + amount - lien.price;
    }

    function _acceptBidSellNftToMarketLienUpdate(
        Lien memory lien,
        uint256 lienId,
        uint256 tokenId,
        uint256 amount,
        address lender
    ) internal {
        // update lien
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: lender,
                    borrower: lien.borrower,
                    collection: lien.collection,
                    tokenId: tokenId,
                    price: lien.price,
                    rate: lien.rate,
                    loanStartTime: block.timestamp,
                    auctionStartTime: 0
                })
            )
        );

        emit AcceptBid(lienId, lender, tokenId, amount, block.timestamp);
    }

    /*==============================================================
                               Auction Logic
    ==============================================================*/

    /// @inheritdoc IParticleExchange
    function startLoanAuction(
        Lien calldata lien,
        uint256 lienId
    ) external override validateLien(lien, lienId) nonReentrant {
        if (msg.sender != lien.lender) {
            revert Errors.Unauthorized();
        }

        if (lien.loanStartTime == 0) {
            revert Errors.InactiveLoan();
        }

        if (lien.auctionStartTime != 0) {
            revert Errors.AuctionStarted();
        }

        // update lien
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: lien.lender,
                    borrower: lien.borrower,
                    collection: lien.collection,
                    tokenId: lien.tokenId,
                    price: lien.price,
                    rate: lien.rate,
                    loanStartTime: lien.loanStartTime,
                    auctionStartTime: block.timestamp
                })
            )
        );

        emit StartAuction(lienId, block.timestamp);
    }

    /// @inheritdoc IParticleExchange
    function stopLoanAuction(
        Lien calldata lien,
        uint256 lienId
    ) external override validateLien(lien, lienId) nonReentrant {
        if (msg.sender != lien.lender) {
            revert Errors.Unauthorized();
        }

        if (lien.auctionStartTime == 0) {
            revert Errors.AuctionNotStarted();
        }

        if (block.timestamp < lien.auctionStartTime + _MIN_AUCTION_DURATION) {
            revert Errors.AuctionEndTooSoon();
        }

        // update lien
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: lien.lender,
                    borrower: lien.borrower,
                    collection: lien.collection,
                    tokenId: lien.tokenId,
                    price: lien.price,
                    rate: lien.rate,
                    loanStartTime: lien.loanStartTime,
                    auctionStartTime: 0
                })
            )
        );

        emit StopAuction(lienId);
    }

    /// @inheritdoc IParticleExchange
    function auctionSellNft(
        Lien calldata lien,
        uint256 lienId,
        uint256 tokenId
    ) external override validateLien(lien, lienId) nonReentrant {
        if (lien.auctionStartTime == 0) {
            revert Errors.AuctionNotStarted();
        }

        // transfer fund to corresponding recipients
        _execAuctionSellNft(lien, lienId, tokenId, msg.sender);

        // transfer NFT to the contract
        /// @dev receiver is this contract, no need to safeTransferFrom
        /// @dev at this point, collection.setApprovalForAll should have been called
        IERC721(lien.collection).transferFrom(msg.sender, address(this), tokenId);
    }

    /// @dev unchecked function, make sure lien is validated, auction is live and collection is matched
    function _execAuctionSellNft(Lien memory lien, uint256 lienId, uint256 tokenId, address auctionBuyer) internal {
        uint256 accruedInterest = MathUtils.calculateCurrentInterest(lien.price, lien.rate, lien.loanStartTime);

        /// @dev: arithmetic revert if accruedInterest > lien.price, i.e., even 0 buyback cannot cover the interest
        uint256 currentAuctionPrice = MathUtils.calculateCurrentAuctionPrice(
            lien.price - accruedInterest,
            block.timestamp - lien.auctionStartTime,
            _AUCTION_DURATION
        );

        // pay PnL to borrower
        uint256 payback = lien.price - currentAuctionPrice - accruedInterest;
        if (payback > 0) {
            accountBalance[lien.borrower] += payback;
        }

        // pay auction price to new NFT supplier
        payable(auctionBuyer).sendValue(currentAuctionPrice);

        // accrue interest to lender
        _accrueInterest(lien.lender, accruedInterest);

        // update lien (by default, the lien is open to accept new loan)
        liens[lienId] = keccak256(
            abi.encode(
                Lien({
                    lender: lien.lender,
                    borrower: address(0),
                    collection: lien.collection,
                    tokenId: tokenId,
                    price: lien.price,
                    rate: lien.rate,
                    loanStartTime: 0,
                    auctionStartTime: 0
                })
            )
        );

        emit AuctionSellNFT(lienId, auctionBuyer, tokenId, currentAuctionPrice);
    }

    /*==============================================================
                             Push-Based Logic
    ==============================================================*/

    /**
     * @notice Receiver function upon ERC721 transfer
     *
     * @dev We modify this receiver to enable "push based" NFT supply, where one of the following is embedded in the
     * data bytes that are piggy backed with the SafeTransferFrom call:
     * (1) the price and rate (for nft supply) (64 bytes) or
     * (2) lien information (for NFT repay or auction buy) (288 bytes) or
     * (3) lien information and market sell information (accept bid to NFT market sell) (>= 384 bytes).
     * This way, the lender doesn't need to additionally sign the "setApprovalForAll" transaction, which saves gas and
     * creates a better user experience.
     *
     * @param from the address which previously owned the NFT
     * @param tokenId the NFT identifier which is being transferred
     * @param data additional data with no specified format
     */
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        /// @dev NFT transfer coming from buyNftFromMarket will be flagged as already enterred (re-entrancy status),
        /// where the NFT is matched with an existing lien already. If it proceeds (to supply), this NFT will be tied
        /// with two liens, which creates divergence.
        if (!isEntered()) {
            _pushBasedNftSupply(from, tokenId, data);
        }
        return this.onERC721Received.selector;
    }

    function _pushBasedNftSupply(address from, uint256 tokenId, bytes calldata data) internal nonReentrant {
        /// @dev this function is external and can be called by anyone, we need to check the NFT is indeed received
        /// at this point to proceed, message sender is the NFT collection in nominal function call
        if (IERC721(msg.sender).ownerOf(tokenId) != address(this)) {
            revert Errors.NFTNotReceived();
        }
        // use data.length to branch different conditions
        if (data.length == 64) {
            // Conditon (1): NFT supply
            (uint256 price, uint256 rate) = abi.decode(data, (uint256, uint256));
            /// @dev the msg.sender is the NFT collection (called by safeTransferFrom's _checkOnERC721Received check)
            _supplyNft(from, msg.sender, tokenId, price, rate);
        } else if (data.length == 288) {
            // Conditon (2): NFT repay or auction buy
            (Lien memory lien, uint256 lienId) = abi.decode(data, (Lien, uint256));
            /// @dev equivalent to modifier validateLien, replacing calldata to memory
            if (liens[lienId] != keccak256(abi.encode(lien))) {
                revert Errors.InvalidLien();
            }
            /// @dev msg.sender is the NFT collection address
            if (msg.sender != lien.collection) {
                revert Errors.UnmatchedCollections();
            }
            if (from == lien.borrower) {
                /// @dev repayWithNft branch
                /// @dev notice that for borrower repayWithNft and auctionSellNft (at any price point) yield the same
                /// return, since repayNft's payback = auction's payback + auction price, and auction price goes to the
                /// same "from" (the borrower) too. Routing to repayNft is more gas efficient for one less receiver.
                if (lien.loanStartTime == 0) {
                    revert Errors.InactiveLoan();
                }
                _execRepayWithNft(lien, lienId, tokenId);
            } else {
                /// @dev auctionSellNft branch
                /// @dev equivalent to modifier auctionLive, replacing calldata to memory
                if (lien.auctionStartTime == 0) {
                    revert Errors.AuctionNotStarted();
                }
                /// @dev "from" (acution buyer) is the auction buyer address that calls safeTransferFrom
                _execAuctionSellNft(lien, lienId, tokenId, from);
            }
        } else if (data.length >= 384) {
            // Conditon (3): Accept bid to sell NFT to market
            /// @dev flexible data.length because tradeData can be of any non-zero length
            (
                Lien memory lien,
                uint256 lienId,
                uint256 amount,
                address marketplace,
                address puller,
                bytes memory tradeData
            ) = abi.decode(data, (Lien, uint256, uint256, address, address, bytes));
            /// @dev equivalent to modifier validateLien, replacing calldata to memory
            if (liens[lienId] != keccak256(abi.encode(lien))) {
                revert Errors.InvalidLien();
            }
            /// @dev msg.sender is the NFT collection address
            if (msg.sender != lien.collection) {
                revert Errors.UnmatchedCollections();
            }
            /// @dev "from" (nft supplier) is address that calls safeTransferFrom
            /// @dev zero address puller, means sell to market using push based flow
            if (puller == address(0)) {
                _acceptBidSellNftToMarketCheck(lien, amount);
                _acceptBidSellNftToMarketLienUpdate(lien, lienId, tokenId, amount, from);
                _execSellNftToMarketPush(lien, tokenId, amount, marketplace, tradeData);
            } else {
                _acceptBidSellNftToMarketCheck(lien, amount);
                _acceptBidSellNftToMarketLienUpdate(lien, lienId, tokenId, amount, from);
                _execSellNftToMarketPull(lien, tokenId, amount, marketplace, puller, tradeData);
            }
        } else {
            revert Errors.InvalidParameters();
        }
    }

    /*==============================================================
                               Balance Logic
    ==============================================================*/

    /// @inheritdoc IParticleExchange
    function withdrawAccountBalance() external override nonReentrant {
        uint256 balance = accountBalance[msg.sender];
        if (balance == 0) return;

        accountBalance[msg.sender] = 0;
        payable(msg.sender).sendValue(balance);

        emit WithdrawAccountBalance(msg.sender, balance);
    }

    function _accrueInterest(address account, uint256 amount) internal {
        uint256 treasuryRate = _treasuryRate; /// @dev SLOAD once to cache, saving gas
        if (treasuryRate > 0) {
            uint256 treasuryInterest = MathUtils.calculateTreasuryProportion(amount, treasuryRate);
            _treasury += treasuryInterest;
            amount -= treasuryInterest;
        }
        accountBalance[account] += amount;

        emit AccrueInterest(account, amount);
    }

    function _balanceAccount(address account, uint256 withdraw, uint256 deposit) internal {
        if (withdraw > deposit) {
            // use account balance to cover the deposit deficit
            /// @dev balance - (amount - deposit) >= 0, i.e., amount <= balance + deposit (cannot overspend)
            accountBalance[account] -= (withdraw - deposit);
        } else if (deposit > withdraw) {
            // top up account balance with the deposit surplus
            accountBalance[account] += (deposit - withdraw);
        }
    }

    /*==============================================================
                             Validation Logic
    ==============================================================*/

    modifier validateLien(Lien calldata lien, uint256 lienId) {
        if (liens[lienId] != keccak256(abi.encode(lien))) {
            revert Errors.InvalidLien();
        }
        _;
    }

    /*==============================================================
                               Admin Logic
    ==============================================================*/

    /// @inheritdoc IParticleExchange
    function registerMarketplace(address marketplace) external override onlyOwner {
        registeredMarketplaces[marketplace] = true;
        emit RegisterMarketplace(marketplace);
    }

    /// @inheritdoc IParticleExchange
    function unregisterMarketplace(address marketplace) external override onlyOwner {
        registeredMarketplaces[marketplace] = false;
        emit UnregisterMarketplace(marketplace);
    }

    /// @inheritdoc IParticleExchange
    function setTreasuryRate(uint256 rate) external override onlyOwner {
        if (rate > _MAX_TREASURY_RATE) {
            revert Errors.InvalidParameters();
        }
        _treasuryRate = rate;
        emit UpdateTreasuryRate(rate);
    }

    /// @inheritdoc IParticleExchange
    function withdrawTreasury(address receiver) external override onlyOwner {
        uint256 withdrawAmount = _treasury;
        if (withdrawAmount > 0) {
            if (receiver == address(0)) {
                revert Errors.InvalidParameters();
            }
            _treasury = 0;
            payable(receiver).sendValue(withdrawAmount);
            emit WithdrawTreasury(receiver, withdrawAmount);
        }
    }

    /*==============================================================
                              Miscellaneous
    ==============================================================*/

    // receive ETH
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // solhint-disable-next-line func-name-mixedcase
    function WETH_ADDRESS() external view returns (address) {
        return address(weth);
    }
}