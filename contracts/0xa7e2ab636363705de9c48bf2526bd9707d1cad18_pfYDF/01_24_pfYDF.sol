// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/KeeperCompatible.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './IndexHandler.sol';

contract pfYDF is
  ERC721Enumerable,
  IndexHandler,
  KeeperCompatibleInterface,
  Ownable
{
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint256 private constant PERC_DEN = 100000;

  Counters.Counter internal _ids;
  string private baseTokenURI; // baseTokenURI can point to IPFS folder like https://ipfs.io/ipfs/{cid}/ while
  address public paymentAddress;
  address public royaltyAddress;

  // Royalties basis points (percentage using 2 decimals - 1000 = 100, 500 = 50, 0 = 0)
  uint256 private royaltyBasisPoints = 50; // 5%

  bool public enabled = true;

  // array of all the NFT token IDs owned by a user
  mapping(address => uint256[]) public allUserOwned;
  // the index in the token ID array at allUserOwned to save gas on operations
  mapping(uint256 => uint256) public ownedIndex;

  mapping(uint256 => uint256) public tokenMintedAt;
  mapping(uint256 => uint256) public tokenLastTransferred;

  address public treasury;
  mapping(address => bool) public liquidators;
  uint8 maxLiquidationsPerUpkeep = 25;

  IERC20 private _positionToken =
    IERC20(0x30dcBa0405004cF124045793E1933C798Af9E66a);

  uint16 public maxLeverage = 10; // 1x
  uint256 public minOpenTimeForProfit = 3 hours;
  uint256 public minPriceDiffForProfit = (PERC_DEN * 15) / 1000; // 1.5%
  uint256 public openPositionFeePositionSize = (PERC_DEN * 1) / 1000; // 0.1%
  uint256 public closePositionFeePositionSize = (PERC_DEN * 1) / 1000; // 0.1%
  uint256 public closePositionFeePerDurationUnit = 1 hours;
  uint256 public closePositionFeePerDuration = (PERC_DEN * 5) / 100000; // 0.005% / hour
  uint256 public totalFeesCollected;
  uint256 public totalAmountProfit;
  uint256 public totalAmountLoss;

  struct PositionIndexFeed {
    IndexFeed feed;
    uint16 phaseIdStart;
    uint80 roundIdStart;
    uint16 phaseIdSettle;
    uint80 roundIdSettle;
  }

  struct Position {
    PositionIndexFeed[] feeds;
    uint256 openTime;
    uint256 openFees;
    uint256 closeTime;
    uint256 closeFees;
    uint256 amountCollateral;
    uint256 amountPosition;
    bool isLong;
    uint16 leverage;
    uint256 indexPriceStart;
    uint256 indexPriceSettle;
    uint256 amountWon;
    uint256 amountLost;
  }

  // tokenId => Position
  mapping(uint256 => Position) public positions;
  // tokenId => address
  mapping(uint256 => address) public positionOpeners;
  // tokenId => address
  mapping(uint256 => address) public positionClosers;
  // tokenId[]
  uint256[] public allOpenPositions;
  // tokenId => allOpenPositions index
  mapping(uint256 => uint256) internal _openPositionsIndexed;

  event OpenPosition(
    uint256 indexed tokenId,
    address indexed user,
    uint256 indexPriceStart,
    uint256 positionCollateral
  );
  event SettlePosition(
    uint256 indexed tokenId,
    address indexed user,
    uint256 indexPriceStart,
    uint256 indexPriceSettle,
    uint256 amountWon,
    uint256 amountLost
  );
  event SetPaymentAddress(address indexed user);
  event SetRoyaltyAddress(address indexed user);
  event SetRoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);
  event SetBaseTokenURI(string indexed newUri);

  constructor(string memory _baseTokenURI)
    ERC721('Yieldification Perpetual Futures', 'pfYDF')
  {
    baseTokenURI = _baseTokenURI;
  }

  function getAllIndexes() external view returns (Index[] memory) {
    return indexes;
  }

  function openPosition(
    uint256 _indexInd,
    uint256 _collateral,
    uint16 _leverage, // 10 == 1x, 1000 == 100x
    bool _isLong
  ) external {
    require(enabled, 'opening positions is not enabled');
    require(_indexInd < indexes.length, 'invalid index provided');
    require(
      _positionToken.balanceOf(msg.sender) >= _collateral,
      'you can only open a position with up to your balance'
    );
    require(
      _leverage >= 10 && _leverage <= maxLeverage,
      'cannot exceed max allowable leverage'
    );

    _ids.increment();
    _positionToken.transferFrom(msg.sender, address(this), _collateral);
    uint256 _positionPreFee = (_collateral * _leverage) / 10;
    uint256 _openFee = (_positionPreFee * openPositionFeePositionSize) /
      PERC_DEN;
    uint256 _finalPositionCollateral = _collateral - _openFee;
    uint256 _finalPositionAmount = (_finalPositionCollateral * _leverage) / 10;
    totalFeesCollected += _openFee;

    Index memory _index = indexes[_indexInd];
    Position storage _newPosition = positions[_ids.current()];
    for (uint256 _i = 0; _i < _index.priceFeeds.length; _i++) {
      IndexFeed memory _feed = _index.priceFeeds[_i];
      (uint16 _phase, uint80 _round, ) = getLatestProxyInfo(_feed.proxy);
      _newPosition.feeds.push(
        PositionIndexFeed({
          feed: _index.priceFeeds[_i],
          phaseIdStart: _phase,
          roundIdStart: _round,
          phaseIdSettle: 0,
          roundIdSettle: 0
        })
      );
    }
    uint256 _openPrice = getIndexPriceFromIndex(_indexInd);
    positionOpeners[_ids.current()] = msg.sender;
    _newPosition.openTime = block.timestamp;
    _newPosition.openFees = _openFee;
    _newPosition.amountCollateral = _finalPositionCollateral;
    _newPosition.amountPosition = _finalPositionAmount;
    _newPosition.isLong = _isLong;
    _newPosition.leverage = _leverage;
    _newPosition.indexPriceStart = _openPrice;
    _newPosition.indexPriceSettle = 0;
    _newPosition.amountWon = 0;
    _newPosition.amountLost = 0;

    _safeMint(msg.sender, _ids.current());
    _addOpenPosition(_ids.current());
    tokenMintedAt[_ids.current()] = block.timestamp;

    emit OpenPosition(
      _ids.current(),
      msg.sender,
      _openPrice,
      _finalPositionCollateral
    );
  }

  function closePosition(uint256 _tokenId) external {
    _closePosition(_tokenId, false);
  }

  function _closePosition(uint256 _tokenId, bool _overrideCallerCheck)
    internal
  {
    Position storage _position = positions[_tokenId];
    address _user = ownerOf(_tokenId);

    require(
      _overrideCallerCheck || (msg.sender == _user || liquidators[msg.sender]),
      'must be position owner or liquidator'
    );
    require(_exists(_tokenId), 'position is already closed');

    // make sure position should be liquidated if this is a liquidator trying to close position
    if (liquidators[msg.sender] && msg.sender != _user) {
      require(
        shouldPositionLiquidate(_tokenId),
        'position is not in liquidation status'
      );
    }

    (
      uint256 _closingFeePosition,
      uint256 _closingFeeDurationTotal
    ) = getPositionCloseFees(_tokenId);
    uint256 _totalCloseFees = _closingFeePosition + _closingFeeDurationTotal;
    totalFeesCollected += _totalCloseFees;

    (
      uint256 _currentIndexPrice,
      uint256 _amountReturnToUser,
      uint256 _absolutePL,
      bool _isProfit,
      bool _canCloseInProfit
    ) = getIndexAndPLInfo(_tokenId);

    if (_isProfit) {
      if (_canCloseInProfit) {
        totalAmountProfit += _absolutePL;
      }
    } else {
      totalAmountLoss += _absolutePL;
    }

    // adjust amount returned based on closing fees incurred then transfer to position holder
    _amountReturnToUser = _totalCloseFees > _amountReturnToUser
      ? 0
      : _amountReturnToUser - _totalCloseFees;
    if (_amountReturnToUser > 0) {
      _positionToken.transfer(_user, _amountReturnToUser);
    }

    positionClosers[_tokenId] = _user;
    _position.closeTime = block.timestamp;
    _position.closeFees = _totalCloseFees;
    _position.indexPriceSettle = _currentIndexPrice;
    _position.amountWon = _isProfit && _canCloseInProfit ? _absolutePL : 0;
    _position.amountLost = _isProfit
      ? 0
      : _absolutePL > _position.amountCollateral
      ? _position.amountCollateral
      : _absolutePL;

    _burn(_tokenId);
    _removeOpenPosition(_tokenId);
    _closeIndividualFeeds(_tokenId);

    emit SettlePosition(
      _tokenId,
      _user,
      _position.indexPriceStart,
      _position.indexPriceSettle,
      _position.amountWon,
      _position.amountLost
    );
  }

  function getIndexAndPLInfo(uint256 _tokenId)
    public
    view
    returns (
      uint256,
      uint256,
      uint256,
      bool,
      bool
    )
  {
    Position memory _position = positions[_tokenId];
    bool _canCloseInProfit = true;
    uint256 _currentIndexPrice = getPositionIndexPrice(_tokenId);
    bool _priceIsHigherAtSettle = _currentIndexPrice >
      _position.indexPriceStart;
    uint256 _indexAbsDiffFromOpen = _priceIsHigherAtSettle
      ? _currentIndexPrice - _position.indexPriceStart
      : _position.indexPriceStart - _currentIndexPrice;
    uint256 _absolutePL = (_position.amountPosition * _indexAbsDiffFromOpen) /
      _position.indexPriceStart;
    bool _isProfit = _position.isLong
      ? _priceIsHigherAtSettle
      : !_priceIsHigherAtSettle;

    uint256 _amountReturnToUser = _position.amountCollateral;
    if (_isProfit) {
      bool _isOverMinChange = _absolutePL >=
        (_position.indexPriceStart * minPriceDiffForProfit) / PERC_DEN;
      bool _isPastMinTime = block.timestamp >=
        _position.openTime + minOpenTimeForProfit;
      if (_isOverMinChange || _isPastMinTime) {
        _amountReturnToUser += _absolutePL;
      } else {
        _canCloseInProfit = false;
      }
    } else {
      if (_absolutePL > _amountReturnToUser) {
        _amountReturnToUser = 0;
      } else {
        _amountReturnToUser -= _absolutePL;
      }
    }
    return (
      _currentIndexPrice,
      _amountReturnToUser,
      _absolutePL,
      _isProfit,
      _canCloseInProfit
    );
  }

  function getLiquidationPriceChange(uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    Position memory _position = positions[_tokenId];

    // 90% of exact liquidation which would mean 100% deliquency
    // NOTE: _position.leverage == 10 means 1x
    // Ex. price start == 100, leverage == 15 (1.5x)
    // (priceStart / (15 / 10)) * (9 / 10)
    // (priceStart * 10 / 15) * (9 / 10)
    // (priceStart / 15) * 9
    // (priceStart * 9) / 15
    return (_position.indexPriceStart * 9) / _position.leverage;
  }

  function shouldPositionLiquidate(uint256 _tokenId)
    public
    view
    returns (bool)
  {
    Position memory _position = positions[_tokenId];
    uint256 _priceChangeForLiquidation = getLiquidationPriceChange(_tokenId);
    (uint256 _closingFeeMain, uint256 _closingFeeTime) = getPositionCloseFees(
      _tokenId
    );
    (
      uint256 _currentIndexPrice,
      uint256 _amountReturnToUser,
      uint256 _absolutePL,
      bool _isProfit,

    ) = getIndexAndPLInfo(_tokenId);
    uint256 _indexPriceDelinquencyPrice = _position.isLong
      ? _position.indexPriceStart - _priceChangeForLiquidation
      : _position.indexPriceStart + _priceChangeForLiquidation;
    bool _priceInLiquidation = _position.isLong
      ? _currentIndexPrice <= _indexPriceDelinquencyPrice
      : _currentIndexPrice >= _indexPriceDelinquencyPrice;
    bool _feesExceedReturn = !_isProfit &&
      _absolutePL + _closingFeeMain + _closingFeeTime >= _amountReturnToUser;
    return _priceInLiquidation || _feesExceedReturn;
  }

  function getPositionIndexPrice(uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    Position memory _position = positions[_tokenId];
    address[] memory _proxies = new address[](_position.feeds.length);
    uint8[] memory _weights = new uint8[](_position.feeds.length);
    uint256 _totalWeight;
    for (uint256 _i = 0; _i < _position.feeds.length; _i++) {
      _proxies[_i] = _position.feeds[_i].feed.proxy;
      _weights[_i] = _position.feeds[_i].feed.weight;
      _totalWeight += _position.feeds[_i].feed.weight;
    }
    return getIndexPriceFromFeeds(_proxies, _weights, _totalWeight);
  }

  function getPositionCloseFees(uint256 _tokenId)
    public
    view
    returns (uint256, uint256)
  {
    Position memory _position = positions[_tokenId];
    uint256 _closingFeePosition = (_position.amountPosition *
      closePositionFeePositionSize) / PERC_DEN;
    uint256 _closingFeeDurationPerUnit = (_position.amountPosition *
      closePositionFeePerDuration) / PERC_DEN;
    uint256 _closingFeeDurationTotal = (_closingFeeDurationPerUnit *
      (block.timestamp - _position.openTime)) / closePositionFeePerDurationUnit;
    return (_closingFeePosition, _closingFeeDurationTotal);
  }

  function getPositionIndexProxies(uint256 _tokenId)
    external
    view
    returns (address[] memory)
  {
    Position memory _pos = positions[_tokenId];
    PositionIndexFeed[] memory _posFeeds = _pos.feeds;
    address[] memory _proxies = new address[](_pos.feeds.length);
    for (uint256 _i = 0; _i < _posFeeds.length; _i++) {
      _proxies[_i] = _posFeeds[_i].feed.proxy;
    }
    return _proxies;
  }

  function getPositionToken() external view returns (address) {
    return address(_positionToken);
  }

  function setPositionToken(address _token) external onlyOwner {
    require(
      allOpenPositions.length == 0,
      'cannot change position token with open positions'
    );
    _positionToken = IERC20(_token);
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  // 10 == 1x, 1000 == 100x, etc.
  function setMaxLeverage(uint16 _max) external onlyOwner {
    require(_max <= 2000, 'cannot be more than 200x');
    maxLeverage = _max;
  }

  function setMinOpenTimeForProfit(uint256 _seconds) external onlyOwner {
    require(_seconds <= 1 days, 'cannot be more than 1 days');
    minOpenTimeForProfit = _seconds;
  }

  function setMinPriceDiffForProfit(uint256 _percentage) external onlyOwner {
    require(_percentage < (PERC_DEN * 3) / 100, 'cannot be more than 3%');
    minPriceDiffForProfit = _percentage;
  }

  function setOpenPositionFeePositionSize(uint256 _percentage)
    external
    onlyOwner
  {
    require(_percentage < (PERC_DEN * 10) / 100, 'cannot be more than 10%');
    openPositionFeePositionSize = _percentage;
  }

  function setClosePositionFeePositionSize(uint256 _percentage)
    external
    onlyOwner
  {
    require(_percentage < (PERC_DEN * 10) / 100, 'cannot be more than 10%');
    closePositionFeePositionSize = _percentage;
  }

  function setClosePositionFeePerDurationUnit(uint256 _seconds)
    external
    onlyOwner
  {
    require(
      _seconds >= 10 minutes,
      'unit time frame cannot be less than 10 min'
    );
    closePositionFeePerDurationUnit = _seconds;
  }

  function setClosePositionFeePerDuration(uint256 _percentage)
    external
    onlyOwner
  {
    require(_percentage < (PERC_DEN * 1) / 100, 'cannot be more than 1%');
    closePositionFeePerDuration = _percentage;
  }

  function addLiquidator(address _wallet) external onlyOwner {
    require(!liquidators[_wallet], 'must not be liquidator to add them');
    liquidators[_wallet] = true;
  }

  function removeLiquidator(address _wallet) external onlyOwner {
    require(liquidators[_wallet], 'must be liquidator to remove them');
    delete liquidators[_wallet];
  }

  function setMaxLiquidationsPerUpkeep(uint8 _max) external onlyOwner {
    require(_max > 0, 'must allow liquidating at least 1');
    maxLiquidationsPerUpkeep = _max;
  }

  function addIndex(
    string memory _name,
    address[] memory _proxies,
    uint8[] memory _weights
  ) external onlyOwner {
    require(
      _proxies.length > 0 && _proxies.length == _weights.length,
      'must contain a weight for each proxy'
    );
    Index storage _newIndex = indexes.push();
    _newIndex.name = _name;
    for (uint256 _i = 0; _i < _proxies.length; _i++) {
      address _proxy = _proxies[_i];
      (, , uint256 _priceUSD) = getLatestProxyInfo(_proxy);
      require(_priceUSD > 0, 'invalid proxy');

      _newIndex.weightsTotal += _weights[_i];
      _newIndex.priceFeeds.push(
        IndexFeed({ proxy: _proxy, weight: _weights[_i] })
      );
    }
  }

  function removeIndex(uint256 _index) external onlyOwner {
    indexes[_index] = indexes[indexes.length - 1];
    indexes.pop();
  }

  // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 1000);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(_tokenId), 'token does not exist');
    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), '.json'));
  }

  // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), 'contract.json'));
  }

  // Override supportsInterface - See {IERC165-supportsInterface}
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(_interfaceId);
  }

  function getLastMintedTokenId() external view returns (uint256) {
    return _ids.current();
  }

  function isTokenMinted(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  function setPaymentAddress(address _address) external onlyOwner {
    paymentAddress = _address;
    emit SetPaymentAddress(_address);
  }

  function setRoyaltyAddress(address _address) external onlyOwner {
    royaltyAddress = _address;
    emit SetRoyaltyAddress(_address);
  }

  function setRoyaltyBasisPoints(uint256 _points) external onlyOwner {
    royaltyBasisPoints = _points;
    emit SetRoyaltyBasisPoints(_points);
  }

  function setBaseURI(string memory _uri) external onlyOwner {
    baseTokenURI = _uri;
    emit SetBaseTokenURI(_uri);
  }

  function setEnabled(bool _enabled) external onlyOwner {
    enabled = _enabled;
  }

  function processFees(uint256 _amount) external onlyOwner {
    _positionToken.transfer(address(_positionToken), _amount);
  }

  function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
    IERC20 _contract = IERC20(_token);
    _amount = _amount == 0 ? _contract.balanceOf(address(this)) : _amount;
    require(_amount > 0, 'needs balance to withdraw');
    _contract.transfer(owner(), _amount);
  }

  function getAllUserOwned(address _user)
    external
    view
    returns (uint256[] memory)
  {
    return allUserOwned[_user];
  }

  // https://docs.chain.link/docs/chainlink-keepers/compatible-contracts/
  function checkUpkeep(
    bytes calldata /* checkData */
  )
    external
    view
    override
    returns (
      bool upkeepNeeded,
      bytes memory /* performData */
    )
  {
    for (uint256 _i = 0; _i < allOpenPositions.length; _i++) {
      uint256 _tokenId = allOpenPositions[_i];
      if (shouldPositionLiquidate(_tokenId)) {
        upkeepNeeded = true;
        break;
      }
    }
  }

  // https://docs.chain.link/docs/chainlink-keepers/compatible-contracts/
  function performUpkeep(
    bytes calldata /* performData */
  ) external override {
    uint8 _liquidations;
    for (uint256 _i = 0; _i < allOpenPositions.length; _i++) {
      uint256 _tokenId = allOpenPositions[_i];
      if (shouldPositionLiquidate(_tokenId)) {
        _closePosition(_tokenId, true);
        _liquidations++;
        if (_liquidations >= maxLiquidationsPerUpkeep) {
          break;
        }
      }
    }
  }

  function _addOpenPosition(uint256 _tokenId) internal {
    _openPositionsIndexed[_tokenId] = allOpenPositions.length;
    allOpenPositions.push(_tokenId);
  }

  function _removeOpenPosition(uint256 _tokenId) internal {
    uint256 _allPositionsIndex = _openPositionsIndexed[_tokenId];
    uint256 _tokenIdMoving = allOpenPositions[allOpenPositions.length - 1];
    delete _openPositionsIndexed[_tokenId];
    _openPositionsIndexed[_tokenIdMoving] = _allPositionsIndex;
    allOpenPositions[_allPositionsIndex] = _tokenIdMoving;
    allOpenPositions.pop();
  }

  function _closeIndividualFeeds(uint256 _tokenId) internal {
    Position storage _position = positions[_tokenId];
    // update settle phase and round data for all proxies that make up the index
    for (uint256 _i = 0; _i < _position.feeds.length; _i++) {
      PositionIndexFeed storage _feed = _position.feeds[_i];
      (uint16 _phase, uint80 _round, ) = getLatestProxyInfo(_feed.feed.proxy);
      _feed.phaseIdSettle = _phase;
      _feed.roundIdSettle = _round;
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721Enumerable) {
    tokenLastTransferred[_tokenId] = block.timestamp;

    super._beforeTokenTransfer(_from, _to, _tokenId);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721) {
    // if from == address(0), token is being minted
    if (_from != address(0)) {
      uint256 _currIndex = ownedIndex[_tokenId];
      uint256 _tokenIdMovingIndices = allUserOwned[_from][
        allUserOwned[_from].length - 1
      ];
      allUserOwned[_from][_currIndex] = allUserOwned[_from][
        allUserOwned[_from].length - 1
      ];
      allUserOwned[_from].pop();
      ownedIndex[_tokenIdMovingIndices] = _currIndex;
    }

    // if to == address(0), token is being burned
    if (_to != address(0)) {
      ownedIndex[_tokenId] = allUserOwned[_to].length;
      allUserOwned[_to].push(_tokenId);
    }

    super._afterTokenTransfer(_from, _to, _tokenId);
  }
}