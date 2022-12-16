pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./MtrollerInterface.sol";
import "./TokenAuction.sol";
import "./compound/InterestRateModel.sol";
import "./compound/EIP20NonStandardInterface.sol";
import "./open-zeppelin/token/ERC721/IERC721Metadata.sol";

contract MTokenCommonInterface is MTokenIdentifier, MDelegatorIdentifier {

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint240 mToken, uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Events emitted when tokens are minted
     */
    event Mint(address minter, address beneficiary, uint mintAmountUnderlying, uint240 mTokenMinted, uint amountTokensMinted);

    /**
     * @notice Events emitted when tokens are transferred
     */
    event Transfer(address from, address to, uint240 mToken, uint amountTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint240 mToken, uint redeemTokens, uint256 underlyingID, uint underlyingRedeemAmount);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 underlyingID, uint borrowAmount, uint paidOutAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when underlying is borrowed in a flash loan operation
     */
    event FlashBorrow(address borrower, uint256 underlyingID, address receiver, uint downPayment, uint borrowAmount, uint paidOutAmount);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint256 underlyingID, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint240 mTokenBorrowed, uint repayAmountUnderlying, uint240 mTokenCollateral, uint seizeTokens);

    /**
     * @notice Event emitted when a grace period is started before liquidating a token with an auction
     */
    event GracePeriod(uint240 mTokenCollateral, uint lastBlockOfGracePeriod);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when flash receiver whitlist is changed
     */
    event FlashReceiverWhitelistChanged(address receiver, bool newState);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when tokenAuction is changed
     */
    event NewTokenAuction(TokenAuction oldTokenAuction, TokenAuction newTokenAuction);

    /**
     * @notice Event emitted when mtroller is changed
     */
    event NewMtroller(MtrollerInterface oldMtroller, MtrollerInterface newMtroller);

    /**
     * @notice Event emitted when global protocol parameters are updated
     */
    event NewGlobalProtocolParameters(uint newInitialExchangeRateMantissa, uint newReserveFactorMantissa, uint newProtocolSeizeShareMantissa, uint newBorrowFeeMantissa);

    /**
     * @notice Event emitted when global auction parameters are updated
     */
    event NewGlobalAuctionParameters(uint newAuctionGracePeriod, uint newPreferredLiquidatorHeadstart, uint newMinimumOfferMantissa, uint newLiquidatorAuctionFeeMantissa, uint newProtocolAuctionFeeMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint240 mToken, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint240 mToken, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);


    function getAdmin() public view returns (address payable admin);
    function accrueInterest(uint240 mToken) public returns (uint);
}

contract MTokenAdminInterface is MTokenCommonInterface {

    /// @notice Indicator that this is a admin part contract (for inspection)
    function isMDelegatorAdminImplementation() public pure returns (bool);

    /*** Admin Functions ***/

    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint);
    function _setTokenAuction(TokenAuction newTokenAuction) public returns (uint);
    function _setMtroller(MtrollerInterface newMtroller) public returns (uint);
    function _setGlobalProtocolParameters(uint _initialExchangeRateMantissa, uint _reserveFactorMantissa, uint _protocolSeizeShareMantissa, uint _borrowFeeMantissa) public returns (uint);
    function _setGlobalAuctionParameters(uint _auctionGracePeriod, uint _preferredLiquidatorHeadstart, uint _minimumOfferMantissa, uint _liquidatorAuctionFeeMantissa, uint _protocolAuctionFeeMantissa) public returns (uint);
    function _reduceReserves(uint240 mToken, uint reduceAmount) external returns (uint);
    function _sweepERC20(address tokenContract) external returns (uint);
    function _sweepERC721(address tokenContract, uint256 tokenID) external;
}

contract MTokenUserInterface is MTokenCommonInterface {

    /// @notice Indicator that this is a user part contract (for inspection)
    function isMDelegatorUserImplementation() public pure returns (bool);

    /*** User Interface ***/

    function balanceOf(address owner, uint240 mToken) external view returns (uint);
    function getAccountSnapshot(address account, uint240 mToken) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock(uint240 mToken) external view returns (uint);
    function supplyRatePerBlock(uint240 mToken) external view returns (uint);
    function totalBorrowsCurrent(uint240 mToken) external returns (uint);
    function borrowBalanceCurrent(address account, uint240 mToken) external returns (uint);
    function borrowBalanceStored(address account, uint240 mToken) public view returns (uint);
    function exchangeRateCurrent(uint240 mToken) external returns (uint);
    function exchangeRateStored(uint240 mToken) external view returns (uint);
    function getCash(uint240 mToken) external view returns (uint);
    function seize(uint240 mTokenBorrowed, address liquidator, address borrower, uint240 mTokenCollateral, uint seizeTokens) external returns (uint);
}

contract MTokenInterface is MTokenAdminInterface, MTokenUserInterface {}

contract MFungibleTokenAdminInterface is MTokenAdminInterface {
}

contract MFungibleTokenUserInterface is MTokenUserInterface{

    /*** Market Events ***/

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
}

contract MFungibleTokenInterface is MFungibleTokenAdminInterface, MFungibleTokenUserInterface {}

contract MEtherAdminInterface is MFungibleTokenAdminInterface {

    /*** Admin Functions ***/

    function initialize(MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                uint reserveFactorMantissa_,
                uint initialExchangeRateMantissa_,
                uint protocolSeizeShareMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_) public;

    /*** User Interface ***/

    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function flashBorrow(uint borrowAmount, address payable receiver, bytes calldata flashParams) external payable returns (uint);
    function name() public view returns (string memory);
    function symbol() public view returns (string memory);
    function decimals() public view returns (uint8);
}

contract MEtherUserInterface is MFungibleTokenUserInterface {

    /*** Admin Functions ***/

    function getProtocolAuctionFeeMantissa() external view returns (uint);
    function _addReserves() external payable returns (uint);

    /*** User Interface ***/

    function mint() external payable returns (uint);
    function mintTo(address beneficiary) external payable returns (uint);
    function repayBorrow() external payable returns (uint);
    function repayBorrowBehalf(address borrower) external payable returns (uint);
    function liquidateBorrow(address borrower, uint240 mTokenCollateral) external payable returns (uint);
}

contract MEtherInterface is MEtherAdminInterface, MEtherUserInterface {}

contract MERC721AdminInterface is MTokenAdminInterface, IERC721, IERC721Metadata {

    event NewTokenAuctionContract(TokenAuction oldTokenAuction, TokenAuction newTokenAuction);

    /*** Admin Functions ***/

    function initialize(address underlyingContract_,
                MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                TokenAuction tokenAuction_,
                string memory name_,
                string memory symbol_) public;

    /*** User Interface ***/

    function redeem(uint240 mToken) public returns (uint);
    function redeemUnderlying(uint256 underlyingID) external returns (uint);
    function redeemAndSell(uint240 mToken, uint sellPrice, address payable transferHandler, bytes memory transferParams) public returns (uint);
    function borrow(uint256 borrowUnderlyingID) external returns (uint);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract MERC721UserInterface is MTokenUserInterface, IERC721 {

    event LiquidateToPaymentToken(address indexed oldOwner, address indexed newOwner, uint240 mToken, uint256 auctioneerTokens, uint256 oldOwnerTokens);

    /*** Admin Functions ***/

//    function _addReserves(uint240 mToken, uint addAmount) external payable returns (uint);

    /*** User Interface ***/

    function mintAndCollateralizeTo(address beneficiary, uint256 underlyingTokenID) external returns (uint240);
    function mintTo(address beneficiary, uint256 underlyingTokenID) public returns (uint240);
//    function repayBorrow(uint256 repayUnderlyingID) external payable returns (uint);
//    function repayBorrowBehalf(address borrower, uint256 repayUnderlyingID) external payable returns (uint);
//    function liquidateBorrow(address borrower, uint256 repayUnderlyingID, uint240 mTokenCollateral) external payable returns (uint);
    function addAuctionBid(uint240 mToken) external payable;
    function instantSellToHighestBidder(uint240 mToken, uint256 minimumPrice, address favoriteBidder) public;
    function setAskingPrice(uint240 mToken, uint256 newAskingPrice) external;
    function startGracePeriod(uint240 mToken) external returns (uint);
    function liquidateToPaymentToken(uint240 mToken) external returns (uint);
}

contract MERC721Interface is MERC721AdminInterface, MERC721UserInterface {}

contract FlashLoanReceiverInterface {
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external returns (uint);
    function executeTransfer(uint256 tokenId, address payable seller, uint sellPrice, bytes calldata transferParams) external returns (uint);
}