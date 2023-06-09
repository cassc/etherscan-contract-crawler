// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { ERC721Enumerable } from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import { SafeMath } from '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
 * @title ERC721FairDistribution
 * @author this-is-obvs
 *
 * @notice ERC721 base contract supporting a fair and random distribution of tokens, with a fixed
 *  minting price. The owner of the contract is responsible for ensuring that the NFT works are
 *  stored in decentralized storage, and provably linked to this contract via _provenanceHash.
 *
 *  The following events should happen in order, coordinated by the contract owner:
 *    1. The pre-sale begins, during which tokens may be purchased, but the NFT pieces have not yet
 *       been revealed.
 *    2. The _provenanceHash is finalized on-chain, acting as a commitment to the content and
 *       metadata of the NFT series, as well as the order of original sequence IDs.
 *    3. A starting index is chosen pseudorandomly and is used to determine how the NFT token IDs
 *       are mapped to original sequence IDs. This helps to ensure a fair distribution.
 *    4. The NFT pieces are revealed, by updating the _baseTokenUri.
 *    5. After the conclusion of the sale, it is recommended that the contract owner renounce
 *       ownership, to prevent further changes to the _baseTokenUri or _provenanceHash. Before
 *       giving up ownership, the owner may call pauseMinting(), if necessary, to cap the supply.
 *
 *  The starting index is determined pseudorandomly using a recent block hash once one of the
 *  following occurs:
 *    1. The last token is purchased; OR
 *    2. The first token is purchased after the _presaleEnd timestamp; OR
 *    3. If either of the above takes too long to occur, the owner may take manual action to ensure
 *       that the starting index is chosen promptly.
 *
 *  Once the starting index is chosen, each NFT token ID is mapped to an original sequence ID
 *  according to the formula:
 *
 *    Original Sequence ID = (NFT Token ID + Starting Index) % Max Supply
 */
contract ERC721FairDistribution is
  ERC721Enumerable,
  Ownable
{
  using SafeMath for uint256;

  event Withdrew(uint256 balance);
  event MintPriceUpdated(uint256 mintPrice);
  event PresaleStartUpdated(uint256 presaleStart);
  event PresaleEndUpdated(uint256 presaleEnd);
  event BaseTokenUriUpdated(string baseTokenUri);
  event ProvenanceHashUpdated(string provenanceHash);
  event MintingPaused();
  event MintingUnpaused();
  event SetStartingIndexBlockNumber(uint256 blockNumber, bool usedForce);
  event SetStartingIndex(uint256 startingIndex, uint256 blockNumber);

  /// @notice The maximum number of tokens which may ever be minted.
  uint256 public immutable MAX_SUPPLY;

  /// @notice Max tokens which can be purchased per call to the mint() function.
  uint256 public immutable MAX_PURCHASE_QUANTITY;

  /// @notice The price to mint a token.
  uint256 public _mintPrice;

  /// @notice The timestamp marking the start of the pre-sale.
  uint256 public _presaleStart;

  /// @notice The timestamp marking the end of the pre-sale.
  uint256 public _presaleEnd;

  /// @notice The block number to be used to derive the starting index.
  uint256 public _startingIndexBlockNumber;

  /// @notice The starting index, chosen pseudorandomly to help ensure a fair distribution.
  uint256 public _startingIndex;

  /// @notice The base URI used to retrieve the data associated with the tokens.
  string internal _baseTokenUri;

  /// @notice A hash provided by the contract owner to commit to the content, metadata, and
  ///  sequence order of the NFT series.
  string public _provenanceHash;

  /// @notice Indicates whether minting has been paused by the contract owner.
  bool public _isMintingPaused;

  constructor(
    string memory name,
    string memory symbol,
    uint256 maxSupply,
    uint256 mintPrice,
    uint256 maxPurchaseSize,
    uint256 presaleStart,
    uint256 presaleEnd
  )
    ERC721(name, symbol)
  {
    MAX_SUPPLY = maxSupply;
    MAX_PURCHASE_QUANTITY = maxPurchaseSize;
    _mintPrice = mintPrice;
    _presaleStart = presaleStart;
    _presaleEnd = presaleEnd;
    emit PresaleStartUpdated(presaleStart);
    emit PresaleEndUpdated(presaleEnd);
  }

  function mintPresale()
    external
    onlyOwner
  {
    // Mint cows sold during the pre-sale, to be distributed separately.
    for (uint256 i = 50; i < 119; i++) {
      _safeMint(0xdEf4Ed6e5Aa0Aea70503C91F12587a06dDc1e60F, i);
    }
    require(totalSupply() == 119);
  }

  /**
   * @notice Withdraw contract funds.
   *
   * @return The withdrawn amount.
   */
  function withdraw()
    external
    onlyOwner
    returns (uint256)
  {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
    emit Withdrew(balance);
    return balance;
  }

  /**
   * @notice Set the mint price (denominated in wei).
   */
  function setMintPrice(uint256 mintPrice)
    external
    onlyOwner
  {
    _mintPrice = mintPrice;
    emit MintPriceUpdated(mintPrice);
  }

  /**
   * @notice Set the timestamp which marks the start of the pre-sale.
   */
  function setPresaleStart(uint256 presaleStart)
    external
    onlyOwner
  {
    _presaleStart = presaleStart;
    emit PresaleStartUpdated(presaleStart);
  }

  /**
   * @notice Set the timestamp which marks the end of the pre-sale.
   */
  function setPresaleEnd(uint256 presaleEnd)
    external
    onlyOwner
  {
    _presaleEnd = presaleEnd;
    emit PresaleEndUpdated(presaleEnd);
  }

  /**
   * @notice Set the base URI. This is used to update the NFT off-chain content and/or metadata.
   *  This should be called at the conclusion of the pre-sale, after the starting index has been
   *  selected, in order to reveal the final NFT pieces.
   */
  function setBaseTokenUri(string memory baseUri)
    external
    onlyOwner
  {
    _baseTokenUri = baseUri;
    emit BaseTokenUriUpdated(baseUri);
  }

  /**
   * @notice Set the hash committing to the content, metadata, and sequence order of the NFT series.
   */
  function setProvenanceHash(string memory provenanceHash)
    external
    onlyOwner
  {
    _provenanceHash = provenanceHash;
    emit ProvenanceHashUpdated(provenanceHash);
  }

  /**
   * @notice Pause minting.
   */
  function pauseMinting()
    external
    onlyOwner
  {
    _isMintingPaused = true;
    emit MintingPaused();
  }

  /**
   * @notice Unpause minting.
   */
  function unpauseMinting()
    external
    onlyOwner
  {
    _isMintingPaused = false;
    emit MintingUnpaused();
  }

  /**
   * @notice Mint a token.
   */
  function mint(uint256 purchaseQuantity)
    external
    payable
  {
    require(block.timestamp >= _presaleStart, 'The sale has not started');
    require(!_isMintingPaused, 'Minting is disabled');
    require(purchaseQuantity <= MAX_PURCHASE_QUANTITY, 'Max purchase quantity exceeded');
    require(totalSupply().add(purchaseQuantity) <= MAX_SUPPLY, 'Purchase would exceed max supply');
    require(_mintPrice.mul(purchaseQuantity) <= msg.value, 'Insufficient payment received');

    for(uint256 i = 0; i < purchaseQuantity; i++) {
      _safeMint(msg.sender, totalSupply());
    }

    if (_startingIndexBlockNumber != 0) {
      return;
    }

    // Finalize the starting index as soon as either of the following occurs:
    //   1. The first token is purchased after the _presaleEnd timestamp; OR
    //   2. The final token is purchased.
    if (
      block.timestamp > _presaleEnd ||
      totalSupply() == MAX_SUPPLY
    ) {
      _startingIndexBlockNumber = block.number;
      emit SetStartingIndexBlockNumber(block.number, false);
    }
  }

  /**
   * @notice Fix the starting index for the collection using the previously determined block number.
   */
  function setStartingIndex() external {
    uint256 targetBlock = _startingIndexBlockNumber;

    require(targetBlock != 0, 'Starting index block number has not been set');

    // If the hash for the desired block is unavailable, fall back to the most recent block.
    if (block.number.sub(targetBlock) > 256) {
      targetBlock = block.number - 1;
    }

    uint256 startingIndex = uint256(blockhash(targetBlock)) % MAX_SUPPLY;
    emit SetStartingIndex(startingIndex, targetBlock);

    _startingIndex = startingIndex;
  }

  /**
   * @notice Set the starting index block number, which will determine the starting index for the
   *  collection. This is still pseudorandom since the starting index will depend on the hash of
   *  the current block.
   *
   *  An appropriate time to call this would be after some window of time following the _presaleEnd
   *  timestamp, if time passes without anyone purchasing a token. In such a situation, it is in
   *  the community's interests for the owner to finalize the starting index, to reduce the
   *  opportunity for anyone to manipulate the starting index. For best security/fairness, the
   *  length of the window of time to wait should be committed to by the contract owner before the
   *  time indicated by the _presaleEnd timestamp.
   */
  function forceSetStartingIndexBlock()
    external
    onlyOwner
  {
    require(_startingIndexBlockNumber == 0, 'Starting index block number is already set');
    _startingIndexBlockNumber = block.number;
    emit SetStartingIndexBlockNumber(block.number, true);
  }

  function _baseURI()
    internal
    view
    override
    returns (string memory)
  {
    return _baseTokenUri;
  }
}