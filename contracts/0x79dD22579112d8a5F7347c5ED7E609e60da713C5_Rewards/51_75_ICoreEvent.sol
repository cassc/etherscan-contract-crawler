// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface ICoreEvent {

    struct SupportedTokenData {
        address token;        
        uint256 maxUserLimit;        
        bool systemFinalized; // Whether or not the system is done setting rates, doing transfers, for this token
    }

    struct DurationInfo {
        uint256 startingBlock;        
        uint256 blockDuration;  // Block duration of the deposit/withdraw stage
    }

    struct RateData {
        address token;
        uint256 tokeNumerator;
        uint256 tokeDenominator;
        uint256 overNumerator;
        uint256 overDenominator;
        address pool; 
    }

    struct TokenData {
        address token;
        uint256 amount;
    }

    struct AccountData {
        address token; // Address of the allowed token deposited        
        uint256 depositedBalance;
        bool finalized; // Has the user either taken their refund or sent to farming. Will not be set on swapped but undersubscribed tokens.
    }

    struct FinalizedAccountData {
        address token;
        uint256 transferredToFarm;
        uint256 refunded;
    }

     struct TokenFarming {
        address token; // address of the allowed token deposited        
        bool sendToFarming; // Refund is default
    }

    struct WhitelistSettings {
        bool enabled;
        bytes32 root;
    }

    event SupportedTokensAdded(SupportedTokenData[] tokenData);
    event TreasurySet(address treasury);    
    event DurationSet(DurationInfo duration);
    event DurationIncreased(DurationInfo duration);
    event Deposited(address depositor, TokenData[] tokenInfo);
    event Withdrawn(address withdrawer, TokenData[] tokenInfo);    
    event RatesPublished(RateData[] ratesData);    
    event AssetsFinalized(address user, FinalizedAccountData[] data);
    event TreasuryTransfer(TokenData[] tokens);
    event WhitelistConfigured(WhitelistSettings settings); 
    event SetNoSwap(address[] tokens);

    //==========================================
    // Initial setup operations
    //==========================================    

    /// @notice Enable or disable the whitelist
    /// @param settings The root to use and whether to check the whitelist at all
    function configureWhitelist(WhitelistSettings memory settings) external;

    /// @notice defines the length in blocks the round will run for
    /// @notice round is started via this call and it is only callable one time
    /// @param blockDuration Duration in blocks the deposit/withdraw portion will run for
    function setDuration(uint256 blockDuration) external;

    /// @notice adds tokens to support
    /// @param tokensToSupport an array of supported token structs
    function addSupportedTokens(SupportedTokenData[] memory tokensToSupport) external;

    //==========================================
    // Stage 1 timeframe operations
    //==========================================

    /// @notice deposits tokens into the round contract
    /// @param tokenData an array of token structs
    /// @param proof Merkle proof for the user. Only required if whitelistSettings.enabled
    function deposit(TokenData[] calldata tokenData, bytes32[] calldata proof) external;

    /// @notice withdraws tokens from the round contract
    /// @param tokenData an array of token structs
    function withdraw(TokenData[] calldata tokenData) external;

    /// @notice extends the deposit/withdraw stage
    /// @notice Only extendable if no tokens have been finalized and no rates set
    /// @param blockDuration Duration in blocks the deposit/withdraw portion will run for. Must be greater than original
    function increaseDuration(uint256 blockDuration) external;

    //==========================================
    // Stage 1 -> 2 transition operations
    //==========================================

    /// @notice once the expected duration has passed, publish the Toke and over subscription rates
    /// @notice tokens which do not have a published rate will have their users forced to withdraw all funds    
    /// @dev pass a tokeNumerator of 0 to delete a set rate
    /// @dev Cannot be called for a token once transferToTreasury/setNoSwap has been called for that token
    function setRates(RateData[] calldata rates) external;

    /// @notice Allows the owner to transfer the effective balance of a token based on the set rate to the treasury
    /// @dev only callable by owner and if rates have been set
    /// @dev is only callable one time for a token
    function transferToTreasury(address[] calldata tokens) external;

    /// @notice Marks a token as finalized but not swapping
    /// @dev complement to transferToTreasury which is for tokens that will be swapped, this one for ones that won't
    function setNoSwap(address[] calldata tokens) external;

    //==========================================    
    // Stage 2 operations
    //==========================================

    /// @notice Once rates have been published, and the token finalized via transferToTreasury/setNoSwap, either refunds or sends to private farming
    /// @param tokens an array of tokens and whether to send them to private farming. False on farming will send back to user.
    function finalize(TokenFarming[] calldata tokens) external;

    //==========================================
    // View operations
    //==========================================

    /// @notice Breaks down the balance according to the published rates
    /// @dev only callable after rates have been set
    function getRateAdjustedAmounts(uint256 balance, address token) external view returns (uint256 effectiveAmt, uint256 ineffectiveAmt, uint256 actualReceived);

    /// @notice return the published rates for the tokens    
    /// @return rates an array of rates for the provided tokens
    function getRates() external view returns (RateData[] memory rates);

    /// @notice returns a list of AccountData for a provided account
    /// @param account the address of the account
    /// @return data an array of AccountData denoting what the status is for each of the tokens deposited (if any)
    function getAccountData(address account) external view returns (AccountData[] calldata data);

    /// @notice get all tokens currently supported by the contract
    /// @return supportedTokensArray an array of supported token structs
    function getSupportedTokens() external view returns (SupportedTokenData[] memory supportedTokensArray);

}