// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ICrowdsale {
    enum Phase {
        Whitelisted,
        Public,
        Inactive
    }

    struct Tranche {
        uint256 start; // in blocks
        uint256 supply;
        uint256 kolPrice;
        uint256 publicPrice;
        uint256 freeMintsSold;
        uint256 kolSold;
        uint256 publicSold;
    }

    struct TrancheStatus {
        Tranche details;
        Phase phase;
        uint256 trancheNumber;
    }

    struct Whitelist {
        uint256 cap;
        uint256 contribution;
    }

    /**
     * @notice Emitted when tokens are purchased
     * @param beneficiary Address that bought NFT
     * @param value Total value paid for NFTs
     * @param amount Amuont of NFTs transfered
     */
    event TokensPurchased(address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @notice Emitted when new tranche is added
     * @param index Index of new tranche
     * @param supply Token supply within new tranche
     * @param price Price per token
     */
    event TrancheAdded(uint256 indexed index, uint256 indexed supply, uint256 indexed price);

    /**
     * @notice Changes fundraising wallet to new address
     * @param newWallet New fundraising wallet address
     */
    function setWallet(address newWallet) external;

    /**
     * @notice Changes currency to new address
     * @param newCurrency New currency address
     */
    function setCurrency(address newCurrency) external;

    /**
     * @notice Changes token address
     * @param newToken New token address
     */
    function setToken(address newToken) external;

    /**
     * @notice Returns total raised funds throughout all tranches
     * @return Total raised funds
     */
    function fundsRaised() external view returns (uint256);

    /**
     * @notice Performs NFT purchase transaction. Transfers currency tokens to wallet and mints `amount` NFTs to purchaser.
     * @param amount Amount of tokens to buy
     */
    function buyTokens(uint256 amount) external;

    /**
     * @notice Returns number of tranches used so far
     * @return Number of tranches
     */
    function getTranchesCount() external view returns (uint256);

    /**
     * @notice Creates new token tranche
     * @param start Starting tranche block number
     * @param kolPrice Price per token for KOL whitelisted
     */
    function addTranche(uint256 start, uint256 kolPrice) external;

    function addToKolWhitelist(address[] memory accounts) external;

    function addToFreeMintsWhitelist(address[] memory accounts) external;

    function removeFromKolWhitelist(address[] calldata accounts) external;

    /**
     * @notice Removes accounts from whitelist
     * @dev Operation is idempotent - if account is not on whitelist than nothing happens
     * @param accounts Accounts to be removed from whitelist
     */
    function removeFromFreeMintsWhitelist(address[] calldata accounts) external;

    /**
     * @notice Returns current tranche details excluding whitelist info
     * @return Tranche details
     */
    function getCurrentTrancheDetails() external view returns (TrancheStatus memory);

    /**
     * @notice Returns whether account is whitelisted in current tranche
     * @return Whether account is whitelisted
     */
    function isAccountFreeMintsWhitelisted(address account) external view returns (bool);

    function isAccountKolWhitelisted(address account) external view returns (bool);

    /**
     * @notice Returns tokens supply intended for sale (available + sold) in current tranche
     * @return Tokens supply intended for sale
     */
    function supply() external view returns (uint256);

    /**
     * @notice Returns tokens in current tranche
     * @return Tokens sold in current tranche
     */
    function sold() external view returns (uint256);

    /**
     * @notice Returns number of tokens available for account
     * @return Number of available tokens
     */
    function available(address account) external view returns (uint256);

    /**
     * @notice Returns number of tokens sender bought in
     * @param account account to check bought count for
     * @return Number of available tokens
     */
    function boughtCountKol(address account) external view returns (uint256);

    /**
     * @notice Returns number of tokens available for account
     * @param account account to check bought count for
     * @return Number of available tokens
     */
    function boughtCountFreeMint(address account) external view returns (uint256);
}