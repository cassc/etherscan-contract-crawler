pragma solidity ^0.5.16;

import "./MTokenUser.sol";
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
contract MFungibleTokenUser is MTokenUser, MFungibleTokenUserInterface {

    /**
     * Marker function identifying this contract as "FUNGIBLE_MTOKEN" type
     */
    function getTokenType() public pure returns (MTokenIdentifier.MTokenType) {
        return MTokenIdentifier.MTokenType.FUNGIBLE_MTOKEN;
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     * @return Error code (0 = success)
     */
    function transferTokens(address spender, address src, address dst, uint tokens) internal nonReentrant returns (uint) {

        /* Get the allowance, infinite for the account owner */
        uint startingAllowance;
        if (spender == src) {
            startingAllowance = uint(-1);
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /* Do the calculations, checking for {under,over}flow */
        MathError mathErr;
        uint allowanceNew;

        (mathErr, allowanceNew) = subUInt(startingAllowance, tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ALLOWED);
        }

        uint err = transferTokens(src, dst, thisFungibleMToken, tokens);
        if (err != uint(Error.NO_ERROR)) {
            return err;
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != uint(-1)) {
            transferAllowances[src][spender] = allowanceNew;
        }

        /* We emit a Transfer event */
        emit Transfer(src, dst, tokens);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) external returns (bool) {
        return transferTokens(msg.sender, msg.sender, dst, amount) == uint(Error.NO_ERROR);
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        return transferTokens(msg.sender, src, dst, amount) == uint(Error.NO_ERROR);
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint amount) external returns (bool) {
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
    function allowance(address owner, address spender) external view returns (uint) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint) {
        return balanceOf(owner, thisFungibleMToken);
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint) {
        return balanceOfUnderlying(owner, thisFungibleMToken);
    }

    /**
     * @notice Sender supplies assets into the market and beneficiary receives mTokens in exchange
     * @dev Reverts on any error
     * @param beneficiary The address to receive the minted mTokens
     * @param mintAmount The amount of the underlying asset to supply
     * @return (the new mToken, 
     *          the amount of tokens minted for the new mToken, 
     *          the actual amount of underlying paid)
     */
    function mintToFungibleInternal(address beneficiary, uint mintAmount) internal nonReentrant returns (uint240, uint, uint) {
        (uint240 mToken, uint tokens, uint underlyingAmount) = mintToInternal(beneficiary, dummyTokenID, mintAmount);
        require(mToken == thisFungibleMToken, "Attempt to mint invalid mToken");
        require(tokens > 0 && underlyingAmount > 0, "No new mTokens minted");
        return (mToken, tokens, underlyingAmount);
    }
}