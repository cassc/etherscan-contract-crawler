// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IERC721Receiver.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721]
 * Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is
 * available separately as
 * {ERC721Enumerable}.
 * @dev removed constructor in order to allow name and symbol to be set by
 * facory clones contracts via the `initialize`
 * function instead.
 *      name and symbol should be set in most derived contract's constructor
 * instead
 */
contract ERC721 {
    // array of token owners, accessed in {NinfaERC721-totalSupply}
    address[] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // util to save on gas in various functions
    address internal constant ZERO_ADDRESS = address(0);

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId`
     * token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to
     * manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address _owner) {
        _owner = _owners[tokenId];
        if (_owner == ZERO_ADDRESS) revert();
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);

        require(msg.sender == owner || _operatorApprovals[owner][msg.sender]);

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        _safeTransfer(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first
     * that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever
     * locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in
     * call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be
     * used to e.g.
     * implement alternative mechanisms to perform token transfer, such as
     * signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon
     * a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) private {
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data));
    }

    /**
     * @dev Destroys `tokenId`.
     *      The approval is cleared when the token is burned.
     *      This is an internal function that does not check if the sender is
     * authorized to operate on the token.
     *      Emits a {Transfer} event.
     * @param _tokenId MUST exist.
     */
    function _burn(uint256 _tokenId) internal virtual {
        // Clear approvals
        delete _tokenApprovals[_tokenId];

        delete _owners[_tokenId]; // equivalent to Openzeppelin's
            // `_balances[owner] -= 1`

        emit Transfer(msg.sender, ZERO_ADDRESS, _tokenId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve}
     * or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != ZERO_ADDRESS;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId));
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || _operatorApprovals[owner][spender]);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`. Doesn't support safe
     * transfers while minting, i.e. doesn't call
     * onErc721Received function because when minting the receiver is
     * msg.sender.
     * We don’t need to zero address check because msg.sender is never the
     * zero address.
     * Because the tokenId is always incremented, we don’t need to check if
     * the token exists already.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address _to, uint256 _tokenId) internal {
        _owners.push(_to);

        emit Transfer(ZERO_ADDRESS, _to, _tokenId);
    }

    /**
     * @dev rather than calling the internal `_mint` function which would create
     * a new owner like so
     * `_owners.push(_to)`,
     *      however ownership will be reassigned/overridden with the buyer's
     * address by the time the `lazyMint` function
     * has finished executing
     *      therefore the `transfer` event is emitted in order to signal to
     * DApps that a mint has occurred
     */
    function _mintAndTransfer(address _minter, address _to, uint256 _tokenId, bytes calldata _data) internal {
        if (_to == ZERO_ADDRESS) revert();
        /*----------------------------------------------------------*|
        |*  # MINT                                                  *|
        |*----------------------------------------------------------*/

        emit Transfer(ZERO_ADDRESS, _minter, _tokenId);

        /*----------------------------------------------------------*|
        |*  # SAFE TRANSFER                                         *|
        |*----------------------------------------------------------*/

        _owners.push(_to);

        emit Transfer(_minter, _to, _tokenId);

        require(_checkOnERC721Received(_minter, _to, _tokenId, _data));
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on
     * msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _from);
        if (_to == ZERO_ADDRESS) revert();

        // Clear approvals _from the previous owner
        _approve(ZERO_ADDRESS, _tokenId);

        _owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 _tokenId) private {
        _tokenApprovals[_tokenId] = to;
        emit Approval(ownerOf(_tokenId), to, _tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(address _owner, address _operator, bool _approved) private {
        if (_owner == _operator) revert();
        _operatorApprovals[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a
     * target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param _to target address that will receive the tokens
     * @param _from address representing the previous owner of the given token
     * ID
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    )
        private
        returns (bool)
    {
        if (_to.code.length > 0) {
            return IERC721Receiver(_to).onERC721Received(
                msg.sender, // operator
                _from, // from
                _tokenId,
                _data
            ) == 0x150b7a02;
        }
        // IERC721Receiver.onERC721Received.selector,
        else {
            return true;
        }
    }

    /**
     * @dev WARNING this function SHOULD only be called by frontends due to
     * unbound loop
     * @dev public visibility as it is needed by
     */
    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == ZERO_ADDRESS) revert();
        uint256 count = 0;
        uint256 totalSupply = _owners.length;
        for (uint256 i; i < totalSupply; i++) {
            if (_owner == _owners[i]) count++;
        }
        return count;
    }
}