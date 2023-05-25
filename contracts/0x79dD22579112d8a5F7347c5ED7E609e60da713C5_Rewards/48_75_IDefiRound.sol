// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface IDefiRound {
    enum STAGES {STAGE_1, STAGE_2, STAGE_3}

    struct AccountData {
        address token; // address of the allowed token deposited
        uint256 initialDeposit; // initial amount deposited of the token
        uint256 currentBalance; // current balance of the token that can be used to claim TOKE
    }

    struct AccountDataDetails {
        address token; // address of the allowed token deposited
        uint256 initialDeposit; // initial amount deposited of the token
        uint256 currentBalance; // current balance of the token that can be used to claim TOKE
        uint256 effectiveAmt; //Amount deposited that will be used towards TOKE
        uint256 ineffectiveAmt; //Amount deposited that will be either refunded or go to farming
        uint256 actualTokeReceived; //Amount of TOKE that will be received
    }

    struct TokenData {
        address token;
        uint256 amount;
    }

    struct SupportedTokenData {
        address token;
        address oracle;
        address genesis;
        uint256 maxLimit;
    }

    struct RateData {
        address token;
        uint256 numerator;
        uint256 denominator;
    }

    struct OversubscriptionRate {
        uint256 overNumerator;
        uint256 overDenominator;
    }

    event Deposited(address depositor, TokenData tokenInfo);
    event Withdrawn(address withdrawer, TokenData tokenInfo, bool asETH);
    event SupportedTokensAdded(SupportedTokenData[] tokenData);
    event RatesPublished(RateData[] ratesData);
    event GenesisTransfer(address user, uint256 amountTransferred);
    event AssetsFinalized(address claimer, address token, uint256 assetsMoved);
    event WhitelistConfigured(WhitelistSettings settings); 
    event TreasuryTransfer(TokenData[] tokens);

    struct TokenValues {
        uint256 effectiveTokenValue;
        uint256 ineffectiveTokenValue;
    }

    struct WhitelistSettings {
        bool enabled;
        bytes32 root;
    }

    /// @notice Enable or disable the whitelist
    /// @param settings The root to use and whether to check the whitelist at all
    function configureWhitelist(WhitelistSettings calldata settings) external;

    /// @notice returns the current stage the contract is in
    /// @return stage the current stage the round contract is in
    function currentStage() external returns (STAGES stage);

    /// @notice deposits tokens into the round contract
    /// @param tokenData an array of token structs
    function deposit(TokenData calldata tokenData, bytes32[] memory proof) external payable;

    /// @notice total value held in the entire contract amongst all the assets
    /// @return value the value of all assets held
    function totalValue() external view returns (uint256 value);

    /// @notice Current Max Total Value
    function getMaxTotalValue() external view returns (uint256 value);

    /// @notice returns the address of the treasury, when users claim this is where funds that are <= maxClaimableValue go
    /// @return treasuryAddress address of the treasury
    function treasury() external returns (address treasuryAddress);

    /// @notice the total supply held for a given token
    /// @param token the token to get the supply for
    /// @return amount the total supply for a given token
    function totalSupply(address token) external returns (uint256 amount);

    /// @notice withdraws tokens from the round contract. only callable when round 2 starts
    /// @param tokenData an array of token structs
    /// @param asEth flag to determine if provided WETH, that it should be withdrawn as ETH
    function withdraw(TokenData calldata tokenData, bool asEth) external;

    // /// @notice adds tokens to support
    // /// @param tokensToSupport an array of supported token structs
    function addSupportedTokens(SupportedTokenData[] calldata tokensToSupport) external;

    // /// @notice returns which tokens can be deposited
    // /// @return tokens tokens that are supported for deposit
    function getSupportedTokens() external view returns (address[] calldata tokens);

    /// @notice the oracle that will be used to denote how much the amounts deposited are worth in USD
    /// @param tokens an array of tokens
    /// @return oracleAddresses the an array of oracles corresponding to supported tokens
    function getTokenOracles(address[] calldata tokens)
        external
        view
        returns (address[] calldata oracleAddresses);

    /// @notice publishes rates for the tokens. Rates are always relative to 1 TOKE. Can only be called once within Stage 1
    // prices can be published at any time
    /// @param ratesData an array of rate info structs
    function publishRates(
        RateData[] calldata ratesData,
        OversubscriptionRate memory overSubRate,
        uint256 lastLookDuration
    ) external;

    /// @notice return the published rates for the tokens
    /// @param tokens an array of tokens to get rates for
    /// @return rates an array of rates for the provided tokens
    function getRates(address[] calldata tokens) external view returns (RateData[] calldata rates);

    /// @notice determines the account value in USD amongst all the assets the user is invovled in
    /// @param account the account to look up
    /// @return value the value of the account in USD
    function accountBalance(address account) external view returns (uint256 value);

    /// @notice Moves excess assets to private farming or refunds them
    /// @dev uses the publishedRates, selected tokens, and amounts to determine what amount of TOKE is claimed
    /// @param depositToGenesis applies only if oversubscribedMultiplier < 1;
    /// when true oversubscribed amount will deposit to genesis, else oversubscribed amount is sent back to user
    function finalizeAssets(bool depositToGenesis) external;

    //// @notice returns what gensis pool a supported token is mapped to
    /// @param tokens array of addresses of supported tokens
    /// @return genesisAddresses array of genesis pools corresponding to supported tokens
    function getGenesisPools(address[] calldata tokens)
        external
        view
        returns (address[] memory genesisAddresses);

    /// @notice returns a list of AccountData for a provided account
    /// @param account the address of the account
    /// @return data an array of AccountData denoting what the status is for each of the tokens deposited (if any)
    function getAccountData(address account)
        external
        view
        returns (AccountDataDetails[] calldata data);

    /// @notice Allows the owner to transfer all swapped assets to the treasury
    /// @dev only callable by owner and if last look period is complete
    function transferToTreasury() external;

    /// @notice Given a balance, calculates how the the amount will be allocated between TOKE and Farming
    /// @dev Only allowed at stage 3
    /// @param balance balance to divy up
    /// @param token token to pull the rates for
    function getRateAdjustedAmounts(uint256 balance, address token)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}