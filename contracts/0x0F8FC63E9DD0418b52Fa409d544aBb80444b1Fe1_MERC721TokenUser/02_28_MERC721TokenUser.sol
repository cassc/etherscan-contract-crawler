pragma solidity ^0.5.16;

import "./MTokenUser.sol";
import "./MTokenInterfaces.sol";
import "./MtrollerInterface.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./compound/InterestRateModel.sol";
import "./open-zeppelin/token/ERC721/IERC721Receiver.sol";
import "./open-zeppelin/token/ERC721/ERC721.sol";
import "./open-zeppelin/token/ERC20/IERC20.sol";
import "./open-zeppelin/introspection/ERC165.sol";

/**
 * @title ERC-721 Token Contract
 * @notice Base for mNFTs
 * @author mmo.finance
 */
contract MERC721TokenUser is MTokenUser, ERC721("MERC721","MERC721"), MERC721UserInterface {
    /** Shortcuts for 'require' error message strings, to save gas
    CAT - "Cannot accept token directly - use mint() or redeem()"
    INI - "Invalid tokenId"
    TRF - "Transfer failed"
    EMF - "Exit market failed"
    ENF - "enter market failed"
    MTE - "Mint NFT tokenization error"
    IIP - "Invalid initial asking price"
    MEF - "Mint ERC-721 token failed"
    NIM - "not implemented yet"
    IIS - "Invalid instant sale"
    TSF - "token seizure failed"
    LNE - "liquidate to non ERC721Receiver"
    INV - "Invalid function call"
    AOU - "Amount must be oneUnit"
    TIF - "Transfer in failed"
    TIA - "Transfer in: Invalid approval"
    INP - "Instant sell not permitted"
     */

    /**
     * @notice Constructs a new MERC721TokenUser
     */
    constructor() public MTokenUser() {
    }

    /**
     * Marker function identifying this contract as "ERC721_MTOKEN" type
     */
    function getTokenType() public pure returns (MTokenIdentifier.MTokenType) {
        return MTokenIdentifier.MTokenType.ERC721_MTOKEN;
    }

    /**
     * @notice Handle the receipt of an NFT, see Open Zeppelin's IERC721Receiver.
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public view returns (bytes4) {
        /* unused parameters */
        from;
        tokenId;
        data;

        /* Reject any token where we did not initiate the transfer ourselves */
        require(operator == address(this), "CAT");
        return this.onERC721Received.selector;
    }

    /**
     * @notice Transfer the `tokenId` token from `from` to `to`
     * @dev Called by both `safeTransferFrom` and `transferFrom` internally. Reverts on any error.
     * @param from The address of the source account
     * @param to The address of the destination account
     * @param tokenId The ID of the token to transfer
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal nonReentrant {
        // No safe failures since ERC-721 transfers expect revert on any error
        require(tokenId <= uint240(-1), "INI");
        uint240 mToken = uint240(tokenId);

        /* Transfer mTokens (full balance). Revert if not allowed. On success, this emits mToken transfer event */
        uint err = transferTokens(from, to, mToken, accountTokens[mToken][from]);
        requireNoError(err, "TRF");

        /* Perform mERC721-specific cleanup actions (e.g., resetting askingPrice and exiting market) */
        cleanUpAfterTokenTransferInternal(mToken, from);

        /* Do ERC-721 specific transfer. On success, this emits ERC-721 transfer event */
        super._transferFrom(from, to, tokenId);
    }

    /**
     * @notice Perform any "clean up" actions after mToken transfer
     * @dev Called internally after transfer, seize, and redeem. Reverts on any error.
     * @param mToken The mToken that was transferred
     * @param oldOwner The mToken's owner before the transfer
     */
    function cleanUpAfterTokenTransferInternal(uint240 mToken, address oldOwner) private {

        /* Reset the asking price to zero (= "not active") */
        if (askingPrice[mToken] > 0) {
            askingPrice[mToken] = 0;
        }

        /* Exit market. Fail if market cannot be exited */
        uint err = mtroller.exitMarketOnBehalf(mToken, oldOwner);
        requireNoError(err, "EMF");
    }

    /**
     * @notice Sender supplies an (NFT) asset into the market and receives a mToken in exchange
     * @dev Reverts upon any failure
     * @param underlyingTokenID The ID of the underlying ERC-721 asset to supply
     * @return (uint240) The new mToken
     */
    function mint(uint256 underlyingTokenID) external returns (uint240) {
        return mintTo(msg.sender, underlyingTokenID);
    }

    /**
     * @notice Sender supplies an (NFT) asset into the market, beneficiary receives a mToken in exchange 
     * and immediately uses it as collateral
     * @dev Reverts upon any failure
     * @param beneficiary The address to receive the minted mToken
     * @param underlyingTokenID The ID of the underlying ERC-721 asset to supply
     * @return (uint240) The newly minted and collateralized mToken
     */
    function mintAndCollateralizeTo(address beneficiary, uint256 underlyingTokenID) external returns (uint240) {
        uint240 mToken = mintTo(beneficiary, underlyingTokenID);
        uint err = mtroller.enterMarketOnBehalf(mToken, beneficiary);
        requireNoError(err, "ENF");
        return mToken;
    }

    /**
     * @notice Sender supplies an (NFT) asset into the market and beneficiary receives a mToken in exchange
     * @dev Reverts upon any failure
     * @param beneficiary The address to receive the minted mToken
     * @param underlyingTokenID The ID of the underlying ERC-721 asset to supply
     * @return (uint240) The new mToken
     */
    function mintTo(address beneficiary, uint256 underlyingTokenID) public nonReentrant returns (uint240) {
        /* Mint the mToken */
        (uint240 mToken, uint tokens, uint underlyingAmount) = mintToInternal(beneficiary, underlyingTokenID, oneUnit);
        require(underlyingAmount == oneUnit && tokens == oneUnit, "MTE");

        /* Require asking price not set initially */
        require(askingPrice[mToken] == 0, "IIP");

        /* Mint the ERC-721 specific parts of the mToken */
        _safeMint(beneficiary, mToken);
        require(ownerOf(mToken) == beneficiary, "MEF");

        return mToken;
    }

    // /**
    //  * @notice Sender repays their own borrow (including accrued interest)
    //  * @dev Reverts upon any failure
    //   * @param repayUnderlyingID The ID of the underlying NFT asset that is returned to the protocol
    //  * @return (uint) If successful, returns the actual repayment amount.
    //  */
    // function repayBorrow(uint256 repayUnderlyingID) external payable returns (uint) {
    //     repayUnderlyingID;
    //     /* No NFT borrowing for now */
    //     uint err = fail(Error.MTROLLER_REJECTION, FailureInfo.BORROW_MTROLLER_REJECTION);
    //     requireNoError(err, "NIM");
    //     return 0;
    // }

    // /**
    //  * @notice Sender repays a borrow belonging to borrower (including accrued interest)
    //  * @dev Reverts upon any failure
    //  * @param borrower the account with the debt being paid off
    //   * @param repayUnderlyingID The ID of the underlying NFT asset that is returned to the protocol
    //  * @return (uint) If successful, returns the actual repayment amount.
    //  */
    // function repayBorrowBehalf(address borrower, uint256 repayUnderlyingID) external payable returns (uint) {
    //     borrower;
    //     repayUnderlyingID;
    //     /* No NFT borrowing for now */
    //     uint err = fail(Error.MTROLLER_REJECTION, FailureInfo.BORROW_MTROLLER_REJECTION);
    //     requireNoError(err, "NIM");
    //     return 0;
    // }

    // /**
    //  * @notice The sender liquidates the borrowers collateral.
    //  * The collateral seized is transferred to the liquidator.
    //  * @dev Reverts upon any failure
    //  * @param borrower The borrower of this mToken to be liquidated
    //  * @param repayUnderlyingID The ID of the underlying borrowed NFT asset to repay
    //  * @param mTokenCollateral The market in which to seize collateral from the borrower
    //  * @return (uint) If successful, returns the actual repayment amount.
    //  */
    // function liquidateBorrow(address borrower, uint256 repayUnderlyingID, uint240 mTokenCollateral) external payable returns (uint) {
    //     borrower;
    //     repayUnderlyingID;
    //     mTokenCollateral;
    //     /* No NFT borrowing for now */
    //     uint err = fail(Error.MTROLLER_REJECTION, FailureInfo.BORROW_MTROLLER_REJECTION);
    //     requireNoError(err, "NIM");
    //     return 0;
    // }

    /**
     * @notice The sender places an auction bid for an mToken by sending cash (in Wei). Any funds sent
     * are added to already pending bids by the same sender. If the total bid exceeds the current 
     * asking price (if any) of the mToken, then it is sold to the sender immediately
     * @dev Reverts if mToken does not exist or cannot be transferred from current owner
     * @param mToken The mToken to bid on
     */
    function addAuctionBid(uint240 mToken) external payable nonReentrant2 {
        address oldOwner = ownerOf(mToken); // reverts if mToken does not exist
        uint256 askPrice = askingPrice[mToken];
        uint256 paid = tokenAuction.addOfferETH.value(msg.value)(mToken, msg.sender, oldOwner, askPrice);
        if (paid > 0) {
            require(paid >= askPrice && askPrice > 0, "IIS");
            _safeTransferFrom(oldOwner, msg.sender, mToken, "");
        }
    }

    /**
     * @notice Sell an mToken to the highest bidder. If the caller is the current owner, the sale will
     * be executed if the current highest bid is >= minimumPrice. If the caller is any other account, the
     * sale will be executed if the current highest bid is >= the current asking price.
     * @dev Reverts if mToken does not exist (e.g. because it was redeemed before) or if no valid offer found.
     * safeTransferFrom reverts if current owner would be left with insufficient collateral after the transfer. 
     * Payment is always converted into payment token, not underlying cash. Since this is done BEFORE 
     * transferring the mNFT these payment tokens will count towards the current owner's total collateral 
     * (if he has entered the market for these before), and thus it is possible to also transfer mNFTs even 
     * if the current user has SOME outstanding borrow.
     * @param mToken The mToken to be sold to the highest bidder
     * @param minimumPrice The minimum price to accept in case of instant sale triggered by owner
     */
    function instantSellToHighestBidder(uint240 mToken, uint256 minimumPrice) public nonReentrant2 {
        address oldOwner = ownerOf(mToken); // reverts if owner = 0 (non-existant)
        (address maxOfferor, uint256 maxOffer, , ) = tokenAuction.acceptHighestOffer(mToken, oldOwner, oldOwner, 0, minimumPrice);

        uint256 askPrice = askingPrice[mToken];
        require((msg.sender == oldOwner) || (maxOffer >= askPrice && askPrice > 0), "INP");
        _safeTransferFrom(oldOwner, maxOfferor, mToken, "");
    }

    /**
     * @notice Set the asking price at which the current owner of an mToken is willing to sell instantly
     * @dev If a new, non-zero asking price is set and the current highest bid is exceeding this value,
     * the mToken will immediately be sold to the highest bidder (at the price of the highest bid).
     * Reverts if caller is not current owner or mToken does not exist.
     * @param mToken The mToken for which to set the asking price
     * @param newAskingPrice The new asking price (in Wei). If set to zero, asking price is disabled (i.e.,
     * the owner is not willing to sell instantly at any price).
     */
    function setAskingPrice(uint240 mToken, uint256 newAskingPrice) external {
        require(msg.sender == ownerOf(mToken), "Only owner");
        askingPrice[mToken] = newAskingPrice;
        if (newAskingPrice > 0 && tokenAuction.getMaxOffer(mToken) >= newAskingPrice) {
            instantSellToHighestBidder(mToken, newAskingPrice);
        }
    }

    /**
     * @notice Start the grace period for collateral mToken (required before it can be liquidated).
     * The user starting the grace period subsequently has first mover rights as a liquidator.
     * @param mToken The mToken collateral to start the grace period for
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function startGracePeriod(uint240 mToken) external nonReentrant returns (uint) {

        /* If liquidation is not allowed (anymore), cancel grace period and return */
        if (mtroller.liquidateERC721Allowed(mToken) != uint(Error.NO_ERROR)) {
            lastBlockGracePeriod[mToken] = 0;
            preferredLiquidator[mToken] = address(0);
            return fail(Error.MTROLLER_REJECTION, FailureInfo.AUCTION_NOT_ALLOWED);
        }

        /* If no grace period currently ongoing, start new one and set sender as preferred liquidator */
        if (lastBlockGracePeriod[mToken] == 0) {
            lastBlockGracePeriod[mToken] = getBlockNumber() + auctionGracePeriod;
            preferredLiquidator[mToken] = msg.sender;
        }
        /* If grace period currently ongoing, admin (only) can restart it but not change the liquidator */ 
        else {
            if (msg.sender == getAdmin()) {
                lastBlockGracePeriod[mToken] = getBlockNumber() + auctionGracePeriod;
            } else {
                return fail(Error.UNAUTHORIZED, FailureInfo.LIQUIDATE_GRACE_PERIOD_NOT_EXPIRED);
            }
        }

        emit GracePeriod(mToken, lastBlockGracePeriod[mToken]);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sender liquidates non-fungible (ERC-721) collateral into collateral for a "payment token"
     * (for this, any fungible token such as ETH can be chosen when deploying the TokenAuction contract)
     * Before this can be done, four conditions have to be met:
     * 1. There needs to have been a TokenAuction for the mToken collateral resulting in a highest
     *    bid, where bids are submitted in the "payment token" currency
     * 2. The highest bid needs to be higher than the minimumOfferMantissa * getPrice(mToken)
     * 3. The owner of the collateral needs to have a shortfall (i.e., negative liquidity)
     * 4. Since the shortfall occurred, a grace period was started with startGracePeriod() and has
     *    expired without the collateral's owner having removed his shortfall in the meantime
     * After the collateral has successfully been converted into collateral for the "payment token" then
     * in a next step anybody can liquidate this (fungible) "payment token" collateral as usual
     * @dev Reverts upon any failure
     * @param mToken The non-fungible collateral to be liquidated into "payment token" collateral
     * @return (uint, uint240, uint, uint) Unless reverted, returns:
     *         (error code: 0=success, otherwise a failure (see ErrorReporter.sol for details),
     *          the payment mToken, 
     *          the amount (fee) of payment token paid to the liquidator, 
     *          the amount of payment token paid to the previous owner)
     */
    function liquidateToPaymentToken(uint240 mToken) external nonReentrant returns (uint, uint240, uint, uint) {
        /* If liquidation is not allowed (anymore) we reset the gracePeriod and fail */
        if (mtroller.liquidateERC721Allowed(mToken) != uint(Error.NO_ERROR)) {
            lastBlockGracePeriod[mToken] = 0;
            preferredLiquidator[mToken] = address(0);
            return (fail(Error.MTROLLER_REJECTION, FailureInfo.LIQUIDATE_MTROLLER_REJECTION), 0, 0, 0);
        }

        /* Check if gracePeriod has expired */
        uint256 gracePeriod = lastBlockGracePeriod[mToken];
        if (gracePeriod == 0 || getBlockNumber() <= gracePeriod) {
            return (fail(Error.UNAUTHORIZED, FailureInfo.LIQUIDATE_GRACE_PERIOD_NOT_EXPIRED), 0, 0, 0);
        }

        /* Check if preferredLiquidator conditions apply */
        if (getBlockNumber() <= (gracePeriod + preferredLiquidatorHeadstart) 
                && msg.sender != preferredLiquidator[mToken]) {
            return (fail(Error.UNAUTHORIZED, FailureInfo.LIQUIDATE_NOT_PREFERRED_LIQUIDATOR), 0, 0, 0);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        lastBlockGracePeriod[mToken] = 0;
        preferredLiquidator[mToken] = address(0);
        
        /* minimum offer required to win the auction =  minimumOfferMantissa * mtroller.getPrice() */
        uint minimumOffer = mul_ScalarTruncate(Exp({mantissa: minimumOfferMantissa}), mtroller.getPrice(mToken));

        /* accepts highest auction bid, reverts on error */
        address oldOwner = ownerOf(mToken);
        (address maxOfferor, , uint256 auctioneerTokens, uint256 oldOwnerTokens) 
                = tokenAuction.acceptHighestOffer(mToken, oldOwner, msg.sender, liquidatorAuctionFeeMantissa, minimumOffer);

        /* seize mToken, i.e. transfer from oldOwner to maxOfferor. Revert on error. */
        uint err = seizeInternal(mToken, maxOfferor, oldOwner, mToken, oneUnit);
        requireNoError(err, "TSF");

        /* Perform mERC721-specific cleanup actions (e.g., resetting askingPrice and exiting market) */
        cleanUpAfterTokenTransferInternal(mToken, oldOwner);

        /* Execute the ERC-721 specific transfer for the mToken (safeTransferFrom without calling transferTokens) */
        super._transferFrom(oldOwner, maxOfferor, mToken);
        require(_checkOnERC721Received(oldOwner, maxOfferor, mToken, ""), "LNE");

        emit LiquidateToPaymentToken(oldOwner, maxOfferor, mToken, auctioneerTokens, oldOwnerTokens);

        return (uint(Error.NO_ERROR), MTokenUser(address(tokenAuction.paymentToken())).thisFungibleMToken(), auctioneerTokens, oldOwnerTokens);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Always fails since non-fungible (ERC-721) collaterals cannot be seized directly but have to be
     * liquidated in a process using TokenAuction with grace period and then liquidateToPaymentToken().
     * @param mTokenBorrowed The mToken doing the seizing (i.e., borrowed mToken market)
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param mTokenCollateral The mToken to seize (this market)
     * @param seizeTokens The number of mTokenCollateral tokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function seize(uint240 mTokenBorrowed, address liquidator, address borrower, uint240 mTokenCollateral, uint seizeTokens) external nonReentrant returns (uint) {
        mTokenBorrowed;
        liquidator;
        borrower;
        mTokenCollateral;
        seizeTokens;
        return fail(Error.INVALID_COLLATERAL, FailureInfo.LIQUIDATE_SEIZE_NON_FUNGIBLE_ASSET);
    }


    /*** Admin Functions ***/

    // /**
    //  * @notice The sender adds to reserves.
    //  * @param mToken The mToken whose reserves to increase
    //  * @param addAmount Amount of addition to reserves
    //  * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
    //  */
    // function _addReserves(uint240 mToken, uint addAmount) external payable returns (uint) {
    //     mToken;
    //     addAmount;
    //     /* Adding to reserves not allowed for now */
    //     uint err = fail(Error.UNAUTHORIZED, FailureInfo.SET_RESERVE_FACTOR_ADMIN_CHECK);
    //     requireNoError(err, "NIM");
    //     return 0;
    // }

    /**
     * @notice In case of any other action (e.g., ETH being sent to contract), revert
     */
    function () external payable {
        revert("INV");
    }

   /*** Safe Token ***/

    /**
     * @notice Transfers an underlying NFT asset into this contract
     * @dev Performs a transfer in, reverting upon failure. This may revert due to insufficient 
     * balance or insufficient allowance.
     * @param from The address where to transfer underlying asset from
     * @param underlyingID The ID of the underlying asset
     * @param amount The amount of underlying to transfer, must be == oneUnit here
     * @return (uint) Returns the value of the input parameter `amount`.
     */
    function doTransferIn(address from, uint256 underlyingID, uint amount) internal returns (uint) {
        /* NFT assets are always received in (virtual) amounts of `oneUnit` */
        require(amount == oneUnit, "AOU");
        IERC721(underlyingContract).safeTransferFrom(from, address(this), underlyingID);

        /* Check if transfer succeeded and cancel any (possibly) left-over approval */
        require(IERC721(underlyingContract).ownerOf(underlyingID) == address(this), "TIF");
        require(IERC721(underlyingContract).getApproved(underlyingID) == address(0), "TIA");
        return amount;
    }
}