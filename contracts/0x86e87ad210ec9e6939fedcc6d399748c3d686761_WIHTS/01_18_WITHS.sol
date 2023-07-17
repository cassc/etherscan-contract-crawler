// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import {ERC721Psi} from './ERC721Psi.sol';
import {ERC2981Base, ERC2981ContractWideRoyalties} from './ERC2981ContractWideRoyalties.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

/**
 * @author Contract written by Duffles (https://github.com/DefiMatt) for
 * project 'Wish I Had The Same'.
 */
contract WIHTS is ERC721Psi, ERC2981ContractWideRoyalties, Ownable {
  using Strings for uint256;

  /*//////////////////////////////////////////////////////////////
    Public state.
  //////////////////////////////////////////////////////////////*/

  /// @notice Base URI for computing {tokenURI}.
  string public baseURI;
  /// @notice The number of NFTs claimed per address.
  mapping(address => uint256) public claimed;
  /// @notice The number of NFTs minted for free.
  uint256 public freeMints;
  /// @notice Whether the mint is open.
  bool public mintOpen;
  /// @notice The price in wei per NFT.
  uint256 public price = 0.0079 ether;
  /// @notice URI for {tokenURI} before the reveal.
  string public unrevealedURI =
    'https://arweave.net/TdxegBMOs1GtUdFHoN2sMC5L9dH5mx_A6SfI5SfyvY0';

  /*//////////////////////////////////////////////////////////////
    Errors.
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice The attempt to mint the requested amount of NFTs would exceed the
   * maximum number of NFTs allowed per wallet.
   *
   * @param counterfactualNumberInWallet What the number of NFTs minted by the
   * recipient wallet would have been if the requested amount of NFTs were
   * minted.
   */
  error MaximumPerWalletExceeded(uint256 counterfactualNumberInWallet);
  /**
   * @notice The attempt to mint the requested amount of NFTs would exceed the
   * maximum supply allowed.
   *
   * @param counterfactualNewSupply What the total supply would have been if the
   * requested amount of NFTs were minted.
   */
  error MaximumSupplyExceeded(uint256 counterfactualNewSupply);
  /// @notice Attempted to mint after minting was closed.
  error MintClosed();
  /// @notice Attempted to set royalties beyond the permitted maximum.
  error RoyaltiesTooHigh();
  /// @notice Attempted to query for a non-existent token.
  error TokenNonexistent();
  /**
   * @notice The wrong fee was supplied with the attempt to mint the requested
   * amount of NFTs.
   *
   * @param expectedFee The fee required to mint the amount of NFTs requested.
   * @param receivedFee The incorrect fee received.
   */
  error WrongFee(uint256 expectedFee, uint256 receivedFee);
  /// @notice Attempted to mint zero NFTs.
  error ZeroMintsRequested();

  /*//////////////////////////////////////////////////////////////
    Public functions.
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Mint one or more NFTs to the sender. If there are free mints
   * remaining and the sender hasn't minted yet, they get the first one free.
   *
   * @param amount How many to mint.
   */
  function mint(uint256 amount) external payable {
    if (!mintOpen) revert MintClosed();
    if (0 == amount) revert ZeroMintsRequested();

    uint256 newSupply = totalSupply() + amount;
    if (newSupply > 5_000) revert MaximumSupplyExceeded(newSupply);

    uint256 _claimed = claimed[msg.sender];
    uint256 newClaimed = _claimed + amount;

    if (newClaimed > 10) revert MaximumPerWalletExceeded(newClaimed);

    uint256 expectedFee;

    if (0 == _claimed && freeMints < 2_000) {
      ++freeMints;
      expectedFee = price * (amount - 1);
    } else {
      expectedFee = price * amount;
    }

    if (msg.value != expectedFee) revert WrongFee(expectedFee, msg.value);

    claimed[msg.sender] = newClaimed;
    _mint(msg.sender, amount);
  }

  /*//////////////////////////////////////////////////////////////
    Constructor.
  //////////////////////////////////////////////////////////////*/

  constructor() ERC721Psi('Wish I Had The Same', 'WIHTS') {
    // Initial royalties of 2.5%.
    _setRoyalties(address(0xC703E1c25cEAb92F4a88BEb51f6c03EF72055aA3), 250);
    _transferOwnership(address(0xC703E1c25cEAb92F4a88BEb51f6c03EF72055aA3));
  }

  /*//////////////////////////////////////////////////////////////
    Privileged functions.
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Toggle minting.
   *
   * @dev Can only be used by the owner.
   */
  function toggleMint() external onlyOwner {
    mintOpen = !mintOpen;
  }

  /**
   * @notice Change {baseURI}.
   *
   * @dev Can only be used by the owner.
   *
   * @param newBaseURI The new {baseURI}.
   */
  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  /**
   * @notice Change {price} per NFT.
   *
   * @dev Can only be used by the owner.
   *
   * @param newPrice The new {price} in wei per NFT.
   */
  function setPrice(uint256 newPrice) external onlyOwner {
    price = newPrice;
  }

  /**
   * @notice Change royalties (see {ERC2981ContractWideRoyalties-royaltyInfo}).
   *
   * @dev Can only be used by the owner.
   *
   * @param royaltyReceiver Address to receive royalty payments.
   * @param royaltyAmount Permyriadage / basis points (‱) of sale amounts to be
   * paid as royalties.
   */
  function setRoyalties(address royaltyReceiver, uint256 royaltyAmount)
    external
    onlyOwner
  {
    // Maximum royalties of 7.5%.
    if (royaltyAmount > 750) revert RoyaltiesTooHigh();

    _setRoyalties(royaltyReceiver, royaltyAmount);
  }

  /**
   * @notice Change {unrevealedURI}.
   *
   * @dev Can only be used by the owner.
   *
   * @param _unrevealedURI URI for {tokenURI} before the reveal.
   */
  function setUnrevealedURI(string memory _unrevealedURI) external onlyOwner {
    unrevealedURI = _unrevealedURI;
  }

  /**
   * @notice Withdraw accumulated Ether.
   */
  function withdraw() external onlyOwner {
    payable(address(0xDb2Da28bE4d1bF9b1A988643D0A82033CD7B011C)).transfer(
      address(this).balance / 10
    );
    payable(owner()).transfer(address(this).balance);
  }

  /*//////////////////////////////////////////////////////////////
    View functions.
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the URI for the token with id `tokenId`.
   *
   * @dev Returns {unrevealedURI} pre-reveal, and the concatenation of
   * {baseURI}, `tokenId` and '.json' post-reveal (see {baseURI} for more
   * details).
   *
   * @param tokenId The token id to get the URI for.
   * @return The URI for the token.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(tokenId)) revert TokenNonexistent();

    return
      0 == bytes(baseURI).length
        ? unrevealedURI
        : string(abi.encodePacked(baseURI, (tokenId + 1).toString(), '.json'));
  }

  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Psi, ERC2981Base)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}