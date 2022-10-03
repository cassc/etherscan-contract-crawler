pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./MtrollerInterface.sol";
import "./MtrollerStorage.sol";
import "./MTokenInterfaces.sol";
import "./MTokenCommon.sol";
import "./Mmo.sol";
import "./ErrorReporter.sol";
import "./compound/ExponentialNoError.sol";

/**
 * @title Based on Compound's Mtroller Contract, with some modifications
 * @dev This contract must not declare any variables. All required storage must be in MtrollerV1Storage
 * @author Compound, mmo.finance
 */
contract MtrollerCommon is MtrollerV1Storage, MtrollerCommonInterface {

    /**
     * @notice Constructs a new MtrollerCommon
     */
    constructor() public {
    }

    /**
     * @notice Tells the address of the current admin (set in MDelegator.sol)
     * @return admin The address of the current admin
     */
    function getAdmin() public view returns (address payable admin) {
        bytes32 position = mDelegatorAdminPosition;
        assembly {
            admin := sload(position)
        }
    }

    /*** mToken identifier handling utilities ***/

    /**
     * @notice Identifiers for mTokens are special uint240 numbers, where the highest order 8 bits is 
     * an MTokenType enum, the lowest 160 bits are the address of the mToken's contract. The
     * remaining 72 bits in between are used as sequential ID number mTokenSeqNr (always > 0) for
     * non-fungible mTokens. For fungible tokens always mTokenSeqNr == 1. The mToken with
     * mTokenSeqNr == 0 is the special "anchor token" for a given mToken contract.
     */

    /* Returns a special "contract" address reserved for the case when the underlying asset is Ether (ETH) */
    function underlyingContractETH() public pure returns (address) {
        return address(uint160(-1));
    }

    /** 
     * @notice Construct the anchorToken from the given mToken contract address
     * @param mTokenContract The contract address of the mToken whose anchor token to return
     * @return uint240 The anchor token
     */        
    function getAnchorToken(address mTokenContract) public pure returns (uint240) {
        return assembleToken(MTokenIdentifier(mTokenContract).getTokenType(), 0, mTokenContract);
    }

    /** 
     * @notice Construct the anchorToken from the given mToken
     * @param mToken The mToken whose anchor token to return
     * @return uint240 The anchor token for this mToken
     */        
    function getAnchorToken(uint240 mToken) internal pure returns (uint240) {
        return (mToken & 0xff000000000000000000ffffffffffffffffffffffffffffffffffffffff);
    }

    /** 
     * @notice Creates an mToken identifier based on mTokenType, mTokenSeqNr and mTokenAddress
     * @dev Does not check for any errors in its arguments
     * @param mTokenType The MTokenType of the mToken
     * @param mTokenSeqNr The "serial number" of the mToken
     * @param mTokenAddress The address of the mToken's contract
     * @return uint240 The mToken identifier
     */        
    function assembleToken(MTokenType mTokenType, uint72 mTokenSeqNr, address mTokenAddress) public pure returns (uint240 mToken) {
        bytes10 mTokenData = bytes10(uint80(mTokenSeqNr) + (uint80(mTokenType) << 72));
        return (uint240(bytes30(mTokenData)) + uint240(uint160(mTokenAddress)));
    }

    /** 
     * @notice Given an mToken identifier, return the mToken's mTokenType, mTokenSeqNr and mTokenAddress
     * @dev Reverts on error (invalid mToken)
     * @param mToken The mToken to retreive the information from
     * @return (mTokenType The MTokenType of the mToken,
     *          mTokenSeqNr The "serial number" of the mToken,
     *          mTokenAddress The address of the mToken's contract)
     */        
    function parseToken(uint240 mToken) public pure returns (MTokenType mTokenType, uint72 mTokenSeqNr, address mTokenAddress) {
        mTokenAddress = address(uint160(mToken));
        bytes10 mTokenData = bytes10(bytes30(mToken));
        mTokenSeqNr = uint72(uint80(mTokenData));
        mTokenType = MTokenType(uint8(mTokenData[0]));
        require(mTokenType == MTokenIdentifier(mTokenAddress).getTokenType(), "Invalid mToken type");
        if (mTokenType == MTokenType.FUNGIBLE_MTOKEN) {
            require(mTokenSeqNr <= 1, "Invalid seqNr for fungible token");
        }
        else if (mTokenType != MTokenType.ERC721_MTOKEN) {
            revert("Unknown mToken type");
        }
        return (mTokenType, mTokenSeqNr, mTokenAddress);
    }

    /*** Assets You Are In ***/

    /**
      * @notice Add the mToken market to the markets mapping and set it as listed
      * @dev Internal(!) function to set isListed and add support for the market
      * @param mToken The mToken market to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarketInternal(uint240 mToken) internal returns (uint) {
        if (isListed(mToken)) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        // Checks mToken format (full check) to make sure it is a valid mToken (reverts on error)
        ( , uint72 mTokenSeqNr, address mTokenAddress) = parseToken(mToken);
        require(mTokenSeqNr <= MTokenCommon(mTokenAddress).totalCreatedMarkets(), "invalid mToken SeqNr");
        uint240 tokenAnchor = getAnchorToken(mTokenAddress);
        require(tokenAnchor == getAnchorToken(mToken), "invalid anchor token");

        /**
         * Unless sender is admin, only allow listing if sender is mToken's own contract and mToken is
         * not the anchor token and the mToken's anchor token is already listed
         */
        if (msg.sender != getAdmin()) {
            if (msg.sender != mTokenAddress || mToken == tokenAnchor || !isListed(tokenAnchor)) {
                return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
            }
        }

        // Set the mToken as listed
        markets[mToken] = Market({_isListed: true, _collateralFactorMantissa: 0});

        // If the mToken is an anchor token, add it to the markets mapping (reverts on error)
        if (mToken == tokenAnchor) {
            _addMarketInternal(mToken);
        }

        emit MarketListed(mToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(uint240 mToken) internal {
        require(allMarketsIndex[mToken] == 0, "market already added");
        allMarketsSize++;
        allMarkets[allMarketsSize] = mToken;
        allMarketsIndex[mToken] = allMarketsSize;
    }

    /**
      * @notice Checks if an mToken is listed (i.e., it is supported by the platform)
      * @dev For this to return true both the actual mToken and its anchorToken have to be listed.
      * The anchorToken needs to be listed explicitly by admin using _supportMarket(). Any other
      * mToken is listed automatically when mintAllowed() is called for that mToken, i.e. when it is
      * minted for the first time, but only if it's anchorToken is already listed.
      * @param mToken The mToken to check
      * @return true if both the mToken and its anchorToken are listed, false otherwise
      */
    function isListed(uint240 mToken) internal view returns (bool) {
        if (!(markets[getAnchorToken(mToken)]._isListed)) {
            return false;
        }
        return (markets[mToken]._isListed);
    }

    /**
      * @notice Returns the current collateral factor of a mToken
      * @dev If the mTokens own (specific) collateral factor is zero or the anchor token's collateral
      * factor is zero, then the anchor token's collateral factor is returned, otherwise the specific factor.
      * Reverts if mToken is not listed or resulting collateral factor exceeds limit
      * @param mToken The mToken to return the collateral factor for
      * @return uint The mToken's current collateral factor, scaled by 1e18
      */
    function collateralFactorMantissa(uint240 mToken) public view returns (uint) {
        require(isListed(mToken), "mToken not listed");
        uint240 tokenAnchor = getAnchorToken(mToken);
        uint result = markets[tokenAnchor]._collateralFactorMantissa;
        if (result == 0) {
            return 0;
        }
        if (mToken != tokenAnchor) {
            uint localFactor = markets[mToken]._collateralFactorMantissa;
            if (localFactor != 0) {
                result = localFactor;
            }
        }
        require(result <= collateralFactorMaxMantissa, "collateral factor too high");
        return result;
    }
}