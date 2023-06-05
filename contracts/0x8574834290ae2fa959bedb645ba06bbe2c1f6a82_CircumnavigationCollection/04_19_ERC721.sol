pragma solidity 0.8.4;

import "../interface/IERC721.sol";
import "../interface/IERC721Receiver.sol";
import "../interface/IERC721Metadata.sol";
import "../util/Context.sol";
import "../util/Strings.sol";
import "../standard/ERC165.sol";
import "./NiftyEntity.sol";

/**
 * @dev Nifty Gateway implementation of Non-Fungible Token Standard.
 */
contract ERC721 is NiftyEntity, Context, ERC165, IERC721, IERC721Metadata {

    // Tracked individual instance spawned by {BuilderShop} contract. 
    uint immutable public _id;

    // Number of distinct NFTs housed in this contract. 
    uint immutable public _typeCount;

    // Intial receiver of all newly minted NFTs.
    address immutable public _defaultOwner;

    // Component(s) of 'tokenId' calculation. 
    uint immutable public topLevelMultiplier;
    uint immutable public midLevelMultiplier;

    // Token name.
    string private _name;

    // Token symbol.
    string private _symbol;

    // Token artifact location.
    string private _baseURI;

    // Mapping from Nifty type to name of token.
    mapping(uint256 => string) private _niftyTypeName;

    // Mapping from Nifty type to IPFS hash of canonical artifcat file.
    mapping(uint256 => string) private _niftyTypeIPFSHashes;

    // Mapping from token ID to owner address.
    mapping (uint256 => address) internal _owners;

    // Mapping owner address to token count, by aggregating all _typeCount NFTs in the contact.
    mapping (address => uint256) internal _balances;

    // Mapping from token ID to approved address.
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals.
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the token collection.
     *
     * @param name_ Of the collection being deployed.
     * @param symbol_ Shorthand token identifier, for wallets, etc.
     * @param id_ Number instance deployed by {BuilderShop} contract.
     * @param baseURI_ The location where the artifact assets are stored.
     * @param typeCount_ The number of different Nifty types (different 
     * individual NFTs) associated with the deployed collection.
     * @param defaultOwner_ Intial receiver of all newly minted NFTs.
     * @param niftyRegistryContract Points to the repository of authenticated
     * addresses for stateful operations. 
     */
    constructor(string memory name_, 
                string memory symbol_,
                uint256 id_,
                string memory baseURI_,
                uint256 typeCount_,
                address defaultOwner_, 
                address niftyRegistryContract) NiftyEntity(niftyRegistryContract) {
        _name = name_;
        _symbol = symbol_;
        _id = id_;
        _baseURI = baseURI_;
        _typeCount = typeCount_;
        _defaultOwner = defaultOwner_;

        midLevelMultiplier = 100000;
        topLevelMultiplier = id_ * 1000000000;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the link to artificat location for a given token by 'tokenId'.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query.
     * @return The location where the artifact assets are stored.
     */
    function tokenURI(uint256 tokenId) external virtual view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory tokenIdStr = Strings.toString(tokenId);
        return string(abi.encodePacked(_baseURI, tokenIdStr));
    }

    /**
     * @dev Returns an IPFS hash for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query.
     * @return IPFS hash for this (_typeCount) NFT. 
     */
    function tokenIPFSHash(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: IPFS hash query for nonexistent token");
        uint256 niftyType = _getNiftyTypeId(tokenId);
        return _niftyTypeIPFSHashes[niftyType];
    }
    
    /**
     * @dev Determine which NFT in the contract (_typeCount) is associated 
     * with this 'tokenId'.
     */
    function _getNiftyTypeId(uint256 tokenId) internal view returns (uint256) {
        if(tokenId <= topLevelMultiplier) {
            return 0;
        } else {
            return (tokenId - topLevelMultiplier) / midLevelMultiplier;
        }        
    }

    /**
     * @dev Returns the Name for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenName(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Name query for nonexistent token");
        uint256 niftyType = _getNiftyTypeId(tokenId);
        return _niftyTypeName[niftyType];
    }
   
    /**
     * @dev Internal function to set the token IPFS hash for a nifty type.
     * @param niftyType uint256 ID component of the token to set its IPFS hash
     * @param ipfs_hash string IPFS link to assign
     */
    function _setTokenIPFSHashNiftyType(uint256 niftyType, string memory ipfs_hash) internal {
        require(bytes(_niftyTypeIPFSHashes[niftyType]).length == 0, "ERC721Metadata: IPFS hash already set");
        _niftyTypeIPFSHashes[niftyType] = ipfs_hash;
    }

    /**
     * @dev Internal function to set the name for a nifty type.
     * @param niftyType uint256 of nifty type name to be set
     * @param nifty_type_name name of nifty type
     */
    function _setNiftyTypeName(uint256 niftyType, string memory nifty_type_name) internal {
        _niftyTypeName[niftyType] = nifty_type_name;
    }

    /**
     * @dev Base URI for computing {tokenURI}.
     */
    function _setBaseURI(string memory baseURI_) internal {
        _baseURI = baseURI_;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}