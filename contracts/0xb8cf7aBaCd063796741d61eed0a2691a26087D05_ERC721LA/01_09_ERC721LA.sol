// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../extensions/AccessControl.sol";
import "../extensions/IRoyaltiesRegistry.sol";
import "./IERC721LA.sol";
import "../libraries/LANFTUtils.sol";
import "../libraries/BitMaps/BitMaps.sol";

contract ERC721LA is IERC721LA, Initializable, AccessControl {
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               LIBRARIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    using BitMaps for BitMaps.BitMap;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    bytes32 public constant IERC721METADATA_INTERFACE = hex"5b5e139f";
    bytes32 public constant IERC721_INTERFACE = hex"80ac58cd";
    bytes32 public constant IERC2981_INTERFACE = hex"2a55205a";
    bytes32 public constant IERC165_INTERFACE = hex"01ffc9a7";

    // Used for separating editionId and tokenNumber from the tokenId (cf. lazyMintEdition)
    uint256 public constant EDITION_TOKEN_MULTIPLIER = 10e5;
    uint256 public constant EDITION_MAX_SIZE = EDITION_TOKEN_MULTIPLIER - 1;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               STORAGE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    struct Edition {
        string baseURI;
        uint256 maxSupply;
    }

    struct ERC721LAState {
        uint64 _editionCounter;
        string _name;
        string _symbol;
        mapping(uint256 => Edition) _editions;
        mapping(uint256 => uint256) _editionSupplies;
        mapping(uint256 => address) _owners;
        mapping(uint256 => address) _tokenApprovals;
        mapping(address => uint256) _balances;
        mapping(address => mapping(address => bool)) _operatorApprovals;
        BitMaps.BitMap _batchHead;
        IRoyaltiesRegistry _royaltyRegistry;
    }

    function _getERC721LAState()
        internal
        pure
        returns (ERC721LAState storage state)
    {
        bytes32 position = keccak256("liveart.ERC721LA");
        assembly {
            state.slot := position
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               INITIALIZERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    constructor() {}

    /**
     * @dev Initialize function. Should be called by the factory when deploying new instances.
     * @param _admin is the address of the default admin for this contract
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _admin,
        address _royaltyRegistry
    ) external notInitialized {
        ERC721LAState storage state = _getERC721LAState();
        state._name = _name;
        state._symbol = _symbol;
        state._royaltyRegistry = IRoyaltiesRegistry(_royaltyRegistry);
        state._editionCounter = 1;
        _initializeAccessControl(_admin);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        external
        pure
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
    function name() external view returns (string memory) {
        ERC721LAState storage state = _getERC721LAState();
        return state._name;
    }

    function symbol() external view returns (string memory) {
        ERC721LAState storage state = _getERC721LAState();
        return state._symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        ERC721LAState storage state = _getERC721LAState();
        (uint256 editionId, ) = parseEditionFromTokenId(tokenId);
        return state._editions[editionId].baseURI;
    }

    function totalSupply() external view returns (uint256) {
        ERC721LAState storage state = _getERC721LAState();
        uint256 _count;
        for (uint256 i = 0; i < state._editionCounter; i += 1) {
            _count += state._editionSupplies[i];
        }

        // we substract the number of editions to the total count
        // because editions are initialized with a supply of 1 to save gas
        return _count - state._editionCounter;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               EDITIONS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /**
     * @notice Creates a new Edition
     * Editions can be seen as collections within a collection.
     * The token Ids for the a given edition have the following format:
     * `[editionId][tokenNumber]`
     * eg.: The Id of the 2nd token of the 5th edition is: `5000002`
     *
     */
    function lazyMintEdition(string calldata _baseURI, uint256 _maxSupply)
        public
        onlyMinter
        returns (uint256)
    {
        if (_maxSupply >= EDITION_MAX_SIZE) {
            revert MaxSupplyError();
        }

        ERC721LAState storage state = _getERC721LAState();
        state._editionSupplies[state._editionCounter] = 1; // Set to 1 to save gas on mint (non 0 SSTORE)
        state._editions[state._editionCounter] = Edition({
            baseURI: _baseURI,
            maxSupply: _maxSupply
        });

        emit EditionCreated(
            address(this),
            msg.sender,
            state._editionCounter,
            _maxSupply,
            _baseURI
        );

        state._editionCounter += 1;
        return state._editionCounter - 1;
    }

    /**
     * @notice Creates a new Edition then mint all tokens from that edition
     *
     */
    function createAndMintEdition(
        string calldata _baseURI,
        uint256 _maxSupply,
        address _recipient
    ) external onlyMinter {
        uint256 editionId = lazyMintEdition(_baseURI, _maxSupply);
        mintEditionTokens(editionId, _maxSupply, _recipient);
    }

    function getEdition(uint256 _editionId)
        public
        view
        returns (Edition memory)
    {
        ERC721LAState storage state = _getERC721LAState();
        if (_editionId > state._editionCounter) {
            revert InvalidEditionId();
        }
        return state._editions[_editionId];
    }

    function updateEdition(uint256 editionId, string calldata _baseURI)
        external
        onlyAdmin
    {
        ERC721LAState storage state = _getERC721LAState();
        if (editionId > state._editionCounter) {
            revert InvalidEditionId();
        }

        Edition storage edition = state._editions[editionId];

        edition.baseURI = _baseURI;
        emit EditionUpdated(
            address(this),
            editionId,
            edition.maxSupply,
            _baseURI
        );
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                                   ERC721
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        if (
            msg.sender == to ||
            (msg.sender != owner && !isApprovedForAll(owner, msg.sender))
        ) {
            revert NotAllowed();
        }

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert TransferError();
        }
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        (address owner, ) = _ownerAndBatchHeadOf(tokenId);
        return owner;
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        ERC721LAState storage state = _getERC721LAState();
        balance = state._balances[owner];
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        returns (address)
    {
        if (!_exists(tokenId)) {
            revert TokenNotFound();
        }
        ERC721LAState storage state = _getERC721LAState();
        return state._tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        ERC721LAState storage state = _getERC721LAState();
        return state._operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        external 
        override
    {
        if (operator == msg.sender) {
            revert NotAllowed();
        }

        ERC721LAState storage state = _getERC721LAState();
        state._operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    // /**
    //  * @dev See {IERC721-safeTransferFrom}.
    //  */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotAllowed();
        }
        _safeTransfer(from, to, tokenId, _data);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               MINTING
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function mintEditionTokens(
        uint256 _editionId,
        uint256 _quantity,
        address _recipient
    ) public onlyMinter {
        _safeMint(_editionId, _quantity, _recipient);
    }

    function _safeMint(
        uint256 _editionId,
        uint256 _quantity,
        address _recipient
    ) internal virtual {
        ERC721LAState storage state = _getERC721LAState();
        Edition memory edition = getEdition(_editionId);
        uint256 tokenNumber = state._editionSupplies[_editionId];

        if (_quantity == 0 || _recipient == address(0)) {
            revert InvalidMintData();
        }

        if (tokenNumber > edition.maxSupply) {
            revert MaxSupplyError();
        }

        uint256 firstTokenId = editionedTokenId(_editionId, tokenNumber);

        // -1 is because first tokenNumber start at 1 for gas savings
        if (tokenNumber + _quantity - 1 > edition.maxSupply) {
            revert MaxSupplyError();
        }

        state._editionSupplies[_editionId] += _quantity;
        state._owners[firstTokenId] = _recipient;
        state._batchHead.set(firstTokenId);
        state._balances[_recipient] += _quantity;

        // Emit events
        for (
            uint256 tokenId = firstTokenId;
            tokenId < firstTokenId + _quantity;
            tokenId++
        ) {
            emit Transfer(address(0), _recipient, tokenId);
            _checkOnERC721Received(address(0), _recipient, tokenId, "");
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                            ERC2981 Royalties
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount)
    {
        ERC721LAState storage state = _getERC721LAState();
        return
            state._royaltyRegistry.royaltyInfo(address(this), _tokenId, _value);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                         INTERNAL / PUBLIC HELPERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /**
     * @dev Given an editionId and  tokenNumber, returns tokenId in the following format:
     * `[editionId][tokenNumber]` where `tokenNumber` is between 1 and EDITION_TOKEN_MULTIPLIER - 1
     * eg.: The second token from the 5th edition would be `500002`
     *
     */
    function editionedTokenId(uint256 editionId, uint256 tokenNumber)
        public
        pure
        returns (uint256 tokenId)
    {
        uint256 paddedEditionID = editionId * EDITION_TOKEN_MULTIPLIER;
        tokenId = paddedEditionID + tokenNumber;
    }

    /**
     * @dev Given a tokenId return editionId and tokenNumber.
     * eg.: 3000005 => editionId 3 and tokenNumber 5
     */
    function parseEditionFromTokenId(uint256 tokenId)
        public
        pure
        returns (uint256 editionId, uint256 tokenNumber)
    {
        // Divide first to lose the decimal. ie. 1000001 / 1000000 = 1
        editionId = tokenId / EDITION_TOKEN_MULTIPLIER;
        tokenNumber = tokenId - (editionId * EDITION_TOKEN_MULTIPLIER);
    }

    /**
     * @notice Returns the total number of editions
     */
    function totalEditions() external view returns (uint256 total) {
        ERC721LAState storage state = _getERC721LAState();
        total = state._editionCounter - 1;
    }

    /**
     * @notice Returns the current supply of a given edition
     */
    function editionSupply(uint256 editionId)
        external
        view
        returns (uint256 supply)
    {
        ERC721LAState storage state = _getERC721LAState();
        // -1 because supply start at 1 for gas savings
        supply = state._editionSupplies[editionId] - 1;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            tokenId
        );
        ERC721LAState storage state = _getERC721LAState();
        return tokenNumber < state._editionSupplies[editionId];
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
        ERC721LAState storage state = _getERC721LAState();
        (uint256 editionId, ) = parseEditionFromTokenId(tokenId);
        tokenIdBatchHead = state._batchHead.scanForward(
            tokenId,
            editionId * EDITION_TOKEN_MULTIPLIER
        );
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        ERC721LAState storage state = _getERC721LAState();

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
            revert TokenNotFound();
        }

        ERC721LAState storage state = _getERC721LAState();
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
            revert TokenNotFound();
        }

        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
        ERC721LAState storage state = _getERC721LAState();
        (address owner, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(
            tokenId
        );

        if (owner != from || to == address(0)) {
            revert TransferError();
        }

        _approve(address(0), tokenId);

        uint256 nextTokenId = tokenId + 1;
        if (!state._batchHead.get(nextTokenId)) {
            state._owners[nextTokenId] = from;
            state._batchHead.set(nextTokenId);
        }

        state._owners[tokenId] = to;
        if (tokenId != tokenIdBatchHead) {
            state._batchHead.set(tokenId);
        }

        state._balances[to] += 1;
        state._balances[from] -= 1;
        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, _data);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is an EOA
     *
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (LANFTUtils.isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NotERC721Receiver();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}