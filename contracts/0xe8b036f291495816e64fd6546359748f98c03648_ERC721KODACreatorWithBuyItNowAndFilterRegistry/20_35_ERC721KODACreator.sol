// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {KODASettings} from "../KODASettings.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Metadata, IERC2981} from "./interfaces/IERC721KODAEditions.sol";
import {IERC721KODACreator} from "./interfaces/IERC721KODACreator.sol";

import {ERC721KODAEditions} from "./ERC721KODAEditions.sol";

/**
 * @author KnownOrigin Labs - https://knownorigin.io/
 *
 * @dev Contract which extends the KO Edition base enabling creator specific functionality
 */
contract ERC721KODACreator is ERC721KODAEditions, IERC721KODACreator {
    /**
     * @notice KODA Settings
     * @dev Defines the global settings for the linked KODA platform
     */
    KODASettings public kodaSettings;

    /**
     * @notice Default Funds Handler
     * @dev Address of the fund handler that receives funds for all editions if an alternative has not been set in {_editionFundsHandler}
     */
    address public defaultFundsHandler;

    /**
     * @notice Additional address enabled as a minter
     * @dev returns true if the address has been enabled as an additional minter
     *
     * - requires addition logic in place in inherited minting contracts
     */
    mapping(address => bool) public additionalMinterEnabled;

    /**
     * @notice Additional address enabled as creators of editions
     * @dev returns true if the address has been enabled as an additional creator
     *
     */
    mapping(address => bool) public additionalCreatorEnabled;

    /// @dev mapping of edition ID => address of the fund handler for a specific edition
    mapping(uint256 => address) internal _editionFundsHandler;

    modifier onlyApprovedMinter() {
        _onlyApprovedMinter();
        _;
    }

    modifier onlyApprovedCreator() {
        _onlyApprovedCreator();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev initialize method that replaces constructor in upgradeable contract
     *
     * Requirements:
     *
     * - `_artistAndOwner` must not be the zero address
     * - `_name` and `_symbol` must not be empty strings
     * - `_defaultFundsHandler` must not be the zero address
     * - `_settings` must not be the zero address
     * - should call all upgradeable `__[ContractName]_init()` methods from inherited contracts
     *
     * @param _artistAndOwner Who will be assigned attribution as lead artist and initial owner of the contract.
     * @param _name the NFT name
     * @param _symbol the NFT symbol
     * @param _defaultFundsHandler the address of the default address for receiving funds for all editions
     * @param _settings address of the platform KODASettings contract
     * @param _secondaryRoyaltyPercentage the default percentage value used for calculating royalties for secondary sales
     */
    function initialize(
        address _artistAndOwner,
        string calldata _name,
        string calldata _symbol,
        address _defaultFundsHandler,
        KODASettings _settings,
        uint256 _secondaryRoyaltyPercentage,
        address _operatorRegistry,
        address _subscriptionOrRegistrantToCopy
    ) external initializer {
        if (_artistAndOwner == address(0)) revert ZeroAddress();
        if (address(_settings) == address(0)) revert ZeroAddress();
        if (_defaultFundsHandler == address(0)) revert ZeroAddress();

        if (_artistAndOwner == address(this)) revert InvalidOwner();
        if (bytes(_name).length == 0 || bytes(_symbol).length == 0)
            revert EmptyString();

        name = _name;
        symbol = _symbol;

        defaultFundsHandler = _defaultFundsHandler;
        kodaSettings = _settings;
        nextEditionId = MAX_EDITION_SIZE;
        originalDeployer = _artistAndOwner;

        __KODABase_init(_secondaryRoyaltyPercentage);
        __Module_init(_operatorRegistry, _subscriptionOrRegistrantToCopy);

        _transferOwnership(_artistAndOwner);
    }

    /// @dev Allow a module to define custom init logic
    function __Module_init(
        address _operatorRegistry,
        address _subscriptionOrRegistrantToCopy
    ) internal virtual {}

    // ********** //
    // * PUBLIC * //
    // ********** //

    function contractURI() public view returns (string memory) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return
            string.concat(
                kodaSettings.baseKOApi(),
                "/network/",
                Strings.toString(id),
                "/contracts/",
                Strings.toHexString(address(this))
            );
    }

    // * Contract Metadata * //

    /**
     * @notice Royalty Info for a Token Sale
     * @dev returns the royalty details for the edition a token belongs to - falls back to defaults
     * @param _tokenId the id of the token being sold
     * @param _salePrice currency/token agnostic sale price
     * @return receiver address to send royalty consideration to
     * @return royaltyAmount value to be sent to the receiver
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) public view override returns (address receiver, uint256 royaltyAmount) {
        uint256 editionId = _tokenEditionId(_tokenId);

        receiver = editionFundsHandler(editionId);
        royaltyAmount =
            (_salePrice * editionRoyaltyPercentage(editionId)) /
            MODULO;
    }

    /**
     * @notice Check for Interface Support
     * @dev Returns true if this contract implements the interface defined by `interfaceId`.
     * @param interfaceId the ID of the interface to check
     * @return bool the interface is supported
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public pure virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId || // ERC165
            interfaceId == type(IERC721).interfaceId || // ERC721
            interfaceId == type(IERC721Metadata).interfaceId || // ERC721 Metadata
            interfaceId == type(IERC2981).interfaceId || // ERC2981
            interfaceId == type(IERC721KODACreator).interfaceId;
    }

    /**
     * @notice Version of the Contract used in combination with {description}
     * @dev Function value can be more easily updated in event of an upgrade
     * @return string semver version
     */
    function version() external pure override returns (string memory) {
        return "1.0.0";
    }

    // * Editions * //

    /**
     * @notice Edition Funds Handler
     * @dev Returns the address that will receive sale proceeds for a given edition
     * @param _editionId the ID of an edition
     * @return address the funds handler address
     */
    function editionFundsHandler(
        uint256 _editionId
    ) public view override returns (address) {
        address fundsHandler = _editionFundsHandler[_editionId];

        if (fundsHandler != address(0)) {
            return fundsHandler;
        }

        return defaultFundsHandler;
    }

    /**
     * @notice Next Edition Token for Sale
     * @dev returns the ID of the next token that will be sold from a pre-minted edition
     * @param _editionId the ID of the edition
     * @return uint256 the next tokenId from the edition to be sold
     */
    function getNextAvailablePrimarySaleToken(
        uint256 _editionId
    ) public view override returns (uint256) {
        if (isOpenEdition(_editionId)) revert IsOpenEdition();
        return
            _getNextAvailablePrimarySaleToken(
                _editionId,
                _editionMaxTokenId(_editionId)
            );
    }

    /**
     * @notice Next Edition Token for Sale
     * @dev returns the ID of the next token that will be sold from a pre-minted edition
     * @param _editionId the ID of the edition
     * @param _startId the ID of the starting point to look for the next token to sell
     * @return uint256 the next tokenId from the edition to be sold
     */
    function getNextAvailablePrimarySaleToken(
        uint256 _editionId,
        uint256 _startId
    ) public view override returns (uint256) {
        if (isOpenEdition(_editionId)) revert IsOpenEdition();
        return _getNextAvailablePrimarySaleToken(_editionId, _startId);
    }

    /**
     * @notice Mint An Open Edition Token
     * @dev allows the contract owner or additional minter to mint an open edition token
     * @param _editionId the ID of the edition to mint a token from
     * @param _recipient the address to transfer the token to
     */
    function mintOpenEditionToken(
        uint256 _editionId,
        address _recipient
    ) public override onlyApprovedMinter returns (uint256) {
        return _mintSingleOpenEditionTo(_editionId, _recipient);
    }

    /**
     * @notice Mint Multiple Open Edition Tokens to the Edition Owner
     * @dev allows the contract owner or additional minter to mint
     * @param _editionId the ID of the edition to mint a token from
     * @param _quantity the number of tokens to mint
     */
    function mintMultipleOpenEditionTokens(
        uint256 _editionId,
        uint256 _quantity,
        address _recipient
    ) public virtual override onlyApprovedMinter {
        if (_recipient != editionOwner(_editionId)) revert InvalidRecipient();
        _mintMultipleOpenEditionToOwner(_editionId, _quantity);
    }

    // ********* //
    // * OWNER * //
    // ********* //

    /**
     * @notice Create a new Edition - optionally mint tokens and set a custom creator address and edition metadata URI
     * @dev Allows creation of an edition including minting a portion (or all) tokens upfront to any address and setting metadata
     * @param _editionSize the initial maximum supply of tokens in the edition
     * @param _mintQuantity the number of tokens to mint upfront - minting less than the edition size is considered an open edition
     * @param _recipient the address to transfer any minted tokens to
     * @param _creator an optional creator address to reflected in edition details
     * @param _uri the URI for fixed edition metadata
     * @return uint256 the new edition ID
     */
    function createEdition(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        string calldata _uri
    ) public override onlyApprovedCreator returns (uint256) {
        // mint to the minter or owner if address not specified
        address to = _recipient == address(0)
            ? additionalCreatorEnabled[msg.sender] ? msg.sender : owner()
            : _recipient;

        return _createEdition(_editionSize, _mintQuantity, to, _creator, _uri);
    }

    /**
     * @notice Create a new Edition as a collaboration with another entity, passing in a seperate funds handler for the edition - optionally mint tokens and set a custom creator address and edition metadata URI
     * @dev Allows creation of an edition including minting a portion (or all) tokens upfront to any address, setting metadata and a funds handler for this edition
     * @param _editionSize the initial maximum supply of tokens in the edition
     * @param _mintQuantity the number of tokens to mint upfront - minting less than the edition size is considered an open edition
     * @param _recipient the address to transfer any minted tokens to
     * @param _creator an optional creator address to reflected in edition details
     * @param _collabFundsHandler the address for receiving funds for this edition
     * @param _uri the URI for fixed edition metadata
     * @return editionId the new edition ID
     */
    function createEditionAsCollaboration(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        address _collabFundsHandler,
        string calldata _uri
    ) public override onlyApprovedCreator returns (uint256 editionId) {
        // mint to the minter or owner if address not specified
        address to = _recipient == address(0)
            ? additionalCreatorEnabled[msg.sender] ? msg.sender : owner()
            : _recipient;

        editionId = _createEdition(
            _editionSize,
            _mintQuantity,
            to,
            _creator,
            _uri
        );

        _updateEditionFundsHandler(editionId, _collabFundsHandler);
    }

    /**
     * @notice Create Edition and Mint All Tokens to Owner
     * @dev allows the contract owner to creates an edition of specified size and mints all tokens to their address
     * @param _editionSize the number of tokens in the edition
     * @param _uri the metadata URI for the edition
     * @return uint256 the new edition ID
     */
    function createEditionAndMintToOwner(
        uint32 _editionSize,
        string calldata _uri
    ) public override onlyOwner returns (uint256) {
        return
            _createEdition(
                _editionSize,
                _editionSize,
                owner(),
                address(0),
                _uri
            );
    }

    /**
     * @notice Create Edition for Lazy Minting
     * @dev Allows the contract owner to create an edition of specified size for lazy minting
     * @param _editionSize the number of tokens in the edition
     * @param _uri the metadata URI for the edition
     * @return uint256 the new edition ID
     */
    function createOpenEdition(
        uint32 _editionSize,
        string calldata _uri
    ) public override onlyApprovedCreator returns (uint256) {
        return
            _createEdition(
                _editionSize == 0 ? MAX_EDITION_SIZE : _editionSize,
                0,
                additionalCreatorEnabled[msg.sender] ? msg.sender : owner(),
                address(0),
                _uri
            );
    }

    /**
     * @notice Create Edition for Lazy Minting as a collaboration
     * @dev Allows the contract owner to create an edition of specified size for lazy minting as a collaboration with another entity, passing in a seperate funds handler for the edition
     * @param _editionSize the number of tokens in the edition
     * @param _collabFundsHandler the address for receiving funds for this edition
     * @param _uri the metadata URI for the edition
     * @return editionId the new edition ID
     */
    function createOpenEditionAsCollaboration(
        uint32 _editionSize,
        address _collabFundsHandler,
        string calldata _uri
    ) public override onlyApprovedCreator returns (uint256 editionId) {
        editionId = _createEdition(
            _editionSize == 0 ? MAX_EDITION_SIZE : _editionSize,
            0,
            additionalCreatorEnabled[msg.sender] ? msg.sender : owner(),
            address(0),
            _uri
        );

        _updateEditionFundsHandler(editionId, _collabFundsHandler);
    }

    /**
     * @notice Enable/disable minting using an additional address
     * @dev allows the contract owner to enable/disable additional minting addresses
     * @param _minter address of the additional minter
     * @param _enabled whether the address is able to mint
     */
    function updateAdditionalMinterEnabled(
        address _minter,
        bool _enabled
    ) external onlyOwner {
        additionalMinterEnabled[_minter] = _enabled;
        emit AdditionalMinterEnabled(_minter, _enabled);
    }

    /**
     * @notice Enable/disable edition creation using an additional address
     * @dev allows the contract owner to enable/disable additional creator addresses
     * @param _creator address of the additional creator
     * @param _enabled whether the address is able to be a creator
     */
    function updateAdditionalCreatorEnabled(
        address _creator,
        bool _enabled
    ) external onlyOwner {
        additionalCreatorEnabled[_creator] = _enabled;
        emit AdditionalCreatorEnabled(_creator, _enabled);
    }

    /**
     * @notice Update Edition Funds Handler
     * @dev Allows the contract owner to set a specific fund handler for an edition, otherwise the default for all editions is used
     * @param _editionId the ID of the edition
     * @param _fundsHandler the address of the new funds handler for the edition
     */
    function updateEditionFundsHandler(
        uint256 _editionId,
        address _fundsHandler
    ) public override onlyOwner {
        _updateEditionFundsHandler(_editionId, _fundsHandler);
    }

    /// @dev Internal logic for updating edition level funds handler overriding default
    function _updateEditionFundsHandler(
        uint256 _editionId,
        address _fundsHandler
    ) internal {
        if (_fundsHandler == address(0)) revert ZeroAddress();
        if (!_editionExists(_editionId)) revert EditionDoesNotExist();
        if (_editionFundsHandler[_editionId] != address(0)) revert AlreadySet();
        _editionFundsHandler[_editionId] = _fundsHandler;
        emit EditionFundsHandlerUpdated(_editionId, _fundsHandler);
    }

    /**
     * @notice Update Edition Size
     * @dev allows the contract owner to update the number of tokens that can be minted in an edition
     *
     * Requirements:
     *
     * - should not allow edition size to exceed {Konstants-MAX_EDITION_SIZE}
     * - should not allow edition size to be reduced to less than has already been minted
     *
     * @param _editionId the ID of the edition to change the size of
     * @param _editionSize the new size to set for the edition
     *
     * Emits an {EditionSizeUpdated} event.
     */
    function updateEditionSize(
        uint256 _editionId,
        uint32 _editionSize
    ) public override onlyOwner onlyOpenEdition(_editionId) {
        // can't set edition size beyond maximum
        if (_editionSize > MAX_EDITION_SIZE) revert EditionSizeTooLarge();

        unchecked {
            // can't reduce edition size to less than what has been minted already
            if (_editionSize < editionMintedCount(_editionId))
                revert EditionSizeTooSmall();
        }

        _editions[_editionId].editionSize = _editionSize;
        emit EditionSizeUpdated(_editionId, _editionSize);
    }

    /// @dev Provided no primary sale has been made, an artist can correct any mistakes in their token URI
    function updateURIIfNoSaleMade(
        uint256 _editionId,
        string calldata _newURI
    ) external override onlyOwner {
        if (isOpenEdition(_editionId)) {
            if (_owners[_editionId] != address(0)) revert PrimarySaleMade();
        }

        if (
            _owners[_editionId + editionMintedCount(_editionId) - 1] !=
            address(0)
        ) revert PrimarySaleMade();

        _editions[_editionId].uri = _newURI;

        emit EditionURIUpdated(_editionId);
    }

    // ************ //
    // * INTERNAL * //
    // ************ //

    // * Contract Ownership * //

    // @dev Handle transferring and renouncing ownership in one go where owner always has a minimum balance
    // @dev See balanceOf for how the return value is adjusted. We just do this to reduce minting GAS
    function _transferOwnership(address _newOwner) internal override {
        // This is for keeping the balance slot of owner 'dirty'
        address _currentOwner = owner();
        if (_currentOwner != address(0)) {
            _balances[_currentOwner] -= 1;
        }
        if (_newOwner != address(0)) {
            _balances[_newOwner] += 1;
        }

        super._transferOwnership(_newOwner);
    }

    // * Sale Helpers * //

    function _facilitateNextPrimarySale(
        uint256 _editionId,
        address _recipient
    ) internal virtual validateEdition(_editionId) returns (uint256 tokenId) {
        if (_editionSalesDisabled[_editionId]) revert EditionDisabled();

        // Process open edition sale
        if (isOpenEdition(_editionId)) {
            return _facilitateOpenEditionSale(_editionId, _recipient);
        }

        // process batch minted edition
        tokenId = getNextAvailablePrimarySaleToken(_editionId);

        // Re-enter this contract to make address(this) the sender for transferring which should be approved to transfer tokens
        ERC721KODACreator(address(this)).transferFrom(
            ownerOf(tokenId),
            _recipient,
            tokenId
        );
    }

    function _facilitateOpenEditionSale(
        uint256 _editionId,
        address _recipient
    ) internal virtual returns (uint256) {
        // Mint the token on demand
        uint256 tokenId = _mintSingleOpenEditionTo(_editionId, _recipient);

        // Return the token ID
        return tokenId;
    }

    function _getNextAvailablePrimarySaleToken(
        uint256 _editionId,
        uint256 _startId
    ) internal view virtual returns (uint256) {
        unchecked {
            // high to low
            for (_startId; _startId >= _editionId; --_startId) {
                // if no owner set - assume primary if not moved
                if (_owners[_startId] == address(0)) {
                    return _startId;
                }
            }
        }

        revert("Primary market exhausted");
    }

    // * Validators * //

    /// @dev validates that msg.sender is the contract owner or additional minter
    function _onlyApprovedMinter() internal virtual {
        if (msg.sender == owner()) return;
        if (additionalMinterEnabled[msg.sender]) return;
        revert NotAuthorised();
    }

    /// @dev validates that msg.sender is the contract owner or additional creator
    function _onlyApprovedCreator() internal virtual {
        if (msg.sender == owner()) return;
        if (additionalCreatorEnabled[msg.sender]) return;
        revert NotAuthorised();
    }
}