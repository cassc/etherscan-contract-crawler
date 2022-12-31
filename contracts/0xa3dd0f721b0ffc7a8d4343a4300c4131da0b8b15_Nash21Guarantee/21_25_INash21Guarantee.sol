// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/// @title The interface of Nash21Guarantee
/// @notice Handles payments of the Nash21 protocol, regarding tokens
/// @dev Gets payments from tenants and pays renters / token owners
interface INash21Guarantee {
    /// @notice Emitted when someone claims
    /// @param id Token identifier
    /// @param account Owner of the token
    /// @param amount Amount distributed
    /// @param currency Hashed currency symbol
    event Claim (
        uint256 indexed id,
        address indexed account,
        uint256 amount,
        bytes32 currency
    );

    /// @notice Emitted when someone pays
    /// @param id Token identifier
    /// @param account Account paying
    /// @param amount Amount paid
    /// @param currency Hashed currency symbol
    event Pay (
        uint256 indexed id,
        address indexed account,
        uint256 amount,
        bytes32 currency
    );

    /// @notice Emitted when a non-fungible token is splitted
    /// @param id Token identifier
    /// @param account Owner of the token
    /// @param timestamp Time when the token is splitted
    /// @param beforeId Token identifier for the new token before to timestamp
    /// @param afterId Token identifier for the new token after to timestamp
    event Split (
        uint256 indexed id,
        address indexed account,
        uint256 timestamp,
        uint256 beforeId,
        uint256 afterId
    );

    /// @notice Emitted when a new price feed is set
    /// @param currency Hashed currency symbol
    /// @param feed Address of the price feed oracle
    event NewFeed (
        bytes32 indexed currency,
        address feed
    );


    /// @notice Emitted when someone funds the contract
    /// @param token Address of the token of the funds
    /// @param from Address of the sender
    /// @param amount Amount of the funds
    event Fund (
        address indexed token,
        address indexed from,
        uint256 amount
    );

    /// @notice Distributes the claimable amount of a token
    /// @param id Token identifier
    function claim (
        uint256 id
    )
        external;

    /// @notice Distributes the claimable amount of tokens
    /// @param ids Tokens identifiers
    function claimBatch (
        uint256[] memory ids
    )
        external;

    /// @notice Returns the claimable amount of a token
    /// @param id Token identifier
    /// @return Claimable amount
    function claimable (
        uint256 id
    )
        external
        view
        returns (
            uint256
        );

    /// @notice Returns the distributed amount of a token
    /// @param id Token identifier
    /// @return Distributed amount
    function distributed (
        uint256 id
    )
        external
        view
        returns (
            uint256
        );

    /// @notice Extracts ERC20 funds to an address
    /// @param token ERC20 tokens to extract
    /// @param to Address where tokens go to
    /// @param amount Amount of tokens
    function extractFunds (
        address token,
        address to,
        uint256 amount
    )
        external;

    /// @notice Funds the guarantee contract with an ERC20 token
    /// @param token ERC20 token for funding
    /// @param from Address from where tokens come
    /// @param amount Amount of tokens
    function fund (
        address token,
        address from,
        uint256 amount
    )
        external;

    /// @notice Returns the expected amount released (of the value) for a token
    /// @param id Token identifier
    /// @return Amount released
    function getReleased (
        uint256 id
    )
        external
        view
        returns (
            uint256
        );

    /// @notice Initializes the contract
    /// @param initialCurrency Hashed currency symbol
    /// @param initialFeed Price feed address
    function initialize (
        bytes32 initialCurrency,
        address initialFeed
    )
        external;

    /// @notice Returns the paid amount for a token
    /// @param id Token identifier
    /// @return Paid amount
    function paid (
        uint256 id
    )
        external
        view
        returns (
            uint256
        );

    /// @notice Pays an amount for a token
    /// @param id Token identifier
    /// @param amount Amount to pay
    function pay (
        uint256 id,
        uint256 amount
    )
        external;

    /// @notice Pays an amount for a token
    /// @param ids Token identifier
    /// @param amounts Amount to pay
    function payBatch (
        uint256[] calldata ids,
        uint256[] calldata amounts
    )
        external;

    /// @notice Returns the price feed address for a currency
    /// @param currency Hashed currency symbol
    /// @return Price feed address for a currency
    function feeds (
        bytes32 currency
    )
        external
        view
        returns (
            address
        );

    /// @notice Sets new price feeds on batch
    /// @param currencies Array of hashed currency symbols
    /// @param feeds Array of price feed addresses
    function setFeeds (
        bytes32[] memory currencies,
        address[] memory feeds
    )
        external;

    /// @notice Splits a token into two new tokens
    /// @dev Manages the distributed and paid amounts
    /// @param id Token identifier
    /// @param timestamp Time when the token is splitted
    /// @return Before to and after to timestamp token identifiers
    function split (
        uint256 id,
        uint256 timestamp
    )
        external
        returns (
            uint256,
            uint256
        );

    /// @notice Returns the amount in USDT of a selected amount of currency
    /// @param currency Hashed currency symbol
    /// @param amount Amount to be transformed
    function transformCurrency (
        bytes32 currency,
        uint256 amount
    )
        external
        view
        returns (
            uint256
        );
}