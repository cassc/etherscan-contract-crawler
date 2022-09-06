// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./CErc721Virtual.sol";

interface IFlashClaimer {
    function onFlashClaim(address user, uint256 tokenId) external;
}

interface ICERC721Moonbird {
    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function nestingPeriod(uint256 tokenId) external view returns (bool nesting, uint256 current, uint256 total);
    function safeTransferWhileNesting(address from, address to, uint256 tokenId) external;
}

contract CErc721MoonbirdStorage {
    // Reserve tokenId per Supply
    mapping(uint256 => address) internal reserves;
}

/**
 * @title Drops's CErc721 Contract (Modified from "Compound's CErc20 Contract")
 * @notice CTokens which wrap an EIP-721 underlying
 * @author Drops Loan
 */
contract CErc721Moonbird is CErc721Virtual, CErc721MigrationInterface, CErc721MoonbirdStorage {

    /**
     * @notice Initialize the new money market
     * @param underlying_ The address of the underlying asset
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     */
    function initialize(address underlying_,
                        ComptrollerInterface comptroller_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_) public override {
        // CToken initialize does the bulk of the work
        super.initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

        // Set underlying and sanity check it
        underlying = underlying_;
        EIP20Interface(underlying).totalSupply();
    }

    function mintInternalTo(address to, uint tokenId) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return (fail(Error(error), FailureInfo.MINT_ACCRUE_INTEREST_FAILED), 0);
        }
        // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
        return mintFresh(to, tokenId);
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes memory) external returns(bytes4) {
        if (msg.sender == underlying) {
            reserves[tokenId] = from;
            
            (uint err,) = mintInternalTo(from, tokenId);
            require(err == uint(Error.NO_ERROR), "mintInternal failed");

            delete reserves[tokenId];
        }
        return this.onERC721Received.selector;
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint tokenId) internal override returns (uint) {
        ICERC721Moonbird token = ICERC721Moonbird(underlying);
        uint balanceBefore = token.balanceOf(address(this));
        
        if (reserves[tokenId] == address(0)) {
            token.transferFrom(from, address(this), tokenId);
        } else {
            require(reserves[tokenId] == from, "invalid supply");
            balanceBefore -= 1;
        }

        userTokens[from].push(tokenId);

        // bool success;
        // assembly {
        //     switch returndatasize()
        //         case 0 {                       // This is a non-standard ERC-20
        //             success := not(0)          // set success to true
        //         }
        //         case 32 {                      // This is a compliant ERC-20
        //             returndatacopy(0, 0, 32)
        //             success := mload(0)        // Set `success = returndata` of external call
        //         }
        //         default {                      // This is an excessively non-compliant ERC-20, revert.
        //             revert(0, 0)
        //         }
        // }
        // require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address payable to, uint tokenIndex) internal override {
        ICERC721Moonbird token = ICERC721Moonbird(underlying);
        uint tokenId = userTokens[to][tokenIndex];
        uint newBalance = userTokens[to].length - 1;
        userTokens[to][tokenIndex] = userTokens[to][newBalance];
        userTokens[to].pop();

        (bool nesting, , ) = token.nestingPeriod(tokenId);
        if (nesting) {
            token.safeTransferWhileNesting(address(this), to, tokenId);
        } else {
            token.transferFrom(address(this), to, tokenId);
        }

        // bool success;
        // assembly {
        //     switch returndatasize()
        //         case 0 {                      // This is a non-standard ERC-20
        //             success := not(0)          // set success to true
        //         }
        //         case 32 {                     // This is a complaint ERC-20
        //             returndatacopy(0, 0, 32)
        //             success := mload(0)        // Set `success = returndata` of external call
        //         }
        //         default {                     // This is an excessively non-compliant ERC-20, revert.
        //             revert(0, 0)
        //         }
        // }
        // require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() internal view virtual override returns (uint) {
        // [2022.7.15] - cash to `totalySupply`
        // ISSUE - NFT transfer can cause exchangeRate changed
        return totalSupply;

        // [COMMENT] - original code
        // ICERC721 token = ICERC721(underlying);
        // return token.balanceOf(address(this));
    }

    function flashClaim(uint256 tokenIndex, address claimer) external {
        address user = msg.sender;
        require(tx.origin == user, "Invalid owner");
        uint256 tokenId = userTokens[user][tokenIndex];

        ICERC721(underlying).transferFrom(address(this), claimer, tokenId);
        IFlashClaimer(claimer).onFlashClaim(user, tokenId);
        ICERC721(underlying).transferFrom(claimer, address(this), tokenId);
    }

    function migrate() external virtual override returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return fail(Error(error), FailureInfo.MINT_ACCRUE_INTEREST_FAILED);
        }

        address minter = msg.sender;
        uint256 mintAmount = CErc721Virtual(migration).balanceOf(minter);

        for (uint256 i = 0; i < mintAmount; i++) {
            userTokens[minter].push(CErc721Virtual(migration).userTokens(minter, i));
        }

        /* Fail if mint not allowed */
        uint allowed = comptroller.mintAllowed(address(this), minter, mintAmount);
        if (allowed != 0) {
            return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.MINT_COMPTROLLER_REJECTION, allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.MINT_FRESHNESS_CHECK);
        }

        MintLocalVars memory vars;

        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.MINT_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr));
        }

        // vars.actualMintAmount = doTransferIn(minter, tokenId);
        vars.actualMintAmount = mintAmount;

        (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(vars.actualMintAmount, Exp({mantissa: vars.exchangeRateMantissa}));
        require(vars.mathErr == MathError.NO_ERROR, "MINT_EXCHANGE_CALCULATION_FAILED");

        (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply, vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");

        (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[minter], vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");

        /* We write previously calculated values into storage */
        totalSupply = vars.totalSupplyNew;
        accountTokens[minter] = vars.accountTokensNew;

        /* We emit a Mint event, and a Transfer event */
        emit Mint(minter, vars.actualMintAmount, vars.mintTokens);
        emit Transfer(address(this), minter, vars.mintTokens);

        /* We call the defense hook */
        comptroller.mintVerify(address(this), minter, vars.actualMintAmount, vars.mintTokens);

        uint256[] memory redeemTokenIds = new uint256[](mintAmount);
        for (uint256 i = mintAmount; i > 0; i--) {
            require(CErc721Virtual(migration).transferFrom(minter, address(this), i - 1), "Transfer dToken failed");
            redeemTokenIds[mintAmount - i] = i - 1;
        }
        CErc721Virtual(migration).redeems(redeemTokenIds);

        return uint(Error.NO_ERROR);
    }

    function _setMigration(address migration_) external virtual override {
        require(msg.sender == admin, "Invalid admin");
        migration = migration_;
    }
}