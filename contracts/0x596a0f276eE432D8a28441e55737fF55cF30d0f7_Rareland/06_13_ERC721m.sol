// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721m is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // The tokenId is generated sequentially starting from '0' and increments for each mint.
    uint256 private _currentTokenIdIndex = 0;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            _interfaceId == type(IERC721).interfaceId ||
            _interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address _owner) public view virtual override returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balances[_owner];
    }

    /**
     * @dev Returns the total number of minted NFT.
     */
    function totalSupply() public view returns (uint256) {
        return _currentTokenIdIndex;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 _tokenId) public view virtual override returns (address) {
        address owner = _owners[_tokenId];
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
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address _to, uint256 _tokenId) public virtual override {
        address owner = ERC721m.ownerOf(_tokenId);
        require(_to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(_to, _tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 _tokenId) public view virtual override returns (address) {
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[_tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address _operator, bool _approved) public virtual override {
        _setApprovalForAll(_msgSender(), _operator, _approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Safely transfers `_tokenId` token from `_from` to `_to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `_to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `_from` cannot be the zero address.
     * - `_to` cannot be the zero address.
     * - `_tokenId` token must exist and be owned by `_from`.
     * - If `_to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `_tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        return _owners[_tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view virtual returns (bool) {
        require(_exists(_tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721m.ownerOf(_tokenId);
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

    /**
     * @dev Safely mints `_amount` of NFTs and transfers it to `_to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address _to, uint256 _amount) internal virtual {
        _safeMint(_to, _amount, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address _to,
        uint256 _amount,
        bytes memory _data
    ) internal virtual {
        _mint(_to, _amount, _data);
    }

    /**
     * @dev Mints `_amount` tokens and transfers them to `_to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `_to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address _to, uint256 _amount, bytes memory _data) internal virtual {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(_amount > 0, "Invalid mint amount!");
        

        for (uint256 i = 0; i < _amount; ++i) {
            uint256 tokenId = _currentTokenIdIndex + i;
            
            _beforeTokenTransfer(address(0), _to, tokenId);
            _owners[tokenId] = _to;
            emit Transfer(address(0), _to, tokenId);

            require(
                _checkOnERC721Received(address(0), _to, tokenId, _data),
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }

        _balances[_to] += _amount;
        _currentTokenIdIndex += _amount;
    }

    /**
     * @dev Destroys `_tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `_tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 _tokenId) internal virtual {
        address owner = ERC721m.ownerOf(_tokenId);

        _beforeTokenTransfer(owner, address(0), _tokenId);

        // Clear approvals
        _approve(address(0), _tokenId);

        _balances[owner] -= 1;
        delete _owners[_tokenId];

        emit Transfer(owner, address(0), _tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `_to` cannot be the zero address.
     * - `_tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {
        require(ERC721m.ownerOf(_tokenId) == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _tokenId);

        // Clear approvals _from the previous owner
        _approve(address(0), _tokenId);

        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Approve `_to` to operate on `_tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address _to, uint256 _tokenId) internal virtual {
        _tokenApprovals[_tokenId] = _to;
        emit Approval(ERC721m.ownerOf(_tokenId), _to, _tokenId);
    }

    /**
     * @dev Approve `_operator` to operate on all of `_owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address _owner,
        address _operator,
        bool _approved
    ) internal virtual {
        require(_owner != _operator, "ERC721: approve to caller");
        _operatorApprovals[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_to.isContract()) {
            try IERC721Receiver(_to).onERC721Received(_msgSender(), _from, _tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    /**
     * @dev Hooks that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `_from` and `_to` are both non-zero, `_from`'s `tokenId` will be
     * transferred to `_to`.
     * - When `_from` is zero, `tokenId` will be minted for `_to`.
     * - When `_to` is zero, ``_from``'s `tokenId` will be burned.
     * - `_from` and `_to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual {}
}