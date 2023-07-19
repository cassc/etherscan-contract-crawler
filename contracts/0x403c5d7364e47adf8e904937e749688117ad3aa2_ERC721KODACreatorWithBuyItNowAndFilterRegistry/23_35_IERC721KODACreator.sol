pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

/// @author KnownOrigin Labs - https://knownorigin.io/
interface IERC721KODACreator {
    error AlreadySet();
    error EditionDisabled();
    error EditionSizeTooLarge();
    error EditionSizeTooSmall();
    error EmptyString();
    error InvalidOwner();
    error IsOpenEdition();
    error OwnerRevoked();
    error PrimarySaleMade();
    error ZeroAddress();

    event EditionSizeUpdated(uint256 indexed _editionId, uint256 _editionSize);
    event EditionFundsHandlerUpdated(
        uint256 indexed _editionId,
        address indexed _handler
    );

    /// @dev Function value can be more easily updated in event of an upgrade
    function version() external pure returns (string memory);

    /// @dev Returns the address that will receive sale proceeds for a given edition
    function editionFundsHandler(
        uint256 _editionId
    ) external view returns (address);

    /// @dev returns the ID of the next token that will be sold from a pre-minted edition
    function getNextAvailablePrimarySaleToken(
        uint256 _editionId
    ) external view returns (uint256);

    /// @dev returns the ID of the next token that will be sold from a pre-minted edition
    function getNextAvailablePrimarySaleToken(
        uint256 _editionId,
        uint256 _startId
    ) external view returns (uint256);

    /// @dev allows the owner or additional minter to mint open edition tokens
    function mintOpenEditionToken(
        uint256 _editionId,
        address _recipient
    ) external returns (uint256);

    /**
     * @dev allows the contract owner or additional minter to mint multiple open edition tokens
     */
    function mintMultipleOpenEditionTokens(
        uint256 _editionId,
        uint256 _quantity,
        address _recipient
    ) external;

    /// @dev Allows creation of an edition including minting a portion (or all) tokens upfront to any address and setting metadata
    function createEdition(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        string calldata _uri
    ) external returns (uint256);

    /// @dev Allows creation of an edition including minting a portion (or all) tokens upfront to any address, setting metadata and a funds handler for this edition
    function createEditionAsCollaboration(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        address _collabFundsHandler,
        string calldata _uri
    ) external returns (uint256 editionId);

    /// @dev allows the contract owner to creates an edition of specified size and mints all tokens to their address
    function createEditionAndMintToOwner(
        uint32 _editionSize,
        string calldata _uri
    ) external returns (uint256);

    /// @dev Allows the contract owner to create an edition of specified size for lazy minting
    function createOpenEdition(
        uint32 _editionSize,
        string calldata _uri
    ) external returns (uint256);

    /// @dev Allows the contract owner to create an edition of specified size for lazy minting as a collaboration with another entity, passing in a seperate funds handler for the edition
    function createOpenEditionAsCollaboration(
        uint32 _editionSize,
        address _collabFundsHandler,
        string calldata _uri
    ) external returns (uint256 editionId);

    /// @dev Allows the contract owner to add additional minters if the appropriate minting logic is in place
    function updateAdditionalMinterEnabled(
        address _minter,
        bool _enabled
    ) external;

    /// @dev Allows the contract owner to set a specific fund handler for an edition, otherwise the default for all editions is used
    function updateEditionFundsHandler(
        uint256 _editionId,
        address _fundsHandler
    ) external;

    /// @dev allows the contract owner to update the number of tokens that can be minted in an edition
    function updateEditionSize(
        uint256 _editionId,
        uint32 _editionSize
    ) external;

    /// @dev Provided no primary sale has been made, an artist can correct any mistakes in their token URI
    function updateURIIfNoSaleMade(
        uint256 _editionId,
        string calldata _newURI
    ) external;
}