// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title ERC721M.sol. Metadrop implementation of ERC721
 *
 * @author metadrop https://metadrop.com/
 *
 * @notice Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 *
 * Included features:
 * - LayerZero ONFT
 * - gas efficient batch minting
 * - clonable
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../ThirdParty/EPS/EPSDelegationRegister/IEPSDelegationRegister.sol";
import "../ThirdParty/LayerZero/onft/IONFT721.sol";
import "../ThirdParty/LayerZero/onft/ONFT721Core.sol";

contract ERC721M is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  ONFT721Core,
  IONFT721,
  ERC2981,
  AccessControl
{
  using Address for address;
  using Strings for uint256;

  address internal constant BURN_ADDRESS =
    0x000000000000000000000000000000000000dEaD;

  // Boolean to indicate if this contract is a layerZero base contract
  bool private immutable layerZeroBase;

  // EPS Register
  IEPSDelegationRegister internal immutable epsRegister;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  uint256 internal remainingSupply;
  uint256 public maxSupply;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  error CallerIsNotOwnerOrApproved();
  error SendFromIncorrectOwner();
  error InvalidToken();
  error QuantityExceedsRemainingSupply();

  /** ====================================================================================================================
   *                                              CONSTRUCTOR AND INTIIALISE
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                        -->CONSTRUCTOR
   * @dev constructor           The constructor is not called when the contract is cloned. In this
   *                            constructor we just setup default values and set the template contract to initialised.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param epsRegister_        The EPS register address (0x888888888888660F286A7C06cfa3407d09af44B2 on most chains)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param lzEndpoint_         The LZ endpoint for this chain
   *                            (see https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param layerZeroBase_      If this contract is the base layerZero contract. For this ONFT implementation the base
   *                            contract is where intial minting can occue. NFTs can then be sent to any supporting chain
   *                            but cannot be 'freshly' minted on other chains and sent to the base contract.
   * _____________________________________________________________________________________________________________________
   */
  constructor(
    address epsRegister_,
    address lzEndpoint_,
    bool layerZeroBase_
  ) ONFT721Core(lzEndpoint_) {
    epsRegister = IEPSDelegationRegister(epsRegister_);
    layerZeroBase = layerZeroBase_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseNFT  Load configuration into storage for a new instance.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param name_               The name of the NFT
   * ---------------------------------------------------------------------------------------------------------------------
   * @param symbol_             The symbol of the NFT
   * ---------------------------------------------------------------------------------------------------------------------
   * @param maxSupply_          The maximum supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param owner_              The owner for this contract. Will be used to set the owner in ERC721M and also the
   *                            platform admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _initialiseERC721M(
    string memory name_,
    string memory symbol_,
    uint256 maxSupply_,
    address owner_
  ) internal {
    _name = name_;
    _symbol = symbol_;
    maxSupply = maxSupply_;
    remainingSupply = maxSupply_;
    _transferOwnership(owner_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->LAYERZERO
   * @dev (function) _debitFrom  debit an item from a holder on layerzero call. While off-chain the NFT is custodied in
   * this contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from_               The current owner of the asset
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_            The tokenId being sent via LayerZero
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _debitFrom(
    address from_,
    uint16,
    bytes memory,
    uint256 tokenId_
  ) internal virtual override {
    if (!(_isApprovedOrOwner(_msgSender(), tokenId_))) {
      revert CallerIsNotOwnerOrApproved();
    }

    if (!(ownerOf(tokenId_) == from_)) {
      revert SendFromIncorrectOwner();
    }

    _transfer(from_, address(this), tokenId_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->LAYERZERO
   * @dev (function) _creditTo  credit an item to a holder on layerzero call. While off-chain the NFT is custodied in
   * this contract, this transfers it back to the holder
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param toAddress_          The recipient of the asset
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_            The tokenId that has been sent via LayerZero
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _creditTo(
    uint16,
    address toAddress_,
    uint256 tokenId_
  ) internal virtual override {
    if (!(_exists(tokenId_) && ownerOf(tokenId_) == address(this))) {
      revert InvalidToken();
    }
    // Different behaviour depending on whether this has been deployed on
    // the base chain or a satellite chain:
    if (layerZeroBase) {
      // Base chain. For us to be crediting the owner this token MUST be
      // owned by the contract, as they can only be minted on the base chain
      if (!(_exists(tokenId_) && ownerOf(tokenId_) == address(this))) {
        revert InvalidToken();
      }

      _transfer(address(this), toAddress_, tokenId_);
    } else {
      // Satellite chain. We can be crediting the user as a result of this reaching
      // this chain for the first time (mint) OR from a token that has been minted
      // here previously and is currently custodied by the contract.
      if (_exists(tokenId_) && ownerOf(tokenId_) != address(this)) {
        revert InvalidToken();
      }

      if (!_exists(tokenId_)) {
        _safeMint(toAddress_, tokenId_);
      } else {
        _transfer(address(this), toAddress_, tokenId_);
      }
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) _mintIdWithoutBalanceUpdate  Mint an item without updating a holder's balance, so that this can
   * be performed just once per batch.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to_          The recipient of the asset
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_            The tokenId that has been sent via LayerZero
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _mintIdWithoutBalanceUpdate(address to_, uint256 tokenId_) private {
    _beforeTokenTransfer(address(0), to_, tokenId_, 1);

    _owners[tokenId_] = to_;

    emit Transfer(address(0), to_, tokenId_);

    _afterTokenTransfer(address(0), to_, tokenId_, 1);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) _mintSequential  Mint NFTs in order (0,1,2,3 etc)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to_          The recipient of the asset
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantity_    The number of tokens to mint
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _mintSequential(
    address to_,
    uint256 quantity_
  ) internal virtual returns (uint256[] memory mintedTokenIds_) {
    if (quantity_ > remainingSupply) {
      revert QuantityExceedsRemainingSupply();
    }

    mintedTokenIds_ = new uint256[](quantity_);

    uint256 tokenId = maxSupply - remainingSupply;

    for (uint256 i = 0; i < quantity_; ) {
      _mintIdWithoutBalanceUpdate(to_, tokenId + i);

      mintedTokenIds_[i] = tokenId + i;

      unchecked {
        i++;
      }
    }

    remainingSupply = remainingSupply - quantity_;
    _balances[to_] += quantity_;

    return (mintedTokenIds_);
  }

  /** ____________________________________________________________________________________________________________________
   *
   * @dev (function) totalSupply  Returns total supply (minted - burned)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalSupply_   The total supply of this collection (minted - burned)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalSupply() external view virtual returns (uint256 totalSupply_) {
    //
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalUnminted  Returns the remaining unminted supply
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalUnminted_   The total unminted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalUnminted()
    external
    view
    virtual
    returns (uint256 totalUnminted_)
  {
    //
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalMinted  Returns the total number of tokens ever minted
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalMinted_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalMinted() external view virtual returns (uint256 totalMinted_) {
    //
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalBurned  Returns the count of tokens sent to the burn address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalBurned_   The total burned supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalBurned() external view virtual returns (uint256 totalBurned_) {
    //
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC165, IERC165, ERC2981, ONFT721Core, AccessControl)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(
    address owner
  ) public view virtual override returns (uint256) {
    require(owner != address(0), "Non-owner");
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(
    uint256 tokenId
  ) public view virtual override returns (address) {
    address owner = _ownerOf(tokenId);
    require(owner != address(0), "Invalid token");
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
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721M.ownerOf(tokenId);
    require(to != owner, "Approve to owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "Unauthorised"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(
    uint256 tokenId
  ) public view virtual override returns (address) {
    _requireMinted(tokenId);

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(
    address owner,
    address operator
  ) public view virtual override returns (bool) {
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
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Unauthorised");

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
    bytes memory data
  ) public virtual override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Unauthorised");
    _safeTransfer(from, to, tokenId, data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
    bytes memory data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, data), "Non-receiver");
  }

  /**
   * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
   */
  function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
    return _owners[tokenId];
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
    return _ownerOf(tokenId) != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  ) internal view virtual returns (bool) {
    address owner = ERC721M.ownerOf(tokenId);
    return (spender == owner ||
      isApprovedForAll(owner, spender) ||
      getApproved(tokenId) == spender);
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, data),
      "Non-receiver"
    );
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
  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "0 address");
    require(!_exists(tokenId), "Already minted");

    _beforeTokenTransfer(address(0), to, tokenId, 1);

    // Check that tokenId was not minted by `_beforeTokenTransfer` hook
    require(!_exists(tokenId), "Already minted");

    unchecked {
      // Will not overflow unless all 2**256 token ids are minted to the same owner.
      // Given that tokens are minted one by one, it is impossible in practice that
      // this ever happens. Might change if we allow batch minting.
      // The ERC fails to describe this case.
      _balances[to] += 1;
    }

    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId, 1);
  }

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Unauthorised");
    _burn(tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   * This is an internal function that does not check if the sender is authorized to operate on the token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721M.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId, 1);

    // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
    owner = ERC721M.ownerOf(tokenId);

    // Clear approvals
    delete _tokenApprovals[tokenId];

    unchecked {
      // Cannot overflow, as that would require more tokens to be burned/transferred
      // out than the owner initially received through minting and transferring in.
      _balances[owner] -= 1;
      _owners[tokenId] = BURN_ADDRESS;
      _balances[BURN_ADDRESS] += 1;
    }
    delete _owners[tokenId];

    emit Transfer(owner, BURN_ADDRESS, tokenId);

    _afterTokenTransfer(owner, BURN_ADDRESS, tokenId, 1);
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
  ) internal virtual {
    require(ERC721M.ownerOf(tokenId) == from, "Non-owner");
    require(to != address(0), "0 address");

    _beforeTokenTransfer(from, to, tokenId, 1);

    // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
    require(ERC721M.ownerOf(tokenId) == from, "Non-owner");

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];

    unchecked {
      // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
      // `from`'s balance is the number of token held, which is at least one before the current
      // transfer.
      // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
      // all 2**256 token ids to be minted, which in practice is impossible.
      _balances[from] -= 1;
      _balances[to] += 1;
    }
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721M.ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "Approve to caller");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), "Invalid token");
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          /// @solidity memory-safe-assembly
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
   * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
   * - When `from` is zero, the tokens will be minted for `to`.
   * - When `to` is zero, ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 /* firstTokenId */,
    uint256 batchSize
  ) internal virtual {
    if (batchSize > 1) {
      if (from != address(0)) {
        _balances[from] -= batchSize;
      }
      if (to != address(0)) {
        _balances[to] += batchSize;
      }
    }
  }

  /**
   * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
   * - When `from` is zero, the tokens were minted for `to`.
   * - When `to` is zero, ``from``'s tokens were burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual {}
}