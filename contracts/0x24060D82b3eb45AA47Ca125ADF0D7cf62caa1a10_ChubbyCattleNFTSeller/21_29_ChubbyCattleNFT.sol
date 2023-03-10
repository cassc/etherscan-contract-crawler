// SPDX-License-Identifier: Proprietary

pragma solidity ^0.8.13;

import "./Math.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { DefaultOperatorFilterer721, OperatorFilterer721 } from "./opensea/DefaultOperatorFilterer721.sol";
import "./Claimable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract ChubbyCattleNFT is 
  ERC721A,
  ERC2981,
  AccessControl,
  DefaultOperatorFilterer721,
  Ownable,
  Pausable,
  ReentrancyGuard,
  Claimable,
  MathFunctions
{

  using SafeMath for uint256;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");

  uint256 private tiers;

  uint256 public maxSupply;

  string private baseUri;

  string private contractUri;

  address private paymentAddress;

  uint256 public stage;

  mapping(uint256 => uint256) public tokenTier;

  mapping(uint256 => uint256) public tokenLock;

  mapping(uint256 => uint256) public tierPrice;

  mapping(uint256 => uint256) public tierSupply;

  mapping(uint256 => uint256) public tierLimit;

  mapping(uint256 => uint256) public tierMints;

  ProxyRegistry internal proxyRegistry;

  AggregatorV3Interface internal priceFeed;

  constructor(
    string memory _contractUri,
    string memory _baseUri,
    address _paymentAddress,
    address _royaltiesAddress,
    uint96 _feeNumerator,
    address _proxyRegistryAddress,
    address _priceFeedAddress
  )
    ERC721A("Chubby Cattle", "CHUBBYCATTLE") 
  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setDefaultRoyalty(_royaltiesAddress, _feeNumerator);

    contractUri = _contractUri;
    baseUri = _baseUri;
    paymentAddress = _paymentAddress;
    proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
    priceFeed = AggregatorV3Interface(_priceFeedAddress);

    maxSupply = 8888;

    tierPrice[0] = 25000000000;
    tierPrice[1] = 100000000000;
    tierPrice[2] = 0;

    tierSupply[0] = 4400;
    tierSupply[1] = 4400;
    tierSupply[2] = 88;

    tierLimit[0] = 1100;
    tierLimit[1] = 1100;
    tierLimit[2] = 88;

    tiers = 2; // 3 (0 inclusive)
  }

  /* ------------ User Operations ------------ */

  function mint(
    uint256 _tier,
    uint256 _quantity
  )
    external
    payable
    whenNotPaused
    nonReentrant
  {
    requireSaleOpen();
    requireValidTier(_tier, true);
    requireAvailableTokenSupply(_quantity);
    requireAvailableTierSupply(_tier, _quantity);

    uint256 price = tierPrice[_tier] * _quantity;

    if(ethToUsd(msg.value) < price) {
      revert InsufficientFee();
    }

    (bool paid, ) = paymentAddress.call{ value: msg.value }("");
    
    if(!paid) {
      revert UnableCollectFee();
    }

    _mint(_msgSender(), _tier, _quantity, 0);
  }

  /* ------------ Public Operations ------------ */

  function contractURI()
    public
    view
    returns (string memory)
  {
    return contractUri;
  }

  function tokenURI(
    uint256 _tokenId
  ) 
    public
    view
    override 
    returns (string memory)
  {
    if(!_exists(_tokenId)) {
      revert TokenDoesNotExist();
    }
    return string(abi.encodePacked(baseUri, _toString(_tokenId)));
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(AccessControl, ERC721A, ERC2981)
    returns (bool) 
  {
    return
      AccessControl.supportsInterface(interfaceId)
        || ERC2981.supportsInterface(interfaceId)
        || ERC721A.supportsInterface(interfaceId);
  }

  function tierPriceInEth(
    uint256 _tier
  )
    external
    view
    returns (uint256)
  {
    uint256 price = tierPrice[_tier];
    if(price == 0) {
      revert InvalidTier();
    }
    return usdToEth(price);
  }

  /* ------------ Management Operations ------------ */

  function setPaused(
    bool _paused
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if(_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setPaymentAddress(
    address _paymentAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    paymentAddress = _paymentAddress;
  }

  /**
  * @dev Withdraws the erc20 tokens or native coins from this contract.
  */
  function claimValues(address _token, address _to)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _claimValues(_token, _to);
  }

  /**
    * @dev Withdraw ERC721 or ERC1155 deposited for this contract
    * @param _token address of the claimed ERC721 token.
    * @param _to address of the tokens receiver.
    */
  function claimNFTs(address _token, uint256 _tokenId, address _to)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _claimNFTs(_token, _tokenId, _to);
  }

  function setContractUri(
    string calldata _contractUri
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    contractUri = _contractUri;
  }

  function setBaseUri(
    string calldata _baseUri
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    baseUri = _baseUri;
  }

  function setDefaultRoyalty(
    address _receiver,
    uint96 _feeNumerator
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function deleteDefaultRoyalty()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 _tokenId,
    address _receiver,
    uint96 _feeNumerator
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
  }

  function resetTokenRoyalty(
    uint256 tokenId
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _resetTokenRoyalty(tokenId);
  }

  function setStage(
    uint256 _stage
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    stage = _stage;
  }

  function setTierPrice(
    uint256 _tier,
    uint256 _price
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    requireValidTier(_tier, false);
    tierPrice[_tier] = _price;
  }

  function setTierLimit(
    uint256 _tier,
    uint256 _limit
  )
    external
    onlyRole(MANAGER_ROLE)
  {
    requireValidTier(_tier, false);
    if(_limit + tierMints[_tier] > tierSupply[_tier]) {
      revert InvalidSupply();
    }
    tierLimit[_tier] = _limit;
  }

  function setMaxSupply(
    uint256 _supply
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if(_supply < _totalMinted()) {
      revert InvalidSupply();
    }
    maxSupply = _supply;
  }

  function setTierSupply(
    uint256 _tier,
    uint256 _supply
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    requireValidTier(_tier, false);
    if(_supply < tierMints[_tier]) {
      revert InvalidSupply();
    }
    tierSupply[_tier] = _supply;
  }

  function unlockToken(
    uint256 _tokenId
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    tokenLock[_tokenId] = 0;
  }

  function setProxyRegistryAddress(
    address _proxyRegistryAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
  }

  function setPriceFeedAddress(
    address _priceFeedAddress
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    priceFeed = AggregatorV3Interface(_priceFeedAddress);
  }

  function setTiers(
    uint256 _tiers
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if(_tiers < tiers) {
      revert InvalidTier();
    }
    tiers = _tiers;
  }

  function mintTo(
    address _to,
    uint256 _tier,
    uint256 _quantity
  )
    external
    whenNotPaused
    onlyRole(MINTER_ROLE)
  {
    requireSaleOpen();
    requireValidTier(_tier, true);
    requireAvailableTokenSupply(_quantity);
    requireAvailableTierSupply(_tier, _quantity);
    
    _mint(_to, _tier, _quantity, 0);
  }

  function airdrop(
    address[] calldata _to,
    uint256 _tier,
    uint256 _quantity,
    uint256 _lock
  )
    external
    whenNotPaused
    onlyRole(MANAGER_ROLE)
  {
    requireValidTier(_tier, false);
    requireAvailableTokenSupply(_quantity * _to.length);
    requireAvailableTierSupply(_tier, _quantity * _to.length);
    
    for(uint256 i = 0; i < _to.length; i++) {
      _mint(_to[i], _tier, _quantity, _lock);
    }
  }

  function upgradeTier(
    uint256[] calldata _tokenIds,
    uint256 _tier
  )
    external
    whenNotPaused
    onlyRole(UPGRADE_ROLE)
  {
    requireValidTier(_tier, false);
    requireAvailableTierSupply(_tier, _tokenIds.length);

    uint256 _tokenId;
    for(uint256 i = 0; i < _tokenIds.length; i++) {
      _tokenId = _tokenIds[i];
      if(!_exists(_tokenId)) {
        revert TokenDoesNotExist();
      }
      uint256 currentTier = tokenTier[_tokenId];
    
      if(currentTier == _tier) {
        revert InvalidTier();
      }

      tierMints[currentTier] -= 1;
      tierMints[_tier] += 1;
      tierLimit[currentTier] += 1;
      tierLimit[_tier] -= 1;

      tokenTier[_tokenId] = _tier;

      emit TokenUpgraded(_tokenId, _tier);
    }
  }

  /* ------------ Internal Operations/Modifiers ------------ */
  function _mint(
    address _to,
    uint256 _tier,
    uint256 _quantity,
    uint256 _lock
  )
    internal
  {
    uint256 nextTokenId = _nextTokenId();

    _safeMint(_to, _quantity);

    _afterTokenMints(nextTokenId, _tier, _quantity, _lock);
  }

  function requireSaleOpen()
    view
    internal
  {
    if(stage == 0) {
      revert SaleIsClosed();
    }
  }

  function requireValidTier(
    uint256 _tier,
    bool _priceCheck
  )
    view
    internal
  {
    if(_tier > tiers || (_priceCheck && tierPrice[_tier] == 0)) {
      revert InvalidTier();
    }
  }

  function requireAvailableTokenSupply(
    uint256 _quantity
  )
    view
    internal
  {
    if(_totalMinted() + _quantity > maxSupply) {
      revert MaxSupplyExceeded();
    }
  }

  function requireAvailableTierSupply(
    uint256 _tier,
    uint256 _quantity
  )
    view
    internal
  {
    if(tierSupply[_tier] < tierMints[_tier] + _quantity) {
      revert MaxSupplyExceeded();
    }
    if(tierLimit[_tier] < _quantity) {
      revert MaxSupplyExceeded();
    }
  }

  function _startTokenId()
    internal
    pure
    override
    returns (uint256)
  {
    return 1;
  }

  function ethToUsd(
    uint256 amount
  )
    internal
    view
    returns (uint256)
  {
    return mulDiv(amount, getLatestPrice(), 10**(18));
  }

  function usdToEth(
    uint256 amount
  )
    internal
    view
    returns (uint256)
  {
    require(amount > 0, "Amount must be greater than 0");
    uint256 amountWithSlippage = mulDiv(amount, 102, 100);
    return mulDiv(amountWithSlippage, 10**(18), getLatestPrice());
  }

  /**
    * Returns the latest price and # of decimals to use
    */
  function getLatestPrice() 
    internal
    view
    virtual 
    returns (uint256)
  {
    int256 price;
    (, price, , , ) = priceFeed.latestRoundData();
    return uint256(price);
  }

  function _beforeTokenTransfers(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _quantity
  )
    internal
    override
  {
    if(_quantity == 1)
      if(address(0) != _from)
        if(tokenLock[_tokenId] > 0)
          if(block.timestamp < tokenLock[_tokenId]) {
      revert TokenIsLocked(tokenLock[_tokenId]);
    }
    super._beforeTokenTransfers(_from, _to, _tokenId, _quantity);
  }

  function _afterTokenMints(
    uint256 _tokenId,
    uint256 _tier,
    uint256 _quantity,
    uint256 _lock
  )
    internal
  {
    for(uint256 tokenId = _tokenId; tokenId < _tokenId + _quantity; tokenId++) {
      tokenTier[tokenId] = _tier;
      tokenLock[tokenId] = _lock;
    }
    tierMints[_tier] += _quantity;
    tierLimit[_tier] -= _quantity;
  }

  /* ------------ OpenSea Overrides --------------*/
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    payable
    override 
    onlyAllowedOperator(_from)
    whenNotPaused
  {
    super.transferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) 
    public
    payable
    override 
    onlyAllowedOperator(_from)
    whenNotPaused
  {
    super.safeTransferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    payable
    override
    onlyAllowedOperator(_from)
    whenNotPaused
  {
    super.safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function isApprovedForAll(
    address _owner, 
    address _operator
  )
    override
    public
    view
    returns (bool)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return super.isApprovedForAll(_owner, _operator);
  }

  /* ------------ Events ------------ */
  event TokenUpgraded(uint256 tokenId, uint256 tier);
  /* ----------- Errors ------------- */

  error InsufficientFee();
  error UnableCollectFee();
  error SaleIsClosed();
  error TokenDoesNotExist();
  error MaxSupplyExceeded();
  error TokenIsLocked(uint256 until);
  error InvalidTier();
  error InvalidSupply();
}