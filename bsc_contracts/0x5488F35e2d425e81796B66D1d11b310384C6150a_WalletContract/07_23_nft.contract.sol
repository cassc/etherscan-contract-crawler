// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

contract NftContract is Context, Ownable, ERC721Pausable  {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdTracker;

  // See {NFT-_baseURI}.
  string private _baseTokenURI;
  // Address of wallet contract to allow external token minting
  address private _walletContractAddress;

  /**
    * @dev Initializes the contract by setting a `name`, `symbol` and `baseTokenURI` to the token collection.
    */
  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseTokenURI_
  ) ERC721(name_, symbol_) {
    _baseTokenURI = baseTokenURI_;
  }

  /**
    * @dev Create token owned by `to`. TokenId starting from 1 and incrementing by 1 for each new token.
    * Returns tokenId of created token.
    *
    * Requirements:
    *
    * - the caller must be contract owner.
    * - the contract must not be paused.
    * - `to` cannot be the zero address.
    *
    * Emits a {Transfer} event.
    */
  function createItem(address to)
  public onlyOwnerOrWallet
  returns (uint256)
  {
    _tokenIdTracker.increment();

    uint256 newItemId = _tokenIdTracker.current();
    _mint(to, newItemId);

    return newItemId;
  }

  /**
    * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    * token will be the concatenation of the `baseTokenURI` and the `tokenId`.
    */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /**
    * @dev Pauses all token transfers.
    *
    * See {ERC721Pausable} and {Pausable-_pause}.
    *
    * Requirements:
    *
    * - the caller must be owner.
    */
  function pause() public virtual onlyOwner {
  _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must be owner.
   */
  function unpause() public virtual onlyOwner {
  _unpause();
  }

  /**
   * @dev Returns the address of the wallet contract approved to createItem.
    */
  function _getWalletContractAddress() private view returns (address) {
    return _walletContractAddress;
  }

  /**
    * @dev Set new wallet contract address approved to createItem.
    * Requirements:
    *
    * - the caller must be owner.
    */
  function setWalletContractAddress(address newAddress) public onlyOwner {
    _setWalletContractAddress(newAddress);
  }

  /**
    * @dev Set new wallet contract address approved to createItem.
    */
  function _setWalletContractAddress(address newAddress) private {
    require(newAddress != address(0), "NftContract: new wallet contract address can't be zero address");
    _walletContractAddress = newAddress;
  }

  /**
    * @dev Throws if called by any account other than the owner or wallet contract.
    */
  modifier onlyOwnerOrWallet() {
    require(owner() == _msgSender() || _getWalletContractAddress() == _msgSender(), "NftContract: caller is not the owner nor wallet contract");
    _;
  }

  /**
    * @dev See {ERC721Pausable-_beforeTokenTransfer}.
    */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}