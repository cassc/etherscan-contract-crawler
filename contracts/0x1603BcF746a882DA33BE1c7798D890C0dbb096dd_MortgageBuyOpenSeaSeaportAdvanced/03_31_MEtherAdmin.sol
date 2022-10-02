pragma solidity ^0.5.16;

import "./MFungibleTokenAdmin.sol";
import "./MTokenInterfaces.sol";
import "./MtrollerInterface.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./compound/EIP20Interface.sol";
import "./compound/InterestRateModel.sol";

/**
 * @title Contract for fungible tokens
 * @notice Abstract base for fungible MTokens
 * @author mmo.finance, based on Compound
 */
contract MEtherAdmin is MFungibleTokenAdmin, MEtherAdminInterface {

    /**
     * @notice Constructs a new MEtherAdmin
     */
    constructor() public MFungibleTokenAdmin() {
        implementedSelectors.push(bytes4(keccak256('isMEtherAdminImplementation()')));
        implementedSelectors.push(bytes4(keccak256('initialize(address,address,uint256,uint256,uint256,string,string,uint8)')));
        implementedSelectors.push(bytes4(keccak256('redeem(uint256)')));
        implementedSelectors.push(bytes4(keccak256('redeemUnderlying(uint256)')));
        implementedSelectors.push(bytes4(keccak256('borrow(uint256)')));
        implementedSelectors.push(bytes4(keccak256('flashBorrow(uint256,address,bytes)')));
        implementedSelectors.push(bytes4(keccak256('name()')));
        implementedSelectors.push(bytes4(keccak256('symbol()')));
        implementedSelectors.push(bytes4(keccak256('decimals()')));
    }

    /**
     * @notice Initialize a new MEther money market
     * @param mtroller_ The address of the Mtroller
     * @param interestRateModel_ The address of the interest rate model
     * @param reserveFactorMantissa_ The fraction of interest to set aside for reserves, scaled by 1e18
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param protocolSeizeShareMantissa_ The fraction of seized collateral added to reserves, scaled by 1e18
     * @param name_ EIP-20 name of this MToken
     * @param symbol_ EIP-20 symbol of this MToken
     * @param decimals_ EIP-20 decimal precision of this MToken
     */
    function initialize(MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                uint reserveFactorMantissa_,
                uint initialExchangeRateMantissa_,
                uint protocolSeizeShareMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_) public {
        MFungibleTokenAdmin.initialize(mtroller_.underlyingContractETH(), mtroller_, interestRateModel_, 
                    reserveFactorMantissa_, initialExchangeRateMantissa_, protocolSeizeShareMantissa_, 
                    name_, symbol_, decimals_);
    }

    /**
     * @notice Sender redeems mTokens in exchange for the underlying asset (ETH)
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of mTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external nonReentrant returns (uint) {
        return redeemInternal(thisFungibleMToken, redeemTokens, 0, msg.sender, 0, address(0), "");
    }

    /**
     * @notice Sender redeems mTokens in exchange for a specified amount of underlying asset (ETH)
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external nonReentrant returns (uint) {
        return redeemInternal(thisFungibleMToken, 0, redeemAmount, msg.sender, 0, address(0), "");
    }

    /**
      * @notice Sender enters MEther market and borrows assets from the protocol to their own address.
      * @param borrowAmount The amount of the underlying asset (ETH) to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint borrowAmount) external returns (uint) {
        uint err = mtroller.enterMarketOnBehalf(thisFungibleMToken, msg.sender);
        requireNoError(err, "enter market failed");
        return borrowInternal(thisFungibleMToken, borrowAmount);
    }

    /**
     * @notice Sender borrows ETH from the protocol to a receiver address in spite of having 
     * insufficient collateral, but repays borrow or adds collateral to correct balance in the same block
     * Any ETH the sender sends with this payable function are considered a down payment and are
     * also transferred to the receiver address
     * @param borrowAmount The amount of the underlying asset (Wei) to borrow
     * @param receiver The address receiving the borrowed funds. This address must be able to receive
     * the corresponding underlying of mToken and it must implement FlashLoanReceiverInterface.
     * @param flashParams Any other data necessary for flash loan repayment
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function flashBorrow(uint borrowAmount, address payable receiver, bytes calldata flashParams) external payable returns (uint) {
        uint err = mtroller.enterMarketOnBehalf(thisFungibleMToken, msg.sender);
        requireNoError(err, "enter market failed");
        return flashBorrowInternal(thisFungibleMToken, msg.value, borrowAmount, receiver, flashParams);
    }

    function name() public view returns (string memory) {
        return mName;
    }

    function symbol() public view returns (string memory) {
        return mSymbol;
    }

    function decimals() public view returns (uint8) {
        return mDecimals;
    }

    function doTransferOut(address payable to, uint256 underlyingID, uint amount, uint sellPrice, address payable transferHandler, bytes memory transferParams) internal returns (uint) {
        // Sanity checks
        require(underlyingIDs[thisFungibleMToken] == underlyingID, "underlying tokenID mismatch");
        /* Send the Ether, with minimal gas and revert on failure */
        if (transferHandler == address(0)) {
            // transfer without subsequent sale to a third party
            to.transfer(amount);
        }
        else {
            // transfer followed by sale to a third party (handled by transferHandler)
            sellPrice;
            transferParams;
            revert("not implemented");
        }
        return amount;
    }

    /**
     * @notice Transfers underlying assets from sender to a beneficiary (e.g. for flash loan down payment)
     * @dev Performs a transfer from, reverting upon failure (e.g. insufficient allowance from owner)
     * @param to the address where to transfer underlying assets to
     * @param underlyingID the ID of the underlying asset (in case of a NFT) or 1 (in case of a fungible asset)
     * @param amount the amount of underlying to transfer (for fungible assets) or oneUnit (for NFTs)
     * @return (uint) Returns the amount actually transferred (lower in case of a fee).
     */
    function doTransferOutFromSender(address payable to, uint256 underlyingID, uint amount) internal returns (uint) {
        require(underlyingIDs[thisFungibleMToken] == underlyingID, "underlying tokenID mismatch");
        require(msg.value == amount, "value mismatch");
        /* Send the Ether, with minimal gas and revert on failure */
        to.transfer(amount);
        return amount;
    }
}

contract MEtherInterfaceFull is MEtherAdmin, MEtherInterface {}