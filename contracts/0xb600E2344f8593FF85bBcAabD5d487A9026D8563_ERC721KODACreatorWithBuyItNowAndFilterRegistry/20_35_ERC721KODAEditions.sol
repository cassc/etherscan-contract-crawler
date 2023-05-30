// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IERC721KODAEditions} from "./interfaces/IERC721KODAEditions.sol";
import {ITokenUriResolver} from "../interfaces/ITokenUriResolver.sol";

import {KODABaseUpgradeable} from "../KODABaseUpgradeable.sol";

/**
 * @author KnownOrigin Labs - https://knownorigin.io/
 * @dev Base contract which extends the ERC721 NFT standards with edition-based minting logic
 */
abstract contract ERC721KODAEditions is
    KODABaseUpgradeable,
    IERC721KODAEditions
{
    // * ERC721 State * //

    bytes4 internal constant ERC721_RECEIVED =
        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /// @notice Token name
    string public name;

    /// @notice Token symbol
    string public symbol;

    /// @dev Mapping of tokenId => owner - only set on first transfer (after mint) such as a primary sale and/or gift
    mapping(uint256 => address) internal _owners;

    /// @dev Mapping of owner => number of tokens owned
    mapping(address => uint256) internal _balances;

    /// @dev Mapping of owner => operator => approved
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /// @dev Mapping of tokenId => approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // * Custom State * //

    /// @dev ownership of latest editions recorded when contract ownership is transferred
    EditionOwnership[] internal _editionOwnerships;

    /// @notice Token URI resolver
    ITokenUriResolver public tokenUriResolver;

    /// @notice Original deployer of the 721 NFT
    address public originalDeployer;

    /// @dev tokens are minted in batches - the first token ID used is representative of the edition ID
    mapping(uint256 => Edition) internal _editions;

    /// @dev Given an edition ID, if the result is not address(0) then a specific creator has been set for an edition
    mapping(uint256 => address) internal _editionCreator;

    /// @dev The number of tokens minted from an open edition
    mapping(uint256 => uint256) internal _editionMintedCount;

    /// @dev For any given edition ID will be non zero if set by the contract owner for an edition
    mapping(uint256 => uint256) internal _editionRoyaltyPercentage;

    /// @dev Allows a creator to disable sales of their edition
    mapping(uint256 => bool) internal _editionSalesDisabled;

    /// @dev determines the maximum size and the next starting ID for each edition i.e. each edition starts at a multiple of 100,000
    uint32 public constant MAX_EDITION_SIZE = 100_000;

    /**
     * @notice Next Edition ID
     * @dev the ID of the edition that will be created next
     */
    uint256 public nextEditionId;

    // ************* //
    // * MODIFIERS * //
    // ************* //

    modifier onlyEditionOwner(uint256 _editionId) {
        _onlyEditionOwner(_editionId);
        _;
    }

    modifier onlyExistingEdition(uint256 _editionId) {
        _onlyExistingEdition(_editionId);
        _;
    }

    modifier onlyExistingToken(uint256 _tokenId) {
        _onlyExistingToken(_tokenId);
        _;
    }

    modifier onlyOpenEdition(uint256 _editionId) {
        _onlyOpenEdition(_editionId);
        _;
    }

    modifier onlyOpenEditionFromTokenId(uint256 _tokenId) {
        uint256 editionId = _tokenEditionId(_tokenId);
        _onlyOpenEdition(editionId);
        _;
    }

    modifier validateEdition(uint256 _editionId) {
        _validateEdition(_editionId);
        _;
    }

    // ********** //
    // * PUBLIC * //
    // ********** //

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     *      function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return uint256 The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        require(_owner != address(0), "Invalid owner");
        return _owner == owner() ? _balances[_owner] - 1 : _balances[_owner];
    }

    // * Approvals * //

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address.
     *      Throws unless `msg.sender` is the current NFT owner, or an authorized
     *      operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external override {
        address owner = ownerOf(_tokenId);
        require(_approved != owner, "Approved is owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Invalid sender"
        );

        _approve(owner, _approved, _tokenId);
    }

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return address The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(
        uint256 _tokenId
    ) public view override returns (address) {
        require(
            _exists(_tokenId),
            "ERC721: approved query for nonexistent token"
        );
        return _tokenApprovals[_tokenId];
    }

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view override returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     *         all of `msg.sender`"s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow
     *      multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public override {
        require(_msgSender() != _operator, "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    // * Transfers * //

    /**
     * @notice An extension to the default ERC721 behaviour, derived from ERC-875.
     * @dev Allowing for batch transfers from the provided address, will fail if from does not own all the tokens
     * @param _from the address to transfer tokens from
     * @param _to the address to transfer tokens to
     * @param _tokenIds list of token IDs to transfer
     */
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) public override {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _safeTransferFrom(_from, _to, _tokenIds[i], bytes(""));
        }
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        _safeTransferFrom(_from, _to, _tokenId, bytes(""));
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *      operator, or the approved address for this NFT. Throws if `_from` is
     *      not the current owner. Throws if `_to` is the zero address. Throws if
     *      `_tokenId` is not a valid NFT. When transfer is complete, this function
     *      checks if `_to` is a smart contract (code size > 0). If so, it calls
     *      {onERC721Received} on `_to` and throws if the return value is not
     *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param _data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) public override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     *          TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
     *          THEY MAY BE PERMANENTLY LOST
     *  @dev Throws unless `_msgSender()` is the current owner, an authorized
     *       operator, or the approved address for this NFT. Throws if `_from` is
     *       not the current owner. Throws if `_to` is the zero address. Throws if
     *       `_tokenId` is not a valid NFT.
     *  @param _from The current owner of the NFT
     *  @param _to The new owner
     *  @param _tokenId The NFT to transfer
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        _transferFrom(_from, _to, _tokenId);
    }

    // * Editions * //

    /**
     * @notice Edition Creator Address
     * @dev returns the address of the creator of works associated with an edition
     * @param _editionId the ID of the edition
     * @return address the address of the creator of the works associated with the edition
     */
    function editionCreator(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (address) {
        return
            _editionCreator[_editionId] == address(0)
                ? editionOwner(_editionId)
                : _editionCreator[_editionId];
    }

    /**
     * @notice Get Edition Details
     * @dev returns the full edition details
     * @param _editionId the ID of the edition
     * @return EditionDetails the full set of properties of the edition
     */
    function editionDetails(
        uint256 _editionId
    )
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (EditionDetails memory)
    {
        return
            EditionDetails(
                editionOwner(_editionId), // edition owner
                editionCreator(_editionId), // edition creator
                _editionId,
                editionMintedCount(_editionId),
                editionSize(_editionId),
                isOpenEdition(_editionId),
                editionURI(_editionId)
            );
    }

    /**
     * @notice Check if an Edition Exists
     * @dev returns whether edition with id `_editionId` exists or not
     * @param _editionId the ID of the edition
     * @return bool does the edition exist
     */
    function editionExists(
        uint256 _editionId
    ) public view override returns (bool) {
        return _editionExists(_editionId);
    }

    /**
     * @notice Maximum Token ID of an Edition
     * @dev returns the last token ID of edition `_editionId` based on the edition's size
     * @param _editionId the ID of the edition
     * @return uint256 the maximum possible token ID
     */
    function editionMaxTokenId(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (uint256) {
        return _editionMaxTokenId(_editionId);
    }

    /**
     * @notice Edition Minted Count
     * @dev returns the number of tokens minted for an edition - returns edition size if count is 0 but a token has been minted due to assumed batch mint
     * @param _editionId the id of the edition to get a count for
     * @return uint256 the number of tokens minted in the edition
     */
    function editionMintedCount(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (uint256) {
        uint256 count = _editionMintedCount[_editionId];
        if (count > 0) return count;

        if (!_editions[_editionId].isOpenEdition)
            return editionSize(_editionId);

        return 0;
    }

    /**
     * @notice Edition Owner
     * @dev calculates the owner of an edition from recorded ownerships - falls back to current contract owner
     * @param _editionId the id of the edition to get the owner of
     * @return address the address of the edition owner
     */
    function editionOwner(
        uint256 _editionId
    ) public view override returns (address) {
        if (!_editionExists(_editionId)) return address(0);

        uint256 count = _editionOwnerships.length;
        if (count == 0) return owner();

        unchecked {
            // the maximum number of ownerships that need checking = the number of editions from the current one to the end
            uint256 toCheck = (nextEditionId - _editionId) / MAX_EDITION_SIZE;

            uint256 i;
            // if less (or equal) need checking than the number of ownerships recorded, only check the latest ownerships
            if (toCheck < count) {
                i = count - toCheck;
            }

            for (i; i < count; i++) {
                if (_editionId <= _editionOwnerships[i].editionId) {
                    return _editionOwnerships[i].editionOwner;
                }
            }
        }

        return owner();
    }

    /**
     * @notice Edition Royalty Percentage
     * @dev returns the default secondary sale royalty percentage or a stored override value if set
     * @param _editionId the id of the edition to get the royalty percentage for
     * @return uint256 the royalty percentage value for the edition
     */
    function editionRoyaltyPercentage(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (uint256) {
        uint256 royaltyOverride = _editionRoyaltyPercentage[_editionId];
        return
            royaltyOverride == 0 ? defaultRoyaltyPercentage : royaltyOverride;
    }

    /**
     * @notice Check if Edition Primary Sales are Disabled
     * @dev returns whether or not primary sales of an edition are disabled
     * @param _editionId the ID of the edition
     * @return bool primary sales are disabled
     */
    function editionSalesDisabled(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (bool) {
        return _editionSalesDisabled[_editionId];
    }

    /**
     * @notice Edition Primary Sale Possible
     * @dev combines the logic of {editionSalesDisabled} and {editionSoldOut}
     * @param _editionId the ID of the edition
     * @return bool is a primary sale of the edition possible
     */
    function editionSalesDisabledOrSoldOut(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (bool) {
        return _editionSalesDisabled[_editionId] || _editionSoldOut(_editionId);
    }

    /**
     * @notice Edition Primary Sale Possible
     * @dev combines the logic of {editionSalesDisabled} and {editionSoldOut}
     * @param _editionId the ID of the edition
     * @param _startId the ID of the token to start checking from
     * @return bool is a primary sale of the edition possible
     */
    function editionSalesDisabledOrSoldOutFrom(
        uint256 _editionId,
        uint256 _startId
    ) public view override onlyExistingEdition(_editionId) returns (bool) {
        return
            _editionSalesDisabled[_editionId] ||
            _editionSoldOutFrom(_editionId, _startId, 0);
    }

    /**
     * @notice Edition Size
     * @dev returns the maximum number of tokens that CAN BE minted in an edition
     *
     * - see {editionMintedCount} for the number of tokens minted in an edition so far
     *
     * @param _editionId the id of the edition
     * @return uint256 the size of the edition
     */
    function editionSize(
        uint256 _editionId
    ) public view override returns (uint256) {
        return _editions[_editionId].editionSize;
    }

    /**
     * @notice Is the Edition Sold Out
     * @dev returns whether on not primary sales are still possible for an edition
     * @param _editionId the ID of the edition
     * @return bool the edition is sold out
     */
    function editionSoldOut(
        uint256 _editionId
    ) public view override onlyExistingEdition(_editionId) returns (bool) {
        return _editionSoldOut(_editionId);
    }

    /**
     * @notice Is the Edition Sold Out after a specific tokenId
     * @dev returns whether on not all tokens have been sold or transferred after `_startId`
     * @param _editionId the ID of the edition
     * @param _startId the ID of the token to start checking from
     * @return bool the edition is sold out from the startId pointer
     */
    function editionSoldOutFrom(
        uint256 _editionId,
        uint256 _startId
    ) public view override onlyExistingEdition(_editionId) returns (bool) {
        return _editionSoldOutFrom(_editionId, _startId, 0);
    }

    /**
     * @notice Edition URI
     * @dev returns the URI for edition metadata - possibly the metadata for the first token if an external resolver is set
     * @param _editionId the ID of the edition
     * @return string the URI for the edition metadata
     */
    function editionURI(
        uint256 _editionId
    )
        public
        view
        override
        onlyExistingEdition(_editionId)
        returns (string memory)
    {
        // Here we are checking only that the edition has a edition level resolver - there may be a overridden token level resolver
        if (
            tokenUriResolverActive() &&
            tokenUriResolver.isDefined(_editionId, 0)
        ) {
            return tokenUriResolver.tokenURI(_editionId, 0);
        }

        return _editions[_editionId].uri;
    }

    /**
     * @notice Is Edition Open?
     * @dev returns whether or not an edition has tokens available to be minted
     * @param _editionId the ID of the edition check
     * @return bool is the edition open
     */
    function isOpenEdition(uint256 _editionId) public view returns (bool) {
        return editionMintedCount(_editionId) < editionSize(_editionId);
    }

    // * Tokens * //

    /**
     * @notice Check the Existence of a Token
     * @dev returns whether or not a token exists with ID `_tokenID`
     * @param _tokenId the ID of the token
     * @return bool the token exists
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return address The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        uint256 editionId = _tokenEditionId(_tokenId);
        address owner = _ownerOf(_tokenId, editionId);
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    /**
     * @notice Creator of the Works of an Edition Token
     * @dev returns the creator associated with the works of an edition
     * @param _tokenId the ID of the token in an edition
     * @return address the address of the creator
     */
    function tokenEditionCreator(
        uint256 _tokenId
    ) public view override onlyExistingToken(_tokenId) returns (address) {
        return editionCreator(_tokenEditionId(_tokenId));
    }

    /**
     * @notice Get Edition Details for a Token
     * @dev returns the full edition details for a token
     * @param _tokenId the ID of a token in an edition
     * @return EditionDetails the full set of properties for the edition
     */
    function tokenEditionDetails(
        uint256 _tokenId
    )
        public
        view
        override
        onlyExistingToken(_tokenId)
        returns (EditionDetails memory)
    {
        return editionDetails(_tokenEditionId(_tokenId));
    }

    /**
     * @notice Get the Edition ID of a Token
     * @dev returns the ID of the edition the token belongs to
     * @param _tokenId the ID of a token in an edition
     * @return uint256 the ID of the edition the token belongs to
     */
    function tokenEditionId(
        uint256 _tokenId
    ) public view override onlyExistingToken(_tokenId) returns (uint256) {
        return _tokenEditionId(_tokenId);
    }

    /**
     * @notice Get the Size of an Edition for a Token
     * @dev returns the size of the edition the token belongs to, see {editionSize}
     * @param _tokenId the ID of a token in an edition
     * @return uint256 the size of the edition the token belongs to
     */
    function tokenEditionSize(
        uint256 _tokenId
    ) public view override onlyExistingToken(_tokenId) returns (uint256) {
        return editionSize(_tokenEditionId(_tokenId));
    }

    /**
     * @notice Get the URI of the Metadata for a Token
     * @dev returns the URI of the token metadata or the metadata for the edition the token belongs to if an external resolver is not set
     * @param _tokenId the ID of a token in an edition
     * @return string the URI of the token or edition metadata
     */
    function tokenURI(
        uint256 _tokenId
    ) public view onlyExistingToken(_tokenId) returns (string memory) {
        uint256 editionId = _tokenEditionId(_tokenId);

        if (
            tokenUriResolverActive() &&
            tokenUriResolver.isDefined(editionId, _tokenId)
        ) {
            return tokenUriResolver.tokenURI(editionId, _tokenId);
        }

        return _editions[editionId].uri;
    }

    /**
     * @notice Token URI Resolver Active
     * @dev return whether or not an external URI resolver has been set
     * @return bool is a token URI resolver set
     */
    function tokenUriResolverActive() public view override returns (bool) {
        return address(tokenUriResolver) != address(0);
    }

    // ********* //
    // * OWNER * //
    // ********* //

    /**
     * @notice Enable/Disable Edition Sales
     * @dev allows the owner of the contract to enable/disable primary sales of an edition
     * @param _editionId the ID of the edition to enable/disable primary sales of
     *
     * Emits {EditionSalesDisabledUpdated}
     */
    function toggleEditionSalesDisabled(
        uint256 _editionId
    ) public override onlyEditionOwner(_editionId) {
        bool disabled = !_editionSalesDisabled[_editionId];
        _editionSalesDisabled[_editionId] = disabled;
        emit EditionSalesDisabledUpdated(_editionId, disabled);
    }

    /**
     * @notice Update Edition Creator
     * @dev allows the contact owner to provide edition attribution to another address
     * @param _editionId the ID of the edition to set a creator for
     * @param _creator the address of the creator associated with the works of an edition
     *
     * Emits {EditionCreatorUpdated}
     */
    function updateEditionCreator(
        uint256 _editionId,
        address _creator
    ) public override onlyOwner {
        _updateEditionCreator(_editionId, _creator);
    }

    /**
     * @notice Update Secondary Royalty Percentage for an Edition
     * @dev allows the contract owner to set an edition level override for secondary royalties of a specific edition
     * @param _editionId the ID of the edition
     * @param _percentage the secondary royalty percentage using the same precision as {MODULO}
     *
     * Emits {EditionRoyaltyPercentageUpdated}
     */
    function updateEditionRoyaltyPercentage(
        uint256 _editionId,
        uint256 _percentage
    ) public override onlyEditionOwner(_editionId) {
        if (_percentage > MAX_ROYALTY_PERCENTAGE)
            revert MaxRoyaltyPercentageExceeded();
        _editionRoyaltyPercentage[_editionId] = _percentage;
        emit EditionRoyaltyPercentageUpdated(_editionId, _percentage);
    }

    /**
     * @notice Update Token URI Resolver
     * @dev allows the contract owner to update the token URI resolver for editions and tokens
     * @param _tokenUriResolver address of the token URI resolver contract
     *
     * Emits {TokenURIResolverUpdated}
     */
    function updateTokenURIResolver(
        ITokenUriResolver _tokenUriResolver
    ) public override onlyOwner {
        tokenUriResolver = _tokenUriResolver;
        emit TokenURIResolverUpdated(address(_tokenUriResolver));
    }

    // ************ //
    // * INTERNAL * //
    // ************ //

    // * Editions * //

    /**
     * @dev internal function for creating editions
     *
     * Requirements:
     *
     * - the parent contract should implement logic to decide who can use this
     * - `_editionSize` must not be 0 or greater than {Konstants-MAX_EDITION_SIZE}
     * - `_mintQuantity` must not be greater than `_editionSize`
     * - `_recipient` must not be `address(0)` if `mintQuantity` is greater than 0
     *
     * @param _editionSize the maximum number of tokens that can be minted in the edition
     * @param _mintQuantity the number of tokens to mint immediately
     * @param _recipient the address to transfer any minted tokens to
     * @param _creator an optional address to attribute the works of the edition to
     * @param _uri the URI for the edition metadata
     * @return uint256 the ID of the new edition that is created
     *
     * Emits {EditionCreated}
     * Emits {EditionCreatorUpdated} if a `_creator` is not `address(0)`
     * Emits {Transfer} for any tokens that are minted
     */
    function _createEdition(
        uint32 _editionSize,
        uint256 _mintQuantity,
        address _recipient,
        address _creator,
        string calldata _uri
    ) internal virtual returns (uint256) {
        if (_editionSize == 0 || _editionSize > MAX_EDITION_SIZE)
            revert InvalidEditionSize();
        if (_mintQuantity > _editionSize) revert InvalidMintQuantity();
        if (_recipient == address(0)) revert InvalidRecipient();

        // configure start token ID
        uint256 editionId = nextEditionId;
        bool isOpen = _mintQuantity < _editionSize;

        unchecked {
            nextEditionId += MAX_EDITION_SIZE;
        }

        _editions[editionId] = Edition(_editionSize, isOpen, _uri);

        emit EditionCreated(editionId);

        if (_creator != address(0)) {
            _updateEditionCreator(editionId, _creator);
        }

        if (_mintQuantity > 0) {
            if (isOpen) _editionMintedCount[editionId] = _mintQuantity;
            _mintConsecutive(_recipient, _mintQuantity, editionId);
        }

        return editionId;
    }

    /**
     * @dev calculates if an edition exists
     * - edition size is used to calculate the existence of an edition
     * - an existing edition can't have its size set to 0
     *
     * @param _editionId the ID of the edition
     * @return bool the edition exists
     */
    function _editionExists(uint256 _editionId) internal view returns (bool) {
        return editionSize(_editionId) > 0;
    }

    /**
     * @dev calculates the maximum token ID for an edition based on the edition's ID and size
     * @param _editionId the ID of the edition
     * @return uint256 the maximum token ID that can be minted for the edition
     */
    function _editionMaxTokenId(
        uint256 _editionId
    ) internal view returns (uint256) {
        return _editionId + editionSize(_editionId) - 1;
    }

    /**
     * @dev calculates whether the primary market of an an edition is exhausted
     * @param _editionId the ID of the edition
     * @return bool primary sales of the edition no longer possible
     */
    function _editionSoldOut(
        uint256 _editionId
    ) internal view virtual returns (bool) {
        // isOpenEdition returns true if NOT ALL tokens in an edition have been minted, so sold out should always be false
        if (isOpenEdition(_editionId)) {
            return false;
        }

        // even for editions initially created as open,
        // we should check each token for an owner once all tokens have been minted
        // since they may have been minted by the owner to sell
        unchecked {
            for (
                uint256 tokenId = _editionId;
                tokenId <= _editionMaxTokenId(_editionId);
                tokenId++
            ) {
                if (_owners[tokenId] == address(0)) return false;
            }
        }

        return true;
    }

    /**
     * @dev calculates whether the primary market of an an edition is exhausted in a range
     * @param _editionId the ID of the edition
     * @param _startId the tokenId to start checking from
     * @param _quantity the number of tokens to check - to check a smaller range
     * @return bool primary sales of the edition no longer possible
     */
    function _editionSoldOutFrom(
        uint256 _editionId,
        uint256 _startId,
        uint256 _quantity
    ) internal view virtual returns (bool) {
        if (_startId < _editionId) revert InvalidRange();

        uint256 maxTokenId = _editionMaxTokenId(_editionId);
        if (_startId > maxTokenId) revert InvalidRange();

        // if quantity 0, check all the way to the end of the edition
        uint256 finishId = _quantity == 0
            ? maxTokenId
            : _startId + _quantity - 1;

        // don't check beyond maxTokenId
        if (finishId > maxTokenId) finishId = maxTokenId;

        unchecked {
            for (uint256 tokenId = _startId; tokenId <= finishId; tokenId++) {
                if (_owners[tokenId] == address(0)) return false;
            }
        }

        return true;
    }

    /**
     * @dev minting of multiple tokens of open edition `_editionId` to the edition owner
     * @dev optimised by not storing token ownership address which is accounted for in _ownerOf()
     *
     * Requirements:
     *
     * - only valid for open editions
     * - mints must not exceed the edition size
     *
     * @param _editionId the edition that the token is a member of
     * @param _quantity the number of tokens to mint
     */
    function _mintMultipleOpenEditionToOwner(
        uint256 _editionId,
        uint256 _quantity
    ) internal virtual {
        if (!_editions[_editionId].isOpenEdition)
            revert BatchOrUnknownEdition();
        address _owner = editionOwner(_editionId);

        unchecked {
            uint256 mintedCount = _editionMintedCount[_editionId];
            if (mintedCount + _quantity > editionSize(_editionId))
                revert EditionSizeExceeded();

            _editionMintedCount[_editionId] += _quantity;
            _balances[_owner] += _quantity; // unlikely to exceed 2 ^ 256 - 1

            uint256 firstTokenId = _editionId + mintedCount;
            for (uint256 i = 0; i < _quantity; i++) {
                _mintTransferToOwner(_owner, firstTokenId + i);
            }
        }
    }

    /**
     * @dev mints a single token of open edition `_editionId` to `_recipient`
     *
     * Requirements:
     *
     * - recipient is not the zero address
     * - only valid for open editions
     * - mints must not exceed the edition size
     *
     * @param _recipient the address to transfer the minted token to
     * @param _editionId the edition that the token is a member of
     * @return uint256 the minted token ID
     */
    function _mintSingleOpenEditionTo(
        uint256 _editionId,
        address _recipient
    ) internal virtual returns (uint256) {
        if (_recipient == address(0)) revert InvalidRecipient();
        _onlyOpenEdition(_editionId);

        unchecked {
            uint256 mintedCount = _editionMintedCount[_editionId];

            // Get next token ID for sale
            uint256 tokenId = _editionId + mintedCount;

            _editionMintedCount[_editionId] += 1;

            _mintSingle(_recipient, tokenId);
            return tokenId;
        }
    }

    /**
     * @dev sets the address of the creator of works associated with an edition
     * @param _editionId the ID of the edition
     * @param _creator the address of the creator
     *
     * Emits {EditionCreatorUpdated}
     */
    function _updateEditionCreator(
        uint256 _editionId,
        address _creator
    ) internal virtual {
        _editionCreator[_editionId] = _creator;
        emit EditionCreatorUpdated(_editionId, _creator);
    }

    // * Tokens * //

    /**
     * @dev Approve `_approved` to operate on `_tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address _owner,
        address _approved,
        uint256 _tokenId
    ) internal virtual {
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(_owner, _approved, _tokenId);
    }

    /// @dev Hook that is called before any token transfer. This includes minting and burning
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    /// @dev Hook that is called after any token transfer. This includes minting and burning
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}

    /**
     * @dev returns the existence of a token by checking for an owner
     * @param _tokenId the token ID to check
     * @return bool the token exists
     */
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _ownerOf(_tokenId, _tokenEditionId(_tokenId)) != address(0);
    }

    /**
     * @dev returns the address of the owner of a token
     * - Newly created editions and its tokens minted to a creator don't have the owner set until the token is sold on the primary market
     * - Therefore, if internally an edition exists and owner of token is zero address, then creator still owns the token
     * - Otherwise, the token owner is returned or the zero address if the token does not exist
     *
     * @param _tokenId the ID of the token to check
     * @param _editionId the ID of the edition the token belongs to
     * @return address the address of the token owner
     */
    function _ownerOf(
        uint256 _tokenId,
        uint256 _editionId
    ) internal view virtual returns (address) {
        // If an owner assigned
        address _owner = _owners[_tokenId];
        if (_owner != address(0)) {
            return _owner;
        }

        address _editionOwner = editionOwner(_editionId);

        if (_editionOwner != address(0)) {
            // if not open edition, return owner
            if (!_editions[_editionId].isOpenEdition) {
                return _editionOwner;
            }

            // if open edition, return owner below minted count, return 0 above minted count
            if (_tokenId < _editionId + _editionMintedCount[_editionId]) {
                return _editionOwner;
            }
        }

        return address(0);
    }

    /**
     * @dev calculates the edition ID using the token ID given and MAX_EDITION_SIZE
     * @param _tokenId the ID of the token to get edition ID for
     * @return uint256 the ID of the edition the token is from
     */
    function _tokenEditionId(uint256 _tokenId) internal pure returns (uint256) {
        return (_tokenId / MAX_EDITION_SIZE) * MAX_EDITION_SIZE;
    }

    // * Contract Ownership * //

    /// @dev override {Ownable-_transferOwnership} to record the old owner as the current edition owner if not already recorded
    function _transferOwnership(address _newOwner) internal virtual override {
        // record the edition owner of the most recent edition
        if (nextEditionId > MAX_EDITION_SIZE) {
            _recordLatestEditionOwnership(owner());
        }

        super._transferOwnership(_newOwner);
    }

    // * Validators * //

    function _onlyEditionOwner(uint256 _editionId) internal view {
        if (msg.sender == editionOwner(_editionId)) return;
        revert NotAuthorised();
    }

    /// @dev reverts if the edition does not exist
    function _onlyExistingEdition(uint256 _editionId) internal view {
        if (!_editionExists(_editionId)) revert EditionDoesNotExist();
    }

    /// @dev reverts if the token does not exist
    function _onlyExistingToken(uint256 _tokenId) internal view {
        if (!_exists(_tokenId)) revert TokenDoesNotExist();
    }

    /// @dev reverts if the edition is not open
    function _onlyOpenEdition(uint256 _editionId) internal view {
        if (!isOpenEdition(_editionId)) revert BatchOrUnknownEdition();
    }

    /// @dev reverts if the edition is not valid
    function _validateEdition(uint256 _editionId) internal view virtual {
        _onlyExistingEdition(_editionId);
    }

    // *********** //
    // * PRIVATE * //
    // *********** //

    // * Edition Ownership * //

    /**
     * @dev records the editionOwnership of the most recent edition if not already recorded
     *
     * - must only be used when at least one edition has been minted
     */
    function _recordLatestEditionOwnership(address _editionOwner) private {
        uint256 count = _editionOwnerships.length;
        uint256 _editionId = nextEditionId - MAX_EDITION_SIZE;

        if (count == 0) {
            _editionOwnerships.push(
                EditionOwnership(_editionId, _editionOwner)
            );
            return;
        }

        uint256 lastOwnershipId = _editionOwnerships[count - 1].editionId;
        bool ownershipNotRecorded = lastOwnershipId != _editionId;
        if (ownershipNotRecorded) {
            _editionOwnerships.push(
                EditionOwnership(_editionId, _editionOwner)
            );
        }
    }

    // * Minting * //

    /**
     * @dev Mints multiple consecutive tokens starting at and including the first specified ID - must be pre-validated
     * @param _recipient address to mint to
     * @param _quantity the number of tokens to mint
     * @param _firstTokenId the token to start minting from
     */
    function _mintConsecutive(
        address _recipient,
        uint256 _quantity,
        uint256 _firstTokenId
    ) private {
        unchecked {
            _balances[_recipient] += _quantity; // unlikely to exceed 2 ^ 256 - 1

            if (_recipient == owner()) {
                for (uint256 i = 0; i < _quantity; i++) {
                    _mintTransferToOwner(_recipient, _firstTokenId + i);
                }
            } else {
                for (uint256 i = 0; i < _quantity; i++) {
                    _mintTransfer(_recipient, _firstTokenId + i);
                }
            }
        }
    }

    /**
     * @notice Mint a Single Token ID
     * @dev Mint a token with the specified tokenId and update the recipient balance - must be pre-validated
     * @param _recipient address to mint to
     * @param _tokenId id of the token to mint
     */
    function _mintSingle(address _recipient, uint256 _tokenId) private {
        unchecked {
            _balances[_recipient] += 1; // unlikely to exceed 2 ^ 256 - 1
            _mintTransfer(_recipient, _tokenId);
        }
    }

    /**
     * @notice Mint Transfer
     * @dev Transfer logic of minting a token - should be pre-validated and update balance in parent function
     * @param _recipient address to mint to
     * @param _tokenId id of the token to mint
     */
    function _mintTransfer(address _recipient, uint256 _tokenId) private {
        _beforeTokenTransfer(address(0), _recipient, _tokenId);
        _owners[_tokenId] = _recipient;
        emit Transfer(address(0), _recipient, _tokenId);
        _afterTokenTransfer(address(0), _recipient, _tokenId);
    }

    /**
     * @notice Mint Transfer To Owner
     * @dev Transfer logic of minting a token to the edition owner - should be pre-validated and update balance in parent function
     *
     * Requirements:
     *
     * - `_owner` must only ever be the owner of the edition the token belongs to
     *
     * @param _owner address of the edition owner
     * @param _tokenId id of the token to mint
     */
    function _mintTransferToOwner(address _owner, uint256 _tokenId) private {
        _beforeTokenTransfer(address(0), _owner, _tokenId);
        emit Transfer(address(0), _owner, _tokenId);
        _afterTokenTransfer(address(0), _owner, _tokenId);
    }

    // * Token Transfers * //

    /// @dev performs a transfer of a token and checks for a correct response if the `_to` is a contract
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private {
        _transferFrom(_from, _to, _tokenId);

        uint256 receiverCodeSize;
        assembly {
            receiverCodeSize := extcodesize(_to)
        }
        if (receiverCodeSize > 0) {
            bytes4 selector = IERC721Receiver(_to).onERC721Received(
                _msgSender(),
                _from,
                _tokenId,
                _data
            );
            require(selector == ERC721_RECEIVED, "Invalid selector");
        }
    }

    /**
     * @dev custom implementation of logic to transfer a token from one address to another
     *
     * Requirements:
     *
     * - `_to` must not be the zero address - we have custom logic which is optimised for minting to the contract owner
     * - the token must have an owner i.e. CAN NOT BE USED FOR MINTING
     * - the msg.sender must be the the current token owner, approved for all, or approved for the specific token
     * - should call before and after transfer hooks
     * - should clear any existing token approval
     * - should adjust the balances of the existing and new token owner
     *
     * Emits {Approval}
     * Emits {Transfer}
     */
    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) private {
        // enforce not being able to send to zero as we have explicit rules what a minted but unbound owner is
        if (_to == address(0)) revert InvalidRecipient();

        // Ensure the owner is the sender
        address owner = _ownerOf(_tokenId, _tokenEditionId(_tokenId));
        if (owner == address(0)) revert TokenDoesNotExist();
        require(_from == owner, "Owner mismatch");

        address spender = _msgSender();
        address approvedAddress = getApproved(_tokenId);
        require(
            spender == owner || // sending to myself
                isApprovedForAll(owner, spender) || // is approved to send any behalf of owner
                approvedAddress == spender, // is approved to move this token ID
            "Invalid spender"
        );

        // do before transfer check
        _beforeTokenTransfer(_from, _to, _tokenId);

        // Ensure approval for token ID is cleared
        _approve(owner, address(0), _tokenId);

        unchecked {
            // Modify balances
            _balances[_from] -= 1;
            _balances[_to] += 1;
        }
        _owners[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);

        // do after transfer check
        _afterTokenTransfer(_from, _to, _tokenId);
    }
}