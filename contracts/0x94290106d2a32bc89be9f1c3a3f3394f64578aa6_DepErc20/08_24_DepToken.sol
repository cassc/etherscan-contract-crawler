// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "hardhat/console.sol";

import "./MatrixpricerInterface.sol";
import "./DepTokenInterfaces.sol";
import "./ErrorReporter.sol";
import "./EIP20Interface.sol";
import "./InterestRateModel.sol";
import "./ExponentialNoError.sol";
//import { DepositWithdrawInterface } from "./DepositWithdrawInterface.sol";
import { CurveContractInterface } from "./CurveContractInterface.sol";
import "./DepositWithdraw.sol";
import "./CurveSwap.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title DepToken Contract
 * @notice Abstract base for DepTokens
 * @author Vortex
 */
abstract contract DepToken is DepTokenInterface, DepositWithdraw, CurveSwap, ExponentialNoError, TokenErrorReporter, Initializable {

    /**
     * @notice set the levErc20 token
     * @param levErc20_ The address of the associated levErc20
     *
    function setLevErc20(LevErc20Interface levErc20_) public virtual {
        require(msg.sender == admin, "only admin may set leverc20");
        levErc20 = levErc20_;
    }*/

    /**
     * @notice Initialize the money market
     * @param matrixpricer_ The address of the Matrixpricer
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ EIP-20 name of this token
     * @param symbol_ EIP-20 symbol of this token
     * @param decimals_ EIP-20 decimal precision of this token
     * @param levErc20_ The address of the associated levErc20
     */
    function initialize(address underlying_,
                        MatrixpricerInterface matrixpricer_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_,
                        LevErc20Interface levErc20_
                        ) public virtual onlyInitializing {
//        console.log("msg.sender is, ", address(msg.sender));
//        console.log("admin is: ", admin);
        require(msg.sender == admin, "only admin may initialize the market");
        require(accrualBlockNumber == 0 && borrowIndex == 0, "market may only be initialized once");

        // Set initial exchange rate
        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        require(initialExchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

        // Set the matrixpricer
        uint err = _setMatrixpricer(matrixpricer_);
        require(err == NO_ERROR, "setting matrixpricer failed");

        // Initialize block number and borrow index (block number mocks depend on matrixpricer being set)
        accrualBlockNumber = getBlockNumber();
        borrowIndex = mantissaOne;

        // Set the interest rate model (depends on block number / borrow index)
        err = _setInterestRateModelFresh(interestRateModel_);
        require(err == NO_ERROR, "setting interest rate model failed");

        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        levErc20 = levErc20_;

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
//        console.log("depErc20 initialize success");
    }

    /**
     * @notice Initialize the compound portion
     * @param compoundV2cUSDCAddress_ The address of the cUSDC
     * @param compoundV2cUSDTAddress_ The address of the cUSDT
     * @param USDCAddress_ The address of USDC
     * @param USDTAddress_ The address of USDT
    */
    function setAddressesForCompound(address compoundV2cUSDCAddress_, address compoundV2cUSDTAddress_, address USDCAddress_, address USDTAddress_) public {
        require(msg.sender==admin, "only admin can set addresses in general");
        setAddresses(compoundV2cUSDCAddress_, compoundV2cUSDTAddress_, USDCAddress_, USDTAddress_);
    }

    /**
     * @notice Initialize the curve portion
     * @param TriPool_ The address of the Tripool
     * @param ADDRESSPROVIDER_ The address of the curve provider
     * @param USDC_ADDRESS_ The address of USDC
     * @param USDT_ADDRESS_ The address of USDT
    */
    function setAddressesForCurve(address TriPool_, address ADDRESSPROVIDER_, address USDC_ADDRESS_, address USDT_ADDRESS_) public {
        require(msg.sender==admin, "only admin can set addresses in general");
        setAddressesCurve(TriPool_, ADDRESSPROVIDER_, USDC_ADDRESS_, USDT_ADDRESS_);
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     * @return 0 if the transfer succeeded, else revert
     */
    function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {
        /* Fail if transfer not allowed */
        uint allowed = matrixpricer.transferAllowed(address(this), src, dst, tokens);
        if (allowed != 0) {
            revert TransferMatrixpricerRejection(allowed);   // change the name
        }

        /* Do not allow self-transfers */
        if (src == dst) {
            revert TransferNotAllowed();
        }

        /* Get the allowance, infinite for the account owner */
        uint startingAllowance = 0;
        if (spender == src) {
            startingAllowance = type(uint).max;
        } else {
            startingAllowance = transferAllowances[src][spender];
            if(startingAllowance < tokens){
                revert TransferNotEnoughAllowance();
            }
        }

        /* Do the calculations, checking for {under,over}flow */
        uint allowanceNew = startingAllowance - tokens;
        uint srDepTokensNew = accountTokens[src] - tokens;
        uint dstTokensNew = accountTokens[dst] + tokens;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accountTokens[src] = srDepTokensNew;
        accountTokens[dst] = dstTokensNew;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != type(uint).max) {
            transferAllowances[src][spender] = allowanceNew;
        }

        /* We emit a Transfer event */
        emit Transfer(src, dst, tokens);

        return NO_ERROR;
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) override external nonReentrant returns (bool) {
        return transferTokens(msg.sender, msg.sender, dst, amount) == NO_ERROR;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) override external nonReentrant returns (bool) {
        return transferTokens(msg.sender, src, dst, amount) == NO_ERROR;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (uint256.max means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) override external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) override external view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) override external view returns (uint256) {
        return accountTokens[owner];
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) override external returns (uint) {
        Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
        return mul_ScalarTruncate(exchangeRate, accountTokens[owner]);
    }

    /**
     * @notice Get the underlying balance of the `owner`, view only
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlyingView(address owner) override external view returns (uint) {
        return balanceOfUnderlyingViewInternal(owner);
    }

    function balanceOfUnderlyingViewInternal(address owner) internal view returns (uint) {
        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal()});
        return mul_ScalarTruncate(exchangeRate, accountTokens[owner]);
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by matrixpricer to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account) override external view returns (uint, uint, uint, uint) {
        // console.log("account snapshot acct tokens", accountTokens[account]);
        return (
            NO_ERROR,
            accountTokens[account],
            borrowBalanceStoredInternal(account),
            exchangeRateStoredInternal()
        );
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() virtual internal view returns (uint) {
        return block.number;
    }

    function getBNumber() public view returns (uint) {
        return block.number;
    }

    /**
     * notice Returns the current per-block borrow interest rate for this DepToken
     * return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() override external view returns (uint) {
        uint iur = idealUtilizationRate();
        return interestRateModel.getBorrowRate(iur, getCmpUSDTSupplyRate());
    }

    /**
     * notice Returns the current per-block supply interest rate for this DepToken
     * return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() override public view returns (uint) {
        // there are 3 components to this:
        // a, unused cash - no interest
        // b, borrowed cash - earn loan interest
        // c, cash in compound - earn compound interest
        
        // our supplyRate function takes care of a+b
        uint iur = idealUtilizationRate();
        uint ownSupplyRatePerBlock = interestRateModel.getSupplyRate(iur, getCmpUSDTSupplyRate());   // for borrowed portion
        uint avgRate;
        if(totalSupply>0){
            uint unusedCash = getCashExReserves();
            // compound stuff below
            uint compoundUSDTBalance = getCmpBalanceInternal();
            uint compoundSupplyRatePerBlock = getCmpUSDTSupplyRate();
            avgRate  = (ownSupplyRatePerBlock * totalBorrows + compoundUSDTBalance*compoundSupplyRatePerBlock) / (unusedCash + totalBorrows + compoundUSDTBalance);
        }else{
            avgRate = ownSupplyRatePerBlock;    // assume fully lend out. doesnt matter really, just initial indication
        }
        return avgRate;
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() override external nonReentrant returns (uint) {
        accrueInterest();
        return totalBorrows;
    }

    /**
     * @notice Returns the current total borrows
     * @return The total borrows
     */
    function getTotalBorrowsInternal() internal view returns (uint) {
        return totalBorrows;
    }

    function getTotalBorrowsAfterAccrueInterestInternal() internal returns (uint) {
        accrueInterest();
        return totalBorrows;
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     *
    function borrowBalanceCurrent(address account) override external nonReentrant returns (uint) {
        accrueInterest();
        return borrowBalanceStored(account);
    }*/

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     *
    function borrowBalanceStored(address account) override internal view returns (uint) {
        return borrowBalanceStoredInternal(account);
    }*/

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function borrowBalanceStoredInternal(address account) internal view returns (uint) {
        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];
        
        // console.log("borrow bal snapshot principal ", borrowSnapshot.principal);
        // console.log("borrow bal snapshot interestIndex ", borrowSnapshot.interestIndex);
        // console.log("borrow bal borrow index ", borrowIndex);

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return 0;
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        uint principalTimesIndex = borrowSnapshot.principal * borrowIndex;
        return principalTimesIndex / borrowSnapshot.interestIndex;
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() override public nonReentrant returns (uint) {
        accrueInterest();
        return exchangeRateStored();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the DepToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() override public view returns (uint) {
        return exchangeRateStoredInternal();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the DepToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return calculated exchange rate scaled by expScale (=1e18)
     */
    function exchangeRateStoredInternal() virtual internal view returns (uint) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            /*
             * If there are no tokens minted:
             *  exchangeRate = initialExchangeRate
             *  usdt and deptoken both have decimals=6, so initexchrate is naturally 1
             */
            return initialExchangeRateMantissa;
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
             */
            
            uint totalCashMinusReserves = getCashExReserves() + getCmpBalanceInternal();  // 1e6
            uint cashPlusBorrowsMinusReserves = totalCashMinusReserves + totalBorrows;   // 1e6
//            console.log("exchangeRateStoredInternal - totalCashMinusReserves:", totalCashMinusReserves);
//            console.log("exchangeRateStoredInternal - cashPlusBorrowsMinusReserves:", cashPlusBorrowsMinusReserves);
            uint exchangeRate = cashPlusBorrowsMinusReserves * expScale / _totalSupply;
//            console.log("exRate=", exchangeRate);
            return exchangeRate;
        }
    }

    /**
     * @notice Get cash balance of this DepToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() override external view returns (uint) {
        return getCashPrior();
    }

    function getCashExReserves() internal view returns (uint) {
        uint allCash = getCashPrior();
//        console.log("getCashExReserves - allCash", allCash);
        if(allCash > totalReserves){
            return allCash - totalReserves;
        }else{
            return 0;
        }
    }

    /**
     * @notice Get cash balance deposited at compound
     * @return The quantity of underlying asset owned by this contract
     */
    function getCompoundBalance() override external view returns (uint) {
        return getCmpBalanceInternal();
    }

    function getCmpBalanceInternal() virtual internal view returns (uint) {
        Exp memory exchangeRate = Exp({mantissa: getCmpUSDTExchRate()});
        return mul_ScalarTruncate(exchangeRate, getCUSDTNumber());
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @dev This calculates interest accrued from the last checkpoint block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() virtual override public returns (uint) {
        // Remember the initial block number
        uint currentBlockNumber = getBlockNumber(); // the blocknumber on chain
        uint accrualBlockNumberPrior = accrualBlockNumber;  // blocknumber after last calc

        // if no activity on chain since last calc, nothing to compute
        if (accrualBlockNumberPrior == currentBlockNumber) {
            return NO_ERROR;
        }

        // Read the previous values out of storage
        uint cashPrior = getCashExReserves();    // 1e6
        uint borrowsPrior = totalBorrows;   // 1e6
        uint reservesPrior = totalReserves; // 1e6
        uint borrowIndexPrior = borrowIndex;

        // Calculate the current borrow interest rate
        uint compoundBorrowRatePerBlock = getCmpUSDTSupplyRate();   // always use supplyrate, because that's what we can get
//        console.log("Compound Borrow Rate Per Block is: ", compoundBorrowRatePerBlock);
        uint iur = idealUtilizationRate();
//        console.log("iur is: ", iur);
        uint borrowRateMantissa = interestRateModel.getBorrowRate(iur, compoundBorrowRatePerBlock); // it's per block

        // Calculate the number of blocks elapsed since the last accrual
        uint blockDelta = currentBlockNumber - accrualBlockNumberPrior;

//        console.log("Block Delta is: ", blockDelta);
//        console.log("accrualBlockNumberPrior,currentBlockNumber,borrowRateMantissa=%d,%d,%d",accrualBlockNumberPrior,currentBlockNumber,borrowRateMantissa);
//        console.log("iur=",iur);

        //  principle:
        //  time is proxied by #blocks elapsed. rates were converted to annual rate per block
        //  calculate interest, and update borrows, reserves, and borrowIndex
        //  simpleInterestFactor = borrowRate * blockDelta
        //  interestAccumulated = simpleInterestFactor * totalBorrows
        //  totalBorrowsNew = interestAccumulated + totalBorrows
        //  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
        //  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex

        Exp memory simpleInterestFactor = mul_(Exp({mantissa: borrowRateMantissa}), blockDelta);
        uint interestAccumulated = mul_ScalarTruncate(simpleInterestFactor, borrowsPrior);
        uint totalBorrowsNew = interestAccumulated + borrowsPrior;
        uint totalReservesNew = mul_ScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, reservesPrior);
        uint borrowIndexNew = mul_ScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);

//        console.log("reserveFactorMantissa=", reserveFactorMantissa);
//        console.log("borrowRateMantissa=", borrowRateMantissa);
//        console.log("blockDelta=", blockDelta);
//        console.log("interestAccumulated=",interestAccumulated);
        
        // persist the new values
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;
//        console.log("borrowIndex: ", borrowIndex);
//        console.log("totalBorrows: ", totalBorrows);
//        console.log("totalReserves: ", totalReserves);

        // We emit an AccrueInterest event
        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return NO_ERROR;
    }

    /**
     * @notice Sender supplies assets into the market and receives DepTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     */
    function mintInternal(uint mintAmount) internal nonReentrant {
        accrueInterest();
        // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
        // console.log("mint internal msg sender is ", msg.sender);
        mintFresh(msg.sender, mintAmount);
    }

    /**
     * @notice check if sufficient USDT to push to compound
     * @dev
     * @return if true, then transfer
     */
    function checkCompound(uint currUSDTBalance) internal pure returns (bool) {
        if(currUSDTBalance > minTransferAmtUSDT+thresholdUSDT){
            return true;
        }else{
            return false;
        }
    }

    /**
     * @notice User supplies assets into the market and receives DepTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param minter The address of the account which is supplying the assets
     * @param mintAmount The amount of the underlying asset to supply
     */
    function mintFresh(address minter, uint mintAmount) internal {
        /* Fail if mint not allowed */
        // console.log("mint fresh this deptoken addr ", address(this));
        uint allowed = matrixpricer.mintAllowed(address(this), minter);
        if (allowed != 0) {
            revert MintMatrixpricerRejection(allowed);
        }

        /* after the updates in accrualInterest(), these should match */
        if (accrualBlockNumber != getBlockNumber()) {
            revert MintFreshnessCheck();
        }

        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal()});
        //console.log("mintFresh - exchangeRate is: ", exchangeRate.mantissa);
        // start executing transfers according to the completed calculations

        /*
         *  We call `doTransferIn` for the minter and the mintAmount.
         *  Note: The DepToken can only handle USDT!
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if side-effects occurred. 
         *  The function returns the amount actually transferred, after gas. 
         *  On success, the DepToken holds an additional `actualMintAmount` of cash.
         */
        uint actualMintAmount = doTransferIn(minter, mintAmount);
        //console.log("mintFresh - actualMintAmount is: ",  actualMintAmount);
        /*
         * We get the current exchange rate and calculate the number of DepTokens to be minted:
         *  mintTokens = actualMintAmount / exchangeRate
         */

        uint mintTokens = div_(actualMintAmount, exchangeRate);
//        console.log("deptoken actual mint amount=", actualMintAmount);
//        console.log("deptoken Mint Token amount=", mintTokens);
        /*
         * We calculate the new total supply of DepTokens and minter token balance, checking for overflow:
         *  totalSupplyNew = totalSupply + mintTokens
         *  accountTokensNew = accountTokens[minter] + mintTokens
         * And write them into storage
         */
        totalSupply = totalSupply + mintTokens;
        accountTokens[minter] = accountTokens[minter] + mintTokens;

        // deposit mintAmount to compound V2
        uint currUSDTBalance = getCashExReserves();  // usdt in this contract, 1e6
        if(checkCompound(currUSDTBalance)){
            supplyUSDT2Cmp(currUSDTBalance - thresholdUSDT);
        }

        /* We emit a Mint event, and a Transfer event */
        emit Mint(minter, actualMintAmount, mintTokens, supplyRatePerBlock());
        emit Transfer(address(this), minter, mintTokens);
    }

    /**
     * @notice Sender redeems DepTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokensIn The number of DepTokens to redeem into underlying
     * @param redeemAmountIn The amount of underlying to receive from redeeming DepTokens
     */
    function redeemInternal(uint redeemTokensIn, uint redeemAmountIn) internal nonReentrant {
        accrueInterest();
        // redeemFresh emits redeem-specific logs on errors, so we don't need to
        require(redeemTokensIn > 0 && redeemAmountIn == 0, "do not support redeemAmountIn");

        // compute fresh exchange rate
        Exp memory exchangeRate = Exp({mantissa: exchangeRateStoredInternal() });
        // console.log("redeem fresh exchange rate ", exchangeRate.mantissa);

        /*
        uint redeemTokens;
        uint redeemAmount;
        
        if (redeemTokensIn > 0) {
            
            // We calculate the exchange rate and the amount of underlying to be redeemed:
            //  redeemTokens = redeemTokensIn
            //  redeemAmount = redeemTokensIn x exchangeRateCurrent
            redeemTokens = redeemTokensIn;
            redeemAmount = mul_ScalarTruncate(exchangeRate, redeemTokensIn);
        } else {
            // We get the current exchange rate and calculate the amount to be redeemed:
            //  redeemTokens = redeemAmountIn / exchangeRate
            //  redeemAmount = redeemAmountIn
            redeemTokens = div_(redeemAmountIn, exchangeRate);
            redeemAmount = redeemAmountIn;
        }

        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }*/

        uint redeemTokens = redeemTokensIn;
        uint redeemAmount = mul_ScalarTruncate(exchangeRate, redeemTokensIn);

        // console.log("redeem fresh tokens ", redeemTokens);
        // console.log("redeem fresh amount ", redeemAmount);

        address payable redeemer = payable(msg.sender);
        /* Fail if redeem not allowed */
        uint allowed = matrixpricer.redeemAllowed(address(this), redeemer, redeemTokens);
        if (allowed != 0) {
            revert RedeemMatrixpricerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert RedeemFreshnessCheck();
        }

        // now check if we have sufficient USDT (within this contract and in Compound), if not we trigger forceRepay
        uint compoundBalance = getCmpBalanceInternal();
        uint currUSDTBalance = getCashExReserves();
        uint256 totalUndUnborrowed = currUSDTBalance + compoundBalance;
        uint netForceRepayAmt = 0;
//        console.log("totalUndUnborrowed,redeemAmount=%d,%d",totalUndUnborrowed,redeemAmount);
        if (totalUndUnborrowed < redeemAmount) {    // that means forcerepay + all of compound balance
            uint forceRepayAmtRequest = redeemAmount - totalUndUnborrowed;
//            console.log("redeemInternal - forceRepayAmtRequest", forceRepayAmtRequest);
            netForceRepayAmt = levErc20.forceRepay(forceRepayAmtRequest);
            // Fail gracefully if protocol still has insufficient cash
            // balance is changed, coz forceRepay pushes funds directly into depToken
            if (netForceRepayAmt == 0) {    // should either be successful or get nothing
                revert RedeemTransferOutNotPossible();
            }else{  // update ledger
                updateBorrowLedger(netForceRepayAmt, false, true);
            }
            withdrawUSDTfromCmp(compoundBalance);  // taking out all we have
        }else if (redeemAmount > currUSDTBalance) { // need to get some funds from Compound
            uint amtNeeded = redeemAmount - currUSDTBalance;
//            console.log("compoundBalance", compoundBalance);
//            console.log("amtNeeded: ", amtNeeded);
            if(compoundBalance > (amtNeeded + extraUSDT)){
//                console.log("amtNeeded + extraUSDT: ", amtNeeded + extraUSDT);
                withdrawUSDTfromCmp(amtNeeded + extraUSDT);
            }else{
//                console.log("compoundBalance: ", compoundBalance);
                withdrawUSDTfromCmp(compoundBalance);  // taking out all we have
            }
        }
        uint cashAvailToWithdraw = getCashExReserves();
//        console.log("after withdraw cashAvailToWithdraw", cashAvailToWithdraw);
        if(redeemAmount > cashAvailToWithdraw){
//            console.log("cashAvailToWithdraw=",cashAvailToWithdraw);
            redeemAmount = cashAvailToWithdraw; // due to gas fees/transacted fx diff
        }

        // act on the calculations now

        /*
         * We write the previously calculated values into storage.
         *  Note: Avoid token reentrancy attacks by writing reduced supply before external transfer.
         */
        totalSupply = totalSupply - redeemTokens;
        accountTokens[redeemer] = accountTokens[redeemer] - redeemTokens;

        /*
         * We invoke doTransferOut for the redeemer and the redeemAmount.
         *  On success, the DepToken has redeemAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        // deptoken and levtoken pay for the gases of all the transactions. msg.sender pay for the final transfer 
        doTransferOut(redeemer, redeemAmount);

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), redeemTokens);
        emit Redeem(redeemer, redeemAmount, redeemTokens, supplyRatePerBlock());
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param origBorrowAmount The amount of the underlying asset to borrow
      */
    function borrowInternal(uint origBorrowAmount) internal nonReentrant returns (uint) {
        accrueInterest();
        // borrowFresh emits borrow-specific logs on errors, so we don't need to
        // note that borrower is only the initiator, all borrowed amounts get transferred to the LEV contract
        /* Fail if borrow not allowed */
        address borrower = msg.sender;
        uint allowed = matrixpricer.borrowAllowed(address(this), borrower);
        if (allowed != 0) {
            revert BorrowMatrixpricerRejection(allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            revert BorrowFreshnessCheck();
        }

        uint currUSDTBalance = getCashExReserves();
        uint compoundBalance = getCmpBalanceInternal();
        uint borrowAmount = origBorrowAmount;
        uint256 totalUndUnborrowed = currUSDTBalance + compoundBalance;
        if (totalUndUnborrowed == 0) {
            revert BorrowCashNotAvailable();    // Fail gracefully if protocol has no underlying cash
        }else if(totalUndUnborrowed < borrowAmount){
            borrowAmount = totalUndUnborrowed;  // lend out as much as possible
        }
        if(borrowAmount > currUSDTBalance){ // need to get funds from compound
            uint amtNeeded = borrowAmount-currUSDTBalance;
            if(compoundBalance > (amtNeeded + extraUSDT)){
                withdrawUSDTfromCmp(amtNeeded + extraUSDT);
            }else{
                withdrawUSDTfromCmp(compoundBalance);  // taking out all we have
            }
        }

        /*
         * We calculate the new borrow and total borrow balances, failing on overflow:
         *  accountBorrowNew = accountBorrow + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        address payable levErc20Addr = payable(address(levErc20));
        uint accountBorrowsPrev = borrowBalanceStoredInternal(levErc20Addr);
        uint accountBorrowsNew = accountBorrowsPrev + borrowAmount;
        uint totalBorrowsNew = totalBorrows + borrowAmount;

        // ACT

        /*
         * We write the previously calculated values into storage.
         *  Note: Avoid token reentrancy attacks by writing increased borrow before external transfer.
        `*/
        accountBorrows[levErc20Addr].principal = accountBorrowsNew;
        accountBorrows[levErc20Addr].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

//        console.log("depToken borrow, currUSDTBalance=", currUSDTBalance);
//        console.log("depToken borrow, compoundBalance=", compoundBalance);
//        console.log("depToken borrow, origBorrowAmount=", origBorrowAmount);
//        console.log("depToken borrow, accountBorrowsPrev=", accountBorrowsPrev);
//        console.log("depToken borrow, accountBorrowsNew=", accountBorrowsNew);
//        console.log("depToken borrow, totalBorrowsNew=", totalBorrowsNew);
        /*
         * We invoke doTransferOut for the address(levErc20) and the borrowAmount.
         *  Note: The DepToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the DepToken borrowAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        // dont do transfer out, use curve to change USDT to USDC and push to levToken directly
        uint _usdcRec = changeUSDT2USDC(borrowAmount, 0, levErc20Addr);
        uint transFx = _usdcRec * expScale / borrowAmount;
        console.log("changed %d usdt into %d usdc",borrowAmount, _usdcRec);
        //doTransferOut(levErc20Addr, borrowAmount);

        /* We emit a Borrow event */
        emit Borrow(levErc20Addr, borrowAmount, accountBorrowsNew, totalBorrowsNew);
        return transFx;
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @param liquidate if levtoken is going thru liquidation
     */
    function repayBorrowInternal(uint repayAmount, bool liquidate) internal nonReentrant {
        if(!liquidate){  // levToken returns all it has
            accrueInterest();  
        }
        
        updateBorrowLedger(repayAmount, liquidate, false);

        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        uint currUSDTBalance = getCashExReserves();
        // deposit all USDT to compound V2
        if(checkCompound(currUSDTBalance)){
            supplyUSDT2Cmp(currUSDTBalance - thresholdUSDT);
        }
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     */
    function updateBorrowLedger(uint repayAmount, bool liquidate, bool forced) virtual internal {//nonReentrant {
        address levErc20Addr = address(levErc20);
        if(liquidate){
            uint accountBorrowsPrev = borrowBalanceStoredInternal(levErc20Addr);
            if(accountBorrowsPrev < repayAmount){
                uint extraRepaid = repayAmount - accountBorrowsPrev;    // pay this back into levToken
                uint _usdcRec = changeUSDT2USDC(extraRepaid, 0, payable(levErc20Addr));
                console.log("changed back %d usdt into %d usdc",extraRepaid,_usdcRec);
            }
            accountBorrows[levErc20Addr].principal = 0;
            //accountBorrows[levErc20Addr].interestIndex = borrowIndex; // accrueInterest() not called, so no need to update interestIndex
            totalBorrows = 0;
            emit RepayBorrow(levErc20Addr, repayAmount, 0, 0, true);
        }else{
            /* We fetch the amount leverager owes, with accumulated interest */
            uint accountBorrowsPrev = borrowBalanceStoredInternal(levErc20Addr);
            /*
            * We calculate the new borrower and total borrow balances, failing on underflow:
            *  accountBorrowsNew = accountBorrows - actualRepayAmount
            *  totalBorrowsNew = totalBorrows - actualRepayAmount
            */
            uint accountBorrowsNew;
            uint totalBorrowsNew;
            if(accountBorrowsPrev >= repayAmount){
                accountBorrowsNew = accountBorrowsPrev - repayAmount;
                totalBorrowsNew = totalBorrows - repayAmount;
            }else{
                accountBorrowsNew = 0;
                if(totalBorrows > accountBorrowsPrev){
                    totalBorrowsNew = totalBorrows - accountBorrowsPrev;
                }else{
//                    console.log("updateBorrowLedger:totalBorrows,accountBorrowsPrev=%d,%d",totalBorrows,accountBorrowsPrev);
                    totalBorrowsNew = 0;
                }
                uint extraRepaid = repayAmount - accountBorrowsPrev;    // pay this back into levToken
                uint _usdcRec = changeUSDT2USDC(extraRepaid, 0, payable(levErc20Addr));
                console.log("changed back %d usdt into %d usdc",extraRepaid,_usdcRec);
            }

            /* We write the previously calculated values into storage */
            accountBorrows[levErc20Addr].principal = accountBorrowsNew;
            accountBorrows[levErc20Addr].interestIndex = borrowIndex;
            totalBorrows = totalBorrowsNew;
            if(forced){ // function not called by levToken, so we need to tell lev to update its own stats
                levErc20.updateLedger();
            }

            /* We emit a RepayBorrow event */
            emit RepayBorrow(levErc20Addr, repayAmount, accountBorrowsNew, totalBorrowsNew, false);
        }
    }

    /**
     * @notice Calculates the ideal utilization rate of the market: `idealborrows / (cash + borrows - reserves)`
     * @return The utilization rate as a mantissa between [0, MANTISSA]
     */
    function idealUtilizationRate() public view returns (uint) {
        // Utilization rate is 0 when there are no borrows
        if (totalBorrows == 0) {
            return 0;
        }

        uint unborrowedCash = getCashExReserves() + getCmpBalanceInternal();
//        console.log("deptoken unborrowed cash=", unborrowedCash);
//        console.log("deptoken totalBorrows=", totalBorrows);
        uint idealBorrow;
        if (unborrowedCash > 0) {    // the balance left in depositor
            idealBorrow = totalBorrows;
        } else {
            uint extraborrowdemand = levErc20.getExtraBorrowDemand();
            uint extraborrowsupply = levErc20.getExtraBorrowSupply();
//            console.log("deptoken extraborrowdemand=", extraborrowdemand);
//            console.log("deptoken extraborrowsupply=", extraborrowsupply);
            if(totalBorrows + extraborrowdemand > extraborrowsupply){
                idealBorrow = totalBorrows + extraborrowdemand - extraborrowsupply;
            }else{
                idealBorrow = 0;
            }
        }
        return idealBorrow * expScale / (unborrowedCash + totalBorrows);
    }

    /*** Admin Functions ***/

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPendingAdmin(address payable newPendingAdmin) override external returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            revert SetPendingAdminOwnerCheck();
        }

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return NO_ERROR;
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _acceptAdmin() override external returns (uint) {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            revert AcceptAdminPendingAdminCheck();
        }

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = payable(address(0));

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return NO_ERROR;
    }

    /**
      * @notice Sets a new matrixpricer for the market
      * @dev Admin function to set a new matrixpricer
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setMatrixpricer(MatrixpricerInterface newMatrixpricer) override public returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            revert SetMatrixpricerOwnerCheck();
        }

        MatrixpricerInterface oldMatrixpricer = matrixpricer;
        // Ensure invoke matrixpricer.isMatrixpricer() returns true
        require(newMatrixpricer.isMatrixpricer(), "marker method returned false");

        // Set market's matrixpricer to newMatrixpricer
        matrixpricer = newMatrixpricer;

        // Emit NewMatrixpricer(oldMatrixpricer, newMatrixpricer)
        emit NewMatrixpricer(oldMatrixpricer, newMatrixpricer);

        return NO_ERROR;
    }

    /**
      * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
      * @dev Admin function to accrue interest and set a new reserve factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReserveFactor(uint newReserveFactorMantissa) override external nonReentrant returns (uint) {
        accrueInterest();
        // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    /**
      * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
      * @dev Admin function to set a new reserve factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReserveFactorFresh(uint newReserveFactorMantissa) internal returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            revert SetReserveFactorAdminCheck();
        }

        // Verify market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            revert SetReserveFactorFreshCheck();
        }

        // Check newReserveFactor ≤ maxReserveFactor
        if (newReserveFactorMantissa > reserveFactorMaxMantissa) {
            revert SetReserveFactorBoundsCheck();
        }

        uint oldReserveFactorMantissa = reserveFactorMantissa;
        reserveFactorMantissa = newReserveFactorMantissa;

        emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

        return NO_ERROR;
    }

    /**
     * @notice Accrues interest and reduces reserves by transferring from msg.sender
     * @param addAmount Amount of addition to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReservesInternal(uint addAmount) internal nonReentrant returns (uint) {
        accrueInterest();

        // _addReservesFresh emits reserve-addition-specific logs on errors, so we don't need to.
        _addReservesFresh(addAmount);
        return NO_ERROR;
    }

    /**
     * @notice Add reserves by transferring from caller
     * @dev Requires fresh interest accrual
     * @param addAmount Amount of addition to reserves
     * @return (uint, uint) An error code (0=success, otherwise a failure (see ErrorReporter.sol for details)) and the actual amount added, net token fees
     */
    function _addReservesFresh(uint addAmount) internal returns (uint, uint) {
        // totalReserves + actualAddAmount
        uint totalReservesNew;
        uint actualAddAmount;

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            revert AddReservesFactorFreshCheck(actualAddAmount);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the caller and the addAmount
         *  Note: The DepToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the DepToken holds an additional addAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *  it returns the amount actually transferred, in case of a fee.
         */

        actualAddAmount = doTransferIn(msg.sender, addAmount);

        totalReservesNew = totalReserves + actualAddAmount;

        // Store reserves[n+1] = reserves[n] + actualAddAmount
        totalReserves = totalReservesNew;

        /* Emit NewReserves(admin, actualAddAmount, reserves[n+1]) */
        emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

        /* Return (NO_ERROR, actualAddAmount) */
        return (NO_ERROR, actualAddAmount);
    }


    /**
     * @notice Accrues interest and reduces reserves by transferring to admin
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves(uint reduceAmount) override external nonReentrant returns (uint) {
        accrueInterest();
        // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
        return _reduceReservesFresh(reduceAmount);
    }

    /**
     * @notice Reduces reserves by transferring to admin
     * @dev Requires fresh interest accrual
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReservesFresh(uint reduceAmount) internal returns (uint) {
        // totalReserves - reduceAmount
        uint totalReservesNew;

        // Check caller is admin
        if (msg.sender != admin) {
            revert ReduceReservesAdminCheck();
        }

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            revert ReduceReservesFreshCheck();
        }

        // Fail gracefully if protocol has insufficient underlying cash
        if (getCashPrior() < reduceAmount) {
            revert ReduceReservesCashNotAvailable();
        }

        // Check reduceAmount ≤ reserves[n] (totalReserves)
        if (reduceAmount > totalReserves) {
            revert ReduceReservesCashValidation();
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        totalReservesNew = totalReserves - reduceAmount;

        // Store reserves[n+1] = reserves[n] - reduceAmount
        totalReserves = totalReservesNew;

        // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        doTransferOut(admin, reduceAmount);

        emit ReservesReduced(admin, reduceAmount, totalReservesNew);

        return NO_ERROR;
    }

    /**
     * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModel(InterestRateModel newInterestRateModel) override public returns (uint) {
        accrueInterest();
        // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    /**
     * @notice updates the interest rate model (*requires fresh interest accrual)
     * @dev Admin function to update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal returns (uint) {

        // Used to store old model for use in the event that is emitted on success
        InterestRateModel oldInterestRateModel;

        // Check caller is admin
        if (msg.sender != admin) {
            revert SetInterestRateModelOwnerCheck();
        }

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            revert SetInterestRateModelFreshCheck();
        }

        // Track the market's current interest rate model
        oldInterestRateModel = interestRateModel;

        // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
        require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

        // Set the interest rate model to newInterestRateModel
        interestRateModel = newInterestRateModel;

        // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
//        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

        return NO_ERROR;
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying owned by this contract
     */
    function getCashPrior() virtual internal view returns (uint);

    /**
     * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
     *  This may revert due to insufficient balance or insufficient allowance.
     */
    function doTransferIn(address from, uint amount) virtual internal returns (uint);

    /**
     * @dev Performs a transfer out, ideally returning an explanatory error code upon failure rather than reverting.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     */
    function doTransferOut(address payable to, uint amount) virtual internal;


    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }
}