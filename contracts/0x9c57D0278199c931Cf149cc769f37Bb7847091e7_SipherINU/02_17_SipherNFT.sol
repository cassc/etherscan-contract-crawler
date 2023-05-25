// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {ERC721Burnable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import {ISipherNFT} from '../interfaces/ISipherNFT.sol';


contract SipherNFT is ERC721, ERC721Enumerable, Pausable, ERC721Burnable, Ownable, ISipherNFT {
  // only allow genesis minter to mint at most 10K INU
  uint64 public constant MAX_GENESIS_SUPPLY = 10000;

  address public override genesisMinter;
  address public override forkMinter;

  // starting index for genesis mixing, default: 0, means the minter hasn't rolled to init it
  uint256 public override randomizedStartIndex;
  // current genesis token id, default: 0, the first token will have ID of 1
  uint256 public override currentId;
  string public override baseSipherURI;
  string internal _storeFrontURI;

  // Mapping from token ID to its original, if the original
  // is 0, the NFT is genesis, otherwise it is a clone
  mapping(uint256 => uint256) public override originals;

  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  /**
   * @dev Throws if called by any account other than the genesis minter.
   */
  modifier onlyGenesisMinter() {
    require(genesisMinter == _msgSender(), 'SipherERC721: caller is not genesis minter');
    _;
  }

  /**
   * @dev Throws if called by any account other than the fork minter.
   */
  modifier onlyForkMinter() {
    require(forkMinter == _msgSender(), 'SipherERC721: caller is not fork minter');
    _;
  }

  /**
   * @dev set genesis minter to a new address.
   * Can only be called by the current owner.
   * @param newMinter the new genesis minter
   */
  function setGenesisMinter(address newMinter) external onlyOwner {
    genesisMinter = newMinter;
  }

  /**
   * @dev set fork minter to a new address.
   * Can only be called by the current owner.
   * @param newMinter the new fork minter
   */
  function setForkMinter(address newMinter) external onlyOwner {
    forkMinter = newMinter;
  }

  /**
   * @dev set opensea storefront uri.
   * Can only be called by the current owner. No validation is done
   * for the input.
   * @param _uri new store front uri
   */
  function setStoreFrontURI(string calldata _uri) external onlyOwner {
    _storeFrontURI = _uri;
  }

  /**
   * @dev set base uri that is used to return nft uri.
   * Can only be called by the current owner. No validation is done
   * for the input.
   * @param _uri new base uri
   */
  function setBaseURI(string calldata _uri) external onlyOwner {
    baseSipherURI = _uri;
  }

  /**
   * @dev Call by only owner to pause the transfer
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev Call by only owner to unpause the transfer
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @dev Call only by the Genesis Minter to roll the start index
   */
  function rollStartIndex() external override onlyGenesisMinter {
    require(randomizedStartIndex == 0, 'SipherERC721: start index is already rolled');

    uint256 number = uint256(
      keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase, block.difficulty))
    );

    randomizedStartIndex = number % MAX_GENESIS_SUPPLY + 1;
  }

  /**
   * @dev Call to mint new genesis tokens, only by Genesis Minter
   *  Can mint up to MAX_GENESIS_SUPPLY tokens
   * @param amount amount of genesis tokens to mint
   * @param to recipient of genesis tokens
   */
  function mintGenesis(uint256 amount, address to) external override onlyGenesisMinter {
    uint256 startId = currentId;
    require(
      startId + amount <= MAX_GENESIS_SUPPLY,
      'SipherERC721: max genesis supply reached'
    );

    currentId += amount;

    for (uint256 i = 1; i <= amount; i++) {
      _safeMint(to, startId + i);
    }
  }

  /**
   * @dev Call to mint a fork of a tokenId, only by Fork Minter
   *  need to wait for all genesis to be minted before minting forks
   *  allow to mint multile forks for a tokenId
   * @param tokenId id of token to mint a fork
   */
  function mintFork(uint256 tokenId) external override onlyForkMinter {
    uint256 forkId = currentId + 1;
    require(forkId > MAX_GENESIS_SUPPLY, 'SipherERC721: not mint all genesis yet');

    address owner = ownerOf(tokenId);
    require(owner != address(0), 'SipherERC721: token does not exist');

    currentId++;

    // setting the fork's original to this token
    originals[forkId] = tokenId;

    _safeMint(owner, forkId);
  }

  function contractURI() external view override returns (string memory) {
    return _storeFrontURI;
  }

  /**
   * @dev Return owner of a token id if exists
   *  Revert if the tokenId is invalid (0 or not minted yet)
   *  Return 0x0 if the tokenId has been burnt
   */
  function ownerOf(uint256 tokenId)
    public
    view
    override(ERC721, IERC721) returns (address)
  {
    require(tokenId <= currentId && tokenId > 0, 'SipherERC721: invalid token id');
    if (_exists(tokenId)) return super.ownerOf(tokenId);
    return address(0); // token id is burnt
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, IERC165)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`.
   */
  function _baseURI() internal view override returns (string memory) {
    return baseSipherURI;
  }
}