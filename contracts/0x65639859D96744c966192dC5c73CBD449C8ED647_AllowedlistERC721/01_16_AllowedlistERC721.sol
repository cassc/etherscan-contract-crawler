// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * @title AllowedlistERC721 collection.
 * @author SBINFT Co., Ltd.
 */
contract AllowedlistERC721 is ERC721, Ownable, DefaultOperatorFilterer {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _tokenIdCounter;

  string private _baseTokenURI;
  uint256 private _currentPriceGold;
  uint256 private _currentPriceSilver;
  uint256 private _currentPricePublic;
  // @notice account for payable function dest.
  address payable private _withdrawAccount;
  // @notice uppler bounds for each phase.
  uint16 private _tokenUpperBounds = 3333;

  // @notice 0 for phase1, 1 for phase2, 2 for phase3.
  uint8 private _currentPhase = 0;
  // @notice 0 = gold, 1 = silver, 2=public
  uint8 private _currentAllowedRank = 0;

  mapping(uint8 => mapping(address => uint16)) private _allowedUserListGold;
  mapping(uint8 => mapping(address => uint16)) private _allowedUserListSilver;

  /**
   * @dev AllowedlistERC721 constructor
   *
   * @param name_ string name of the token
   * @param symbol_ string symbol of the token
   * @param baseTokenURI string base URI
   * @param owner_ address of owner of the contract
   * @param priceGold uint256 price of gold token
   * @param priceSilver uint256 price of gold token
   * @param pricePublic uint256 price of public token
   * @param withdrawAccount address payable
   */
  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseTokenURI,
    address owner_,
    uint256 priceGold,
    uint256 priceSilver,
    uint256 pricePublic,
    address payable withdrawAccount
  ) ERC721(name_, symbol_) {
    transferOwnership(owner_);
    _baseTokenURI = baseTokenURI;
    _currentPriceGold = priceGold;
    _currentPriceSilver = priceSilver;
    _currentPricePublic = pricePublic;
    _withdrawAccount = withdrawAccount;
  }

  /**
   * @dev Mint a NFT
   *
   * @param to address to which NFT to be minted
   * @param amount uint16 count of NFT to be minted
   */
  function mint(address to, uint16 amount) external payable {
    require(
      amount != 0,
      "AllowedlistERC721:mint: amount should be greater than zero"
    );

    uint256 price = getPrice(_currentAllowedRank);

    require(
      msg.value == price * amount,
      "AllowedlistERC721:mint: Not enough value received for mint"
    );

    // @notice total minted token should be less than 3,333 by each phase.
    require(
      getRemainingTokenByAddress(to, _currentAllowedRank) >= amount &&
        getRemainingToken(_currentPhase) >= amount,
      "AllowedlistERC721:mint: to address is not in the AllowedList or No token left for mint"
    );

    // @dev allowedList management.
    if (_currentAllowedRank == 0) {
      // For gold
      _allowedUserListGold[_currentPhase][to] =
        _allowedUserListGold[_currentPhase][to] -
        amount;
    } else if (_currentAllowedRank == 1) {
      // For silver
      _allowedUserListSilver[_currentPhase][to] =
        _allowedUserListSilver[_currentPhase][to] -
        amount;
    }

    for (uint16 i = 0; i < amount; i++) {
      // @dev TokenId management.
      _tokenIdCounter.increment();
      uint256 tokenId = _tokenIdCounter.current();

      // @dev mint.
      _safeMint(to, tokenId);
    }

    // @dev transfer amount to withdraw account.abi
    _withdrawAccount.transfer(msg.value);
  }

  /**
   * @dev Function for owner free mint needed for ops reason.
   *
   * @param to address to which NFT to be minted
   * @param amount uint256 count of NFT to be minted
   *
   * Requirement
   * - onlyOwner can call
   */
  function ownerMint(address to, uint256 amount) external onlyOwner {
    // @notice total minted token should be less than 3,333 by each phase.
    require(
      getRemainingToken(_currentPhase) >= amount,
      "AllowedlistERC721:ownerMint: Already reached Token Upper bounds."
    );

    for (uint256 i = 0; i < amount; i++) {
      _tokenIdCounter.increment();
      uint256 tokenId = _tokenIdCounter.current();
      _safeMint(to, tokenId);
    }
  }

  /**
   * @dev Returns Token Upper Bounds
   */
  function getTokenUpperBounds() public view returns (uint256) {
    return _tokenUpperBounds;
  }

  /**
   * @dev Update Token Upper Bounds
   *
   * @param upper uint16 update upper limit
   *
   * Requirement
   * - onlyOwner can call
   */
  function setTokenUpperBounds(uint16 upper)
    external
    onlyOwner
    returns (uint256)
  {
    _tokenUpperBounds = upper;
    return _tokenUpperBounds;
  }

  /**
   * @dev Allowed List checker
   *
   * @param addr address
   * @param rank uint8
   * @return upper limit of respective rank
   */
  function getRemainingTokenByAddress(address addr, uint8 rank)
    public
    view
    returns (uint256)
  {
    if (rank == 0) {
      // For gold
      return _allowedUserListGold[_currentPhase][addr];
    } else if (rank == 1) {
      // For silver
      return _allowedUserListSilver[_currentPhase][addr];
    } else {
      return getRemainingToken(_currentPhase);
    }
  }

  /**
   * @dev Set Allowed User List
   *
   * @param phase uint8 Mint Sale phase(1~3)
   * @param rank uint8 parameter for allowedList gold/silver.
   * @param users address[] calldata user address array
   * @param amount uint16[] calldata amount for each user mint-cap
   *
   * Requirement
   * - onlyOwner can call
   */
  function setAllowedUserList(
    uint8 phase,
    uint8 rank,
    address[] calldata users,
    uint16[] calldata amount
  ) external onlyOwner {
    require(
      users.length == amount.length,
      "AllowedlistERC721:setAllowedUserList: users and amount list must be same length."
    );
    require(
      rank == 0 || rank == 1,
      "AllowedlistERC721:setAllowedUserList: rank is only 0 for gold, 1 for silver."
    );

    if (rank == 0) {
      for (uint256 i = 0; i < users.length; i++) {
        _allowedUserListGold[phase][users[i]] = amount[i];
      }
    } else if (rank == 1) {
      for (uint256 i = 0; i < users.length; i++) {
        _allowedUserListSilver[phase][users[i]] = amount[i];
      }
    }
  }

  /**
   * @dev Returns remaining token count
   *
   * @param phase uint8 Mint Sale phase(1~3)
   * @return amount of remaining token that user can mint for respective phase
   */
  function getRemainingToken(uint8 phase) public view returns (uint256) {
    return _tokenUpperBounds * (phase + 1) - _tokenIdCounter.current();
  }

  /**
   * @dev Returns price for respective rank
   *
   * @param rank uint8 rank
   * @return price for respective rank
   */
  function getPrice(uint8 rank) public view returns (uint256) {
    uint256 price;
    if (rank == 0) {
      // For gold
      price = _currentPriceGold;
    } else if (rank == 1) {
      // For silver
      price = _currentPriceSilver;
    } else {
      // For public
      price = _currentPricePublic;
    }

    return price;
  }

  /**
   * @dev Sets price of respective rank
   *
   * @param price uint256
   * @param rank uint8
   *
   * Requirement
   * - onlyOwner can call
   */
  function setPrice(uint256 price, uint8 rank) external onlyOwner {
    require(
      rank == 0 || rank == 1 || rank == 2,
      "AllowedlistERC721:setPrice: invalid rank"
    );

    if (rank == 0) {
      // For gold
      _currentPriceGold = price;
    } else if (rank == 1) {
      // For silver
      _currentPriceSilver = price;
    } else {
      // For public
      _currentPricePublic = price;
    }
  }

  /**
   * @dev Returns current phase
   */
  function getCurrentPhase() public view returns (uint256) {
    return _currentPhase;
  }

  /**
   * @dev Set current phase
   *
   * @param phase uint8
   *
   * Requirement
   * - onlyOwner can call
   */
  function setCurrentPhase(uint8 phase) external onlyOwner {
    _currentPhase = phase;
  }

  /**
   * @dev Returns current allowed rank
   *
   * @return uint256 current allowed rank
   */
  function getCurrentAllowedRank() public view returns (uint256) {
    return _currentAllowedRank;
  }

  /**
   * @dev Set current allowed rank
   *
   * @param rank uint8
   *
   * Requirement
   * - onlyOwner can call
   */
  function setCurrentAllowedRank(uint8 rank) external onlyOwner {
    _currentAllowedRank = rank;
  }

  /**
   * @dev Set withdraw account address
   *
   * @param to address
   *
   * Requirement
   * - onlyOwner can call
   */
  function setWithdrawAccount(address payable to) external onlyOwner {
    require(
      to != address(0),
      "AllowedlistERC721:setWithdrawAccount: to address can't be zero address"
    );

    _withdrawAccount = to;
  }

  /**
   * @dev Returns withdraw account address
   *
   * @return withdraw account address
   */
  function getWithdrawAccount() external view returns (address) {
    return _withdrawAccount;
  }

  /**
   * @dev Expose burn function
   *
   * @param tokenId uint256
   *
   * Requirements:
   * - token owner can burn own token.
   * - collection owner can burn token.
   *
   */
  function burn(uint256 tokenId) external {
    require(
      ownerOf(tokenId) == _msgSender() || _msgSender() == owner(),
      "AllowedlistERC721:burn: only token owner can burn."
    );
    super._burn(tokenId);
  }

  /**
   * @dev Returns token URI of respective tokenId
   *
   * @param tokenId uint256
   * @return string of token URI
   */
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
  }

  /**
   * @dev for opensea royalty on-chain enforcement tools
   * check following for getting more detail.
   * https://twitter.com/opensea/status/1590466349683576832?s=20
   * https://github.com/ProjectOpenSea/operator-filter-registry#filtered-addresses
   */

  function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}