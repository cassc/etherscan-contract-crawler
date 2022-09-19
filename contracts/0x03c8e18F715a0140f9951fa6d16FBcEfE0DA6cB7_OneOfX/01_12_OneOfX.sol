// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract OneOfX is Context, ERC165, IERC721, IERC721Metadata, ERC2981, Ownable {
    using Address for address;
    using Strings for uint256;

    string public override name = "1 of X";
    string public override symbol = "1/X";

    // Total number of tokens burned
    uint256 internal _burnCount;

    // Array of all tokens storing the owner's address
    address[] internal _tokens = [address(0x0)];

    // Mapping of all token hashes to their URI
    mapping(uint256 => string) public override tokenURI;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from approved minting addresses
    mapping(address => bool) private _minters;

    // Custom Errors
    error BalanceQueryForZeroAddress();
    error OwnerIndexOutOfBounds();
    error ApprovalToCurrentOwner();
    error OwnerQueryForNonExistentToken();
    error ApproveToCaller();
    error ApprovedQueryForNonExistentToken();
    error TransferCallerIsNotOwnerNorApproved();
    error TransferToNonERC721ReceiverImplementer();
    error ApproveCallerIsNotOwnerNorApprovedForAll();
    error OperatorQueryForNonExistentToken();
    error TransferOfTokenThatIsNotOwn();
    error TransferToTheZeroAddress();
    error MintToTheZeroAddress();
    error SenderNotMinter();

    constructor() {}

    modifier onlyMinters() {
        if (!_minters[_msgSender()]) revert SenderNotMinter();
        _;
    }

    function setMinter(address addr, bool isMinter) public onlyOwner {
        _minters[addr] = isMinter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(Ownable).interfaceId ||
            interfaceId == type(ERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function totalMinted() public view returns (uint256) {
        return _tokens.length - 1;
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted() - _burnCount;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This is implementation is O(n) and should not be
     * called by other contracts.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == owner) {
                if (currentIndex == index) {
                    return i;
                }
                currentIndex += 1;
            }
        }
        revert OwnerIndexOutOfBounds();
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) {
            revert BalanceQueryForZeroAddress();
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _tokens[tokenId];
        if (owner == address(0)) {
            revert OwnerQueryForNonExistentToken();
        }

        return owner;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = OneOfX.ownerOf(tokenId);

        if (to == owner) {
            revert ApprovalToCurrentOwner();
        }

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApproveCallerIsNotOwnerNorApprovedForAll();
        }

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        if (!_exists(tokenId)) {
            revert ApprovedQueryForNonExistentToken();
        }

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        if (operator == _msgSender()) {
            revert ApproveToCaller();
        }

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert TransferCallerIsNotOwnerNorApproved();
        }
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert TransferCallerIsNotOwnerNorApproved();
        }

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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);

        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
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
        return _tokens[tokenId] != address(0);
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
            revert OperatorQueryForNonExistentToken();
        }

        address owner = OneOfX.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeMint(address to, string memory uri) public returns (uint256) {
        return safeMint(to, uri, "");
    }

    /**
     * Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function safeMint(
        address to,
        string memory uri,
        bytes memory _data
    ) public returns (uint256) {
        uint256 tokenId = _mint(to, uri);
        if (
            !_checkOnERC721Received(address(0), to, _tokens.length - 1, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }
        return tokenId;
    }

    /**
     * Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeMintWithRoyalty(
        address to,
        string memory uri,
        address receiver,
        uint96 feeNumerator
    ) public returns (uint256) {
        uint256 tokenId = safeMint(to, uri, "");
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        return tokenId;
    }

    /**
     * Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function safeMintWithRoyalty(
        address to,
        string memory uri,
        address receiver,
        uint96 feeNumerator,
        bytes memory _data
    ) public returns (uint256) {
        uint256 tokenId = _mint(to, uri);
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        if (
            !_checkOnERC721Received(address(0), to, _tokens.length - 1, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }
        return tokenId;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, string memory uri)
        internal
        onlyMinters
        returns (uint256)
    {
        if (to == address(0)) {
            revert MintToTheZeroAddress();
        }

        uint256 tokenId = _tokens.length;
        _balances[to] += 1;
        _tokens.push(to);
        tokenURI[tokenId] = uri;

        emit Transfer(address(0), to, tokenId);

        return tokenId;
    }

    /**
     * Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) public {
        address owner = OneOfX.ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _burnCount++;
        _balances[owner] -= 1;
        _tokens[tokenId] = address(0);

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (OneOfX.ownerOf(tokenId) != from) {
            revert TransferOfTokenThatIsNotOwn();
        }

        if (to == address(0)) {
            revert TransferToTheZeroAddress();
        }

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _tokens[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(OneOfX.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
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