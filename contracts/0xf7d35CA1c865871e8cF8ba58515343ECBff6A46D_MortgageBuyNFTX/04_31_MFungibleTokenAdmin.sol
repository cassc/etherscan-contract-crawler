pragma solidity ^0.5.16;

import "./MTokenAdmin.sol";
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
contract MFungibleTokenAdmin is MTokenAdmin, MFungibleTokenAdminInterface {

    /**
     * @notice Constructs a new MFungibleTokenAdmin
     */
    constructor() public MTokenAdmin() {
    }

    /**
     * Marker function identifying this contract as "FUNGIBLE_MTOKEN" type
     */
    function getTokenType() public pure returns (MTokenIdentifier.MTokenType) {
        return MTokenIdentifier.MTokenType.FUNGIBLE_MTOKEN;
    }

    /**
     * @notice Initialize a new fungible MToken money market
     * @param underlyingContract_ The contract address of the underlying asset for this MToken
     * @param mtroller_ The address of the Mtroller
     * @param interestRateModel_ The address of the interest rate model
     * @param reserveFactorMantissa_ The fraction of interest to set aside for reserves, scaled by 1e18
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param protocolSeizeShareMantissa_ The fraction of seized collateral added to reserves, scaled by 1e18
     * @param name_ EIP-20 name of this MToken
     * @param symbol_ EIP-20 symbol of this MToken
     * @param decimals_ EIP-20 decimal precision of this MToken
     */
    function initialize(address underlyingContract_,
                MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                uint reserveFactorMantissa_,
                uint initialExchangeRateMantissa_,
                uint protocolSeizeShareMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_) internal {
        MTokenAdmin.initialize(underlyingContract_, mtroller_, interestRateModel_, reserveFactorMantissa_,
            initialExchangeRateMantissa_, protocolSeizeShareMantissa_, name_, symbol_, decimals_);
        thisFungibleMToken = mtroller_.assembleToken(getTokenType(), uint72(dummyTokenID), address(this));
    }
}

contract MFungibleTokenInterfaceFull is MFungibleTokenAdmin, MFungibleTokenInterface {}