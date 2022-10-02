// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../extensions/AccessControl.sol";
import "../extensions/ERC721Mintable.sol";
import "../extensions/PublicMintable.sol";
import "../extensions/AirDropable.sol";
import "./IERC721LA.sol";
import "../extensions/Pausable.sol";
import "../extensions/LAInitializable.sol";
import "../libraries/LANFTUtils.sol";
import "../libraries/BPS.sol";
import "../libraries/CustomErrors.sol";
import "./IERC721LA.sol";
import "./IERC721Events.sol";
import "../platform/royalties/RoyaltiesState.sol";
import "./ERC721State.sol";

/**
 * @notice LiveArt ERC721 implementation contract
 * Supports multiple edtioned NFTs and gas optimized batch minting
 */
contract ERC721LA is
    AccessControl,
    ERC721Mintable,
    IERC721LA,
    LAInitializable,
    AirDropable,
    Pausable,
    PublicMintable
{
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               LIBRARIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    using BitMaps for BitMaps.BitMap;
    using ERC721State for ERC721State.ERC721LAState;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    bytes32 public constant IERC721METADATA_INTERFACE = hex"5b5e139f";
    bytes32 public constant IERC721_INTERFACE = hex"80ac58cd";
    bytes32 public constant IERC2981_INTERFACE = hex"2a55205a";
    bytes32 public constant IERC165_INTERFACE = hex"01ffc9a7";

    // Used for separating editionId and tokenNumber from the tokenId (cf. createEdition)
    uint24 public constant DEFAULT_EDITION_TOKEN_MULTIPLIER = 10e5;
    address private constant burnAddress = address(0xDEAD);

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               INITIALIZERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
     * @dev Initialize function. Should be called by the factory when deploying new instances.
     * @param _collectionAdmin is the address of the default admin for this contract
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _collectionAdmin,
        address _royaltyRegistry
    ) external notInitialized {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._name = _name;
        state._symbol = _symbol;
        state._royaltyRegistry = IRoyaltiesRegistry(_royaltyRegistry);
        state._editionCounter = 1;
        state._edition_max_tokens = DEFAULT_EDITION_TOKEN_MULTIPLIER;
        _grantRole(COLLECTION_ADMIN_ROLE, _collectionAdmin);
        _grantRole(DEPLOYER_ROLE, _collectionAdmin);
    }

    /**
     * @dev Overload `initialize` function with `_edition_max_tokens` argument
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _collectionAdmin,
        address _royaltyRegistry,
        uint24 _edition_max_tokens
    ) external notInitialized {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._name = _name;
        state._symbol = _symbol;
        state._royaltyRegistry = IRoyaltiesRegistry(_royaltyRegistry);
        state._editionCounter = 1;
        state._edition_max_tokens = _edition_max_tokens;
        _grantRole(COLLECTION_ADMIN_ROLE, _collectionAdmin);
        _grantRole(DEPLOYER_ROLE, _collectionAdmin);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == IERC2981_INTERFACE ||
            interfaceId == IERC721_INTERFACE ||
            interfaceId == IERC721METADATA_INTERFACE ||
            interfaceId == IERC165_INTERFACE;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                           IERC721Metadata
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function name() external view override returns (string memory) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._name;
    }

    function symbol() external view override returns (string memory) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._symbol;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert CustomErrors.TokenNotFound();
        }

        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        (uint256 editionId, ) = parseEditionFromTokenId(tokenId);
        return state._editions[editionId].baseURI;
    }

    function totalSupply() external view override returns (uint256) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        uint256 _count;
        for (uint256 i = 1; i < state._editionCounter; i += 1) {
            _count += editionMintedTokens(i);
        }
        return _count;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               EDITIONS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
     * @notice Backward compatibility with the frontend
     */
    function EDITION_TOKEN_MULTIPLIER() public view returns (uint24) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._edition_max_tokens;
    }

    function EDITION_MAX_SIZE() public view returns (uint24) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._edition_max_tokens - 1;
    }

    /**
     * @notice Creates a new Edition
     * Editions can be seen as collections within a collection.
     * The token Ids for the a given edition have the following format:
     * `[editionId][tokenNumber]`
     * eg.: The Id of the 2nd token of the 5th edition is: `5000002`
     *
     */
    function createEdition(
        string calldata _baseURI,
        uint24 _maxSupply,
        address _creator,
        uint24 _contractMintPriceInFinney
    ) public onlyMinter returns (uint256) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        if (_maxSupply >= state._edition_max_tokens - 1) {
            revert CustomErrors.MaxSupplyError();
        }

        state._editions[state._editionCounter] = ERC721State.Edition({
            baseURI: _baseURI,
            maxSupply: _maxSupply,
            createdBy: _creator,
            burnedSupply: 0,
            currentSupply: 0,
            contractMintPriceInFinney: _contractMintPriceInFinney
        });

        emit EditionCreated(
            address(this),
            _creator,
            state._editionCounter,
            _maxSupply,
            _baseURI,
            _contractMintPriceInFinney
        );

        state._editionCounter += 1;

        // -1 because we return the current edition Id
        return state._editionCounter - 1;
    }

    /**
     * @notice Creates a new Edition then mint all tokens from that edition
     */
    function createAndMintEdition(
        string calldata _baseURI,
        uint24 _maxSupply,
        address _creator
    ) external onlyMinter {
        uint256 editionId = createEdition(_baseURI, _maxSupply, _creator, 0);
        mintEditionTokens(editionId, _maxSupply, _creator);
    }

    /**
     * @notice Creates a new Edition then mint all tokens from that edition
     */
    function lazyMintEdition(
        string calldata _baseURI,
        uint24 _maxSupply,
        address _creator
    ) external onlyMinter {
        uint256 editionId = createEdition(_baseURI, _maxSupply, _creator, 0);
        _silentMint(editionId, _maxSupply, _creator);
    }

    /**
     * @notice updates an edition
     */
    function updateEdition(uint256 editionId, string calldata _baseURI)
        external
        onlyAdmin
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        if (editionId > state._editionCounter) {
            revert CustomErrors.InvalidEditionId();
        }

        ERC721State.Edition storage edition = state._editions[editionId];

        edition.baseURI = _baseURI;
        emit EditionUpdated(
            address(this),
            editionId,
            edition.maxSupply,
            _baseURI
        );
    }

    /**
     * @notice fetch edition struct data by editionId
     */
    function getEdition(uint256 _editionId)
        public
        view
        override
        returns (ERC721State.Edition memory)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        if (_editionId > state._editionCounter) {
            revert CustomErrors.InvalidEditionId();
        }
        return state._editions[_editionId];
    }

    /**
     * @notice Returns the total number of editions
     */
    function totalEditions() external view returns (uint256 total) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        total = state._editionCounter - 1;
    }

    /**
     * @notice Returns the current supply of a given edition
     */
    function editionMintedTokens(uint256 editionId)
        public
        view
        returns (uint256 supply)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        ERC721State.Edition memory edition = state._editions[editionId];
        return edition.currentSupply - edition.burnedSupply;
    }

    /**
     * @dev Given an editionId and  tokenNumber, returns tokenId in the following format:
     * `[editionId][tokenNumber]` where `tokenNumber` is between 1 and state._edition_max_tokens  - 1
     * eg.: The second token from the 5th edition would be `500002`
     *
     */
    function editionedTokenId(uint256 editionId, uint256 tokenNumber)
        public
        view
        override
        returns (uint256 tokenId)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        uint256 paddedEditionID = editionId * state._edition_max_tokens;
        tokenId = paddedEditionID + tokenNumber;
    }

    /**
     * @dev Given a tokenId return editionId and tokenNumber.
     * eg.: 3000005 => editionId 3 and tokenNumber 5
     */
    function parseEditionFromTokenId(uint256 tokenId)
        public
        view
        returns (uint256 editionId, uint256 tokenNumber)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        // Divide first to lose the decimal. ie. 1000001 / 1000000 = 1
        editionId = tokenId / state._edition_max_tokens;
        tokenNumber = tokenId - (editionId * state._edition_max_tokens);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               MINTING
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
     * This emulate a mint event and by transfering a token from edition creator
     * and emitting an event from address(0) to receiver address.
     * This is a system function, that should only be called once per token.
     */
    function lazyMintTransfer(address to, uint256 tokenId) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert CustomErrors.NotAllowed();
        }

        address owner = ownerOf(tokenId);
        _transferCore(owner, to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    function mintEditionTokens(
        uint256 _editionId,
        uint24 _quantity,
        address _recipient
    ) public onlyMinter {
        _safeMint(_editionId, _quantity, _recipient);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               BURNABLE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) public override {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        address owner = ownerOf(tokenId);

        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert CustomErrors.TransferError();
        }
        _transferCore(owner, burnAddress, tokenId);

        // Looksrare and other marketplace require the owner to be null address
        emit Transfer(owner, address(0), tokenId);
        (uint256 editionId, ) = parseEditionFromTokenId(tokenId);

        // Update the number of tokens burned for this edition
        state._editions[editionId].burnedSupply += 1;
    }

    function isBurned(uint256 tokenId) public view override returns (bool) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        address owner = state._owners[tokenId];
        return owner == burnAddress;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               PAUSABLE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function pauseContract() public onlyAdmin {
        _pause();
    }

    function unpauseContract() public onlyAdmin {
        _unpause();
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                                   ERC721
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev See {IERC721-approve}.
    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        if (
            msg.sender == to ||
            (msg.sender != owner && !isApprovedForAll(owner, msg.sender))
        ) {
            revert CustomErrors.NotAllowed();
        }

        _approve(to, tokenId);
    }

    /// @dev See {IERC721-transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert CustomErrors.TransferError();
        }

        _transfer(from, to, tokenId);
    }

    /// @dev See {IERC721-ownerOf}.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        (address owner, ) = _ownerAndBatchHeadOf(tokenId);
        return owner;
    }

    /// @dev Returns the number of tokens in ``owner``'s account.
    function balanceOf(address owner)
        external
        view
        returns (uint256 tokenBalance)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        tokenBalance = state._balances[owner];
    }

    /// @dev See {IERC721-getApproved}.
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        if (!_exists(tokenId)) {
            revert CustomErrors.TokenNotFound();
        }
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._tokenApprovals[tokenId];
    }

    /// @dev See {IERC721-isApprovedForAll}.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._operatorApprovals[owner][operator];
    }

    /// @dev See {IERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved)
        external
        override
    {
        if (operator == msg.sender) {
            revert CustomErrors.NotAllowed();
        }

        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert CustomErrors.NotAllowed();
        }
        _safeTransfer(from, to, tokenId, _data);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                            Royalties
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function setRoyaltyRegistryAddress(address _royaltyRegistry)
        public
        onlyAdmin
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        state._royaltyRegistry = IRoyaltiesRegistry(_royaltyRegistry);
    }

    function royaltyRegistryAddress() public view returns (IRoyaltiesRegistry) {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        return state._royaltyRegistry;
    }

    /// @dev see: EIP-2981
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return
            state._royaltyRegistry.royaltyInfo(address(this), _tokenId, _value);
    }

    /// @dev Supports: Manifold, ArtBlocks
    function getRoyalties(uint256 _tokenId)
        public
        view
        returns (address payable[] memory, uint256[] memory)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return state._royaltyRegistry.getRoyalties(address(this), _tokenId);
    }

    /// @dev Supports:Foundation
    function getFees(uint256 _tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return state._royaltyRegistry.getFees(address(this), _tokenId);
    }

    /// @dev Rarible: RoyaltiesV1
    function getFeeRecipients(uint256 _tokenId)
        external
        view
        returns (address payable[] memory)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return state._royaltyRegistry.getFeeRecipients(address(this), _tokenId);
    }

    /// @dev Rarible: RoyaltiesV1
    function getFeeBps(uint256 _tokenId)
        external
        view
        returns (uint256[] memory)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return state._royaltyRegistry.getFeeBps(address(this), _tokenId);
    }

    /// @dev Rarible: RoyaltiesV2
    function getRaribleV2Royalties(uint256 _tokenId)
        external
        view
        returns (IRaribleV2.Part[] memory)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return
            state._royaltyRegistry.getRaribleV2Royalties(
                address(this),
                _tokenId
            );
    }

    /// @dev CreatorCore - Support for KODA
    function getKODAV2RoyaltyInfo(uint256 _tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return
            state._royaltyRegistry.getKODAV2RoyaltyInfo(
                address(this),
                _tokenId
            );
    }

    /// @dev CreatorCore - Support for Zora
    function convertBidShares(uint256 _tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return state._royaltyRegistry.convertBidShares(address(this), _tokenId);
    }

    function registerCollectionRoyaltyReceivers(
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        IRoyaltiesRegistry(state._royaltyRegistry)
            .registerCollectionRoyaltyReceivers(
                address(this),
                msg.sender,
                royaltyReceivers
            );
    }

    function registerEditionRoyaltyReceivers(
        uint256 tokenId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        IRoyaltiesRegistry(state._royaltyRegistry)
            .registerEditionRoyaltyReceivers(
                address(this),
                msg.sender,
                tokenId,
                royaltyReceivers
            );
    }

    function registerTokenRoyaltyReceivers(
        uint256 tokenId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        IRoyaltiesRegistry(state._royaltyRegistry)
            .registerTokenRoyaltyReceivers(
                address(this),
                msg.sender,
                tokenId,
                royaltyReceivers
            );
    }

    function primaryRoyaltyInfo(uint256 tokenId)
        public
        view
        returns (address payable[] memory, uint256[] memory)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        return
            IRoyaltiesRegistry(state._royaltyRegistry).primaryRoyaltyInfo(
                address(this),
                msg.sender,
                tokenId
            );
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                         INTERNAL / PUBLIC HELPERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev Returns whether `tokenId` exists.
    function _exists(uint256 tokenId) internal view returns (bool) {
        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            tokenId
        );

        if (isBurned(tokenId)) {
            return false;
        }

        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        ERC721State.Edition memory edition = state._editions[editionId];
        return tokenNumber <= edition.currentSupply;
    }

    /**
     * @dev Returns the index of the batch for a given token.
     * If the token was not bought in a batch tokenId == tokenIdBatchHead
     */
    function _getBatchHead(uint256 tokenId)
        internal
        view
        returns (uint256 tokenIdBatchHead)
    {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        (uint256 editionId, ) = parseEditionFromTokenId(tokenId);
        tokenIdBatchHead = state._batchHead.scanForward(
            tokenId,
            editionId * state._edition_max_tokens
        );
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();

        state._tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Returns the index of the batch for a given token.
     * and the batch owner address
     */
    function _ownerAndBatchHeadOf(uint256 tokenId)
        internal
        view
        returns (address owner, uint256 tokenIdBatchHead)
    {
        if (!_exists(tokenId)) {
            revert CustomErrors.TokenNotFound();
        }

        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        tokenIdBatchHead = _getBatchHead(tokenId);
        owner = state._owners[tokenIdBatchHead];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        if (!_exists(tokenId)) {
            revert CustomErrors.TokenNotFound();
        }

        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     * Internal function intened to split the logic for different transfer use cases
     * Emits a {Transfer} event.
     */
    function _transferCore(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        ERC721State.ERC721LAState storage state = ERC721State
            ._getERC721LAState();
        (, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(tokenId);

        // We check if the token after the one being transfer
        // belong to the batch, if it does, we have to update it's owner
        // while being careful to not overflow the edition maxSupply
        uint256 nextTokenId = tokenId + 1;
        (uint256 editionId, uint256 nextTokenNumber) = parseEditionFromTokenId(
            nextTokenId
        );
        ERC721State.Edition memory edition = state._editions[editionId];
        if (
            nextTokenNumber <= edition.maxSupply &&
            !state._batchHead.get(nextTokenId)
        ) {
            state._owners[nextTokenId] = from;
            state._batchHead.set(nextTokenId);
        }

        // Finaly we update the owners and balances
        state._owners[tokenId] = to;
        if (tokenId != tokenIdBatchHead) {
            state._batchHead.set(tokenId);
        }

        state._balances[to] += 1;
        state._balances[from] -= 1;
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        _approve(address(0), tokenId);
        emit Transfer(from, to, tokenId);
        _transferCore(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        LANFTUtils._checkOnERC721Received(from, to, tokenId, _data);
    }

    function isCollectionAdmin(address account)
        public
        view
        override
        returns (bool)
    {
        return hasRole(COLLECTION_ADMIN_ROLE, account);
    }

    function isMinter(address account) public view override returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               ETHER
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function balance() public view returns (uint256) {
        return address(this).balance;
    }
}