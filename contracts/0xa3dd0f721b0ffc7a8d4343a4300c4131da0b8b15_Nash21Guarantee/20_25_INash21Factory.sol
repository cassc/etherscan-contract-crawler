// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

/// @title The interface of Nash21Factory
/// @notice Handles non-fungible tokens balances and actions
/// @dev Any data regarding non-fungible tokens is placed here
interface INash21Factory is
    IERC721EnumerableUpgradeable
{
    struct Data {
        // Origin token identifier
        uint256 origin;
        // Value of the token (in currency)
        uint256 value;
        // Hashed currency symbol
        bytes32 currency;
        // Start date of the token contract
        uint256 startDate;
        // End date of the token contract
        uint256 endDate;
        // Token data URI
        string uri;
        // Recipient address
        address recipient;
        // Hashed property of the contract
        bytes32 hashId;
    }

    /// @notice Emitted when a new token is authorized
    /// @param hashId Hashed token identifier
    /// @param account Owner of the token
    /// @param id Token identifier
    /// @param value Total value of the contract
    /// @param currency Hashed currency symbol (reg. value)
    /// @param startDate Start date of the contract
    /// @param endDate End date of the contract
    /// @param uri Token data URI
    event Authorize (
        bytes32 indexed hashId,
        address indexed account,
        uint256 indexed id,
        uint256 value,
        bytes32 currency,
        uint256 startDate,
        uint256 endDate,
        string uri
    );

    /// @notice Emitted when a token is burned (usually when splitted)
    /// @param account Owner of the token
    /// @param id Token identifier
    event Burn (
        address indexed account,
        uint256 indexed id
    );

    /// @notice Emitted when a token is minted
    /// @param account Owner of the token
    /// @param id Token identifier
    event Mint (
        address indexed account,
        uint256 indexed id
    );

    /// @notice Emitted when a token URI is set permanently
    /// @param _value URI
    /// @param _id Indexed token identifier
    event PermanentURI (
        string _value,
        uint256 indexed _id
    ); //You can indicate to OpenSea that an NFT's metadata is no longer changeable by anyone

    /// @notice Emitted when the contract URI is set
    /// @param contractURI Contract URI
    event SetContractURI (string contractURI);

    /// @notice Emitted when the tokenCreationFee is set
    /// @param hashId Hashed token identifier
    /// @param fee Creation fee
    event SetTokenCreationFee (
        bytes32 indexed hashId,
        uint256 fee
    );

    /// @notice Emitted when the tokenTransferFee is set
    /// @param id Token identificator
    /// @param fee Transfer fee
    event SetTokenTransferFee (
        uint256 indexed id,
        uint256 fee
    );

    /// @notice Emitted when the ownerTransferFee is set
    /// @param owner Origin account
    /// @param fee Transfer fee
    event SetOwnerTransferFee (
        address indexed owner,
        uint256 fee
    );

    /// @notice Emitted when the token URI is set
    /// @param tokenURI Token URI
    event SetTokenURI (
        uint256 id,
        string tokenURI
    );

    /// @notice Emitted when the creation of a token is unauthorized
    /// @param id Token identificator
    event Unauthorize (
        uint256 id
    );

    /// @notice Emitted when the creation of a token is unauthorized
    /// @param hash Authorized hash
    event UnauthorizeHash (
        bytes32 hash
    );

    /// @notice Authorizes and creates a new token
    /// @param hashId Hashed token identifier
    /// @param account Owner of the token
    /// @param value Total value of the contract
    /// @param currency Hashed currency symbol (reg. value)
    /// @param startDate Start date of the contract
    /// @param endDate End date of the contract
    /// @param uri Token data URI
    /// @return Token identifier
    function authAndCreate (
        bytes32 hashId,
        address account,
        uint256 value,
        bytes32 currency,
        uint256 startDate,
        uint256 endDate,
        string memory uri
    )
        external
        payable
        returns (
            uint256
        );

    /// @notice Authorizes a new token
    /// @param hashId Hashed token identifier
    /// @param account Owner of the token
    /// @param value Total value of the contract
    /// @param currency Hashed currency symbol (reg. value)
    /// @param startDate Start date of the contract
    /// @param endDate End date of the contract
    /// @param uri Token data URI
    /// @return Token identifier
    function authorize (
        bytes32 hashId,
        address account,
        uint256 value,
        bytes32 currency,
        uint256 startDate,
        uint256 endDate,
        string memory uri
    )
        external
        payable
        returns (
            uint256
        );

    /// @notice Authorizes a new token
    /// @param hashId Hashed token identifier
    /// @param account Owner of the token
    /// @param value Total value of the contract
    /// @param currency Hashed currency symbol (reg. value)
    /// @param startDate Start date of the contract
    /// @param endDate End date of the contract
    /// @param _creationFee CreationFee of the token
    /// @param uri Token data URI
    /// @return Token identifier
    function authorizeAndSetFees (
        bytes32 hashId,
        address account,
        uint256 value,
        bytes32 currency,
        uint256 startDate,
        uint256 endDate,
        uint256 _creationFee,
        string memory uri
    )
        external
        payable
        returns (
            uint256
        );

    /// @notice Returns authorized owner of a token or zero address if token is not authorized yet
    /// @param id Token identifier
    /// @return Owner of the token
    function authorized (
        uint256 id
    )
        external
        view
        returns (
            address
        );

    /// @notice Returns the base uri for every token
    /// @return Base URI
    function baseURI ()
        external
        view
        returns (
            string memory
        );

    /// @notice Returns the factory contract uri
    /// @return Contract URI
    function contractURI ()
        external
        view
        returns (
            string memory
        );

    /// @notice Creates a previously authorized token
    /// @param id Token identifier
    function create (
        uint256 id
    )
        external
        payable;

    /// @notice Creates a new token with auth signature
    /// @param hashId Hashed token identifier
    /// @param account Owner of the token
    /// @param value Total value of the contract
    /// @param currency Hashed currency symbol (reg. value)
    /// @param startDate Start date of the contract
    /// @param endDate End date of the contract
    /// @param uri Token data URI
    /// @param deadline Latest time by which previous data is valid
    /// @param signature Signature of the previous data
    /// @param signer Signer of the previous data
    function createWithSignature (
        bytes32 hashId,
        address account,
        uint256 value,
        bytes32 currency,
        uint256 startDate,
        uint256 endDate,
        string memory uri,
        uint256 deadline,
        bytes memory signature,
        address signer
    )
        external
        payable;

    /// @notice Returns the creation fee
    /// @return Creation fee with 18 decimals
    function creationFee ()
        external
        view
        returns (
            uint256
        );

    /// @notice Returns on-chain data of a token
    /// @param id Token identifier
    /// @return origin Origin id of the token (diff when splitted)
    /// @return value Value of the token
    /// @return currency Hashed currency symbol of the token
    /// @return startDate Start date of the token
    /// @return endDate End date of the token
    /// @return uri Token data URI
    /// @return recipient Recipient address for claiming
    /// @return hashId Hashed property of the contract
    function data (
        uint256 id
    )
        external
        view
        returns (
            uint256 origin,
            uint256 value,
            bytes32 currency,
            uint256 startDate,
            uint256 endDate,
            string memory uri,
            address recipient,
            bytes32 hashId
        );

    /// @notice Returns the creation fee for a token
    /// @param id Token identifier
    /// @return Creation fee for a token
    function getCreationFee (
        uint256 id
    )
        external
        view
        returns (
            uint256
        );

    /// @notice Returns the transfer fee of a token
    /// @param id Token identifier
    /// @return Transfer fee dependant on value
    function getTransferFee (
        uint256 id
    )
        external
        view
        returns (
            uint256
        );

    /// @notice Initializes the contract
    function initialize ()
        external;

    /// @notice Sets a new base URI
    /// @param uri New URI for the base tokenURIs
    function setBaseURI (
        string memory uri
    )
        external
        payable;

    /// @notice Sets a new contract URI
    /// @param contractURI_ New URI for the factory contract
    function setContractURI (
        string memory contractURI_
    )
        external
        payable;

    /// @notice Sets a new creation fee
    /// @param fee Creation fee with 18 decimals
    function setCreationFee (
        uint256 fee
    )
        external
        payable;

    /// @notice Sets a new address for a token
    /// @param id Token identifier
    /// @param recipient Recipient address
    function setRecipient (
        uint256 id,
        address recipient
    )
        external
        payable;

    /// @notice Sets a new creation fee for a token
    /// @param fee Creation fee with 18 decimals
    /// @dev If tokenCreationFee is 0 use global creationFee
    /// @dev If tokenCreationFee is >100 ether use 0
    /// @dev If tokenCreationFee is 0<=fee<=100 ether use tokenCreationFee
    /// @param hashId Hashed token identifier
    function setTokenCreationFee (
        uint256 fee,
        bytes32 hashId
    )
        external
        payable;

    /// @notice Sets a new transfer fee for a token
    /// @dev If tokenTransferFee is 0 use global transferFee
    /// @dev If tokenTransferFee is >100 ether use 0
    /// @dev If tokenTransferFee is 0<=fee<=100 ether use tokenTransferFee
    /// @param fee Creation fee with 18 decimals
    /// @param id Token identificator
    function setTokenTransferFee (
        uint256 fee,
        uint256 id
    )
        external
        payable;

    /// @notice Sets a new transfer fee for an account
    /// @dev If ownerTransferFee is 0 use global transferFee
    /// @dev If ownerTransferFee is >100 ether use 0
    /// @dev If ownerTransferFee is 0<=fee<=100 ether use ownerTransferFee
    /// @param fee Creation fee with 18 decimals
    /// @param owner Origin account
    function setOwnerTransferFee (
        uint256 fee,
        address owner
    )
        external
        payable;

    /// @notice Sets a new token URI
    /// @param id Token identifier
    /// @param _tokenURI New URI for a specific token
    function setTokenURI (
        uint256 id,
        string memory _tokenURI
    )
        external
        payable;

    /// @notice Sets a new transfer fee
    /// @param fee Transfer fee with 18 decimals
    function setTransferFee (
        uint256 fee
    )
        external
        payable;

    /// @notice Splits a token into two new tokens
    /// @param account Account that splits the token
    /// @param id Token identifier
    /// @param timestamp Date when the token is splitted
    /// @return id1 New token identifier before to split date
    /// @return id2 New token identifier after to split date
    function split (
        address account,
        uint256 id,
        uint256 timestamp
    )
        external
        payable
        returns (
            uint256 id1,
            uint256 id2
        );

    /// @notice Returns a token URI
    /// @param id Token identifier
    /// @return Token URI
    function tokenURI (
        uint256 id
    )
        external
        returns (
            string memory
        );

    /// @notice Returns the transferFee of a token
    /// @dev If tokenTransferFee is 0 use global transferFee
    /// @dev If tokenTransferFee is >100 ether use 0
    /// @dev If tokenTransferFee is 0<=fee<=100 ether use tokenTransferFee
    /// @param id Token identifier
    /// @return Token transfer fee
    function tokenTransferFee (
        uint256 id
    )
        external
        view
        returns (
            uint256
        );

    /// @notice Returns the transferFee of an account
    /// @dev If ownerTransferFee is 0 use global transferFee
    /// @dev If ownerTransferFee is >100 ether use 0
    /// @dev If ownerTransferFee is 0<=fee<=100 ether use ownerTransferFee
    /// @param owner Token identifier
    /// @return Token transfer fee
    function ownerTransferFee (
        address owner
    )
        external
        view
        returns (
            uint256
        );

    /// @notice Returns the creationFee of a token
    /// @dev If tokenCreationFee is 0 use global creationFee
    /// @dev If tokenCreationFee is >100 ether use 0
    /// @dev If tokenCreationFee is 0<=fee<=100 ether use tokenCreationFee
    /// @param hashId Hashed token identifier
    /// @return Token creation fee
    function tokenCreationFee (
        bytes32 hashId
    )
        external
        view
        returns (
            uint256
        );

    /// @notice Returns the transfer fee
    /// @return Transfer fee with 18 decimals
    function transferFee ()
        external
        view
        returns (
            uint256
        );

    /// @notice Unauthorizes the creation of the token for the hashed identifier
    /// @param id Token identifier
    function unauthorize (
        uint256 id
    )
        external
        payable;

    /// @notice Unauthorizes the creation of the token for authorized data
    /// @param hashId Hashed token identifier
    function unauthorizeOffchainSign (
        bytes32 hashId /*, address account, uint256 value, bytes32 currency, uint256 startDate, uint256 endDate, string memory uri, uint256 deadline */
    )
        external
        payable;

    /// @notice Returns whether the creation of a token for token identifier is unauthorized or not
    /// @param hashId Hashed token identifier
    /// @return Whether the creation of a token for a token identifier is unauthorized or not
    function unauthorized (
        bytes32 hashId
    )
        external
        view
        returns (
            bool
        );
}