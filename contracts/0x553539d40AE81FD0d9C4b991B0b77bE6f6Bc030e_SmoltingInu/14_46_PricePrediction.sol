// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './interfaces/AggregatorProxy.sol';
import './interfaces/ISmoltingInu.sol';
import './SmolGame.sol';

/**
 * @title PricePrediction
 * @dev Predict if price goes up or down over a time period
 */
contract PricePrediction is SmolGame {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  struct PredictionConfig {
    uint256 timePeriodSeconds;
    uint256 payoutPercentage;
  }
  struct Prediction {
    address priceFeedProxy;
    uint256 configTimePeriodSeconds;
    uint256 configPayoutPercentage;
    bool isLong; // true if price should go higher, otherwise price expected to go lower
    uint256 amountWagered;
    uint16 startPhaseId;
    uint80 startRoundId;
    uint16 endPhaseId; // not set until prediction is settled
    uint80 endRoundId; // not set until prediction is settled
    bool isDraw; // not set until prediction is settled
    bool isWinner; // not set until prediction is settled
  }

  uint256 public minBalancePerc = (PERCENT_DENOMENATOR * 35) / 100; // 35% user's balance
  uint256 public minWagerAbsolute;
  uint256 public maxWagerAbsolute;
  uint8 public maxOpenPredictions = 20;

  uint80 public roundIdStartOffset = 1;

  address[] public validPriceFeedProxies;
  mapping(address => bool) public isValidPriceFeedProxy;

  PredictionConfig[] public predictionOptions;

  address public smol = 0x553539d40AE81FD0d9C4b991B0b77bE6f6Bc030e;
  ISmoltingInu private smolContract = ISmoltingInu(smol);

  uint256 public totalPredictionsMade;
  uint256 public totalPredictionsWon;
  uint256 public totalPredictionsLost;
  uint256 public totalPredictionsDraw;
  uint256 public totalPredictionsAmountWon;
  uint256 public totalPredictionsAmountLost;
  // user => predictions[]
  mapping(address => Prediction[]) public predictions;
  mapping(address => uint256[]) public openPredictions;
  mapping(address => uint256) public predictionsUserWon;
  mapping(address => uint256) public predictionsUserLost;
  mapping(address => uint256) public predictionsUserDraw;
  mapping(address => uint256) public predictionsAmountUserWon;
  mapping(address => uint256) public predictionsAmountUserLost;

  event Predict(
    address indexed user,
    address indexed proxy,
    uint16 startPhase,
    uint80 startRound,
    uint256 amountWager
  );
  event Settle(
    address indexed user,
    address indexed proxy,
    bool isWinner,
    bool isDraw,
    uint256 amountWon
  );

  constructor(address _nativeUSDFeed) SmolGame(_nativeUSDFeed) {}

  function getAllValidPriceFeeds() external view returns (address[] memory) {
    return validPriceFeedProxies;
  }

  function getNumberUserPredictions(address _user)
    external
    view
    returns (uint256)
  {
    return predictions[_user].length;
  }

  function getOpenUserPredictions(address _user)
    external
    view
    returns (Prediction[] memory)
  {
    uint256[] memory _indexes = openPredictions[_user];
    Prediction[] memory _open = new Prediction[](_indexes.length);
    for (uint256 i = 0; i < _indexes.length; i++) {
      _open[i] = predictions[_user][_indexes[i]];
    }
    return _open;
  }

  function getLatestUserPrediction(address _user)
    external
    view
    returns (Prediction memory)
  {
    require(predictions[_user].length > 0, 'no predictions for user');
    return predictions[_user][predictions[_user].length - 1];
  }

  /**
   * Returns the latest price with returned value from a price feed proxy at 18 decimals
   * more info (proxy vs agg) here:
   * https://stackoverflow.com/questions/70377502/what-is-the-best-way-to-access-historical-price-data-from-chainlink-on-a-token-i/70389049#70389049
   *
   * https://docs.chain.link/docs/get-the-latest-price/
   */
  function getRoundInfoAndPriceUSD(address _proxy)
    public
    view
    returns (
      uint16,
      uint80,
      uint256
    )
  {
    // https://docs.chain.link/docs/reference-contracts/
    // https://github.com/pcaversaccio/chainlink-price-feed/blob/main/README.md
    AggregatorProxy priceFeed = AggregatorProxy(_proxy);
    uint16 phaseId = priceFeed.phaseId();
    uint8 decimals = priceFeed.decimals();
    (uint80 proxyRoundId, int256 price, , , ) = priceFeed.latestRoundData();
    return (phaseId, proxyRoundId, uint256(price) * (10**18 / 10**decimals));
  }

  function getPriceUSDAtRound(address _proxy, uint80 _roundId)
    public
    view
    returns (uint256)
  {
    AggregatorProxy priceFeed = AggregatorProxy(_proxy);
    uint8 decimals = priceFeed.decimals();
    (, int256 price, , , ) = priceFeed.getRoundData(_roundId);
    return uint256(price) * (10**18 / 10**decimals);
  }

  // https://docs.chain.link/docs/historical-price-data/
  function getHistoricalPriceFromAggregatorInfo(
    address _proxy,
    uint16 _phaseId,
    uint80 _aggRoundId,
    bool _requireCompletion
  )
    public
    view
    returns (
      uint80,
      uint256,
      uint256,
      uint80
    )
  {
    AggregatorProxy proxy = AggregatorProxy(_proxy);
    uint80 _proxyRoundId = _getProxyRoundId(_phaseId, _aggRoundId);
    (
      uint80 roundId,
      int256 price,
      ,
      uint256 timestamp,
      uint80 answeredInRound
    ) = proxy.getRoundData(_proxyRoundId);
    uint8 decimals = proxy.decimals();
    if (_requireCompletion) {
      require(timestamp > 0, 'Round not complete');
    }
    return (
      roundId,
      uint256(price) * (10**18 / 10**decimals),
      timestamp,
      answeredInRound
    );
  }

  // _isLong: if true, user wants price to go up, else price should go down
  function predict(
    uint256 _configIndex,
    address _priceFeedProxy,
    uint256 _amountWager,
    bool _isLong
  ) external payable {
    require(
      isValidPriceFeedProxy[_priceFeedProxy],
      'not a valid price feed to predict'
    );
    require(
      _amountWager >=
        (smolContract.balanceOf(msg.sender) * minBalancePerc) /
          PERCENT_DENOMENATOR,
      'did not wager enough of balance'
    );
    require(_amountWager >= minWagerAbsolute, 'did not wager at least minimum');
    require(
      maxWagerAbsolute == 0 || _amountWager <= maxWagerAbsolute,
      'wagering more than maximum'
    );

    address _user = msg.sender;
    require(
      openPredictions[_user].length <= maxOpenPredictions,
      'cannot exceed max open predictions at a time'
    );

    if (predictions[_user].length > 0) {
      Prediction memory _openPrediction = predictions[_user][
        predictions[_user].length - 1
      ];
      require(
        _openPrediction.endRoundId > 0,
        'there is an open prediction you must settle before creating a new one'
      );
    }

    _enforceMinMaxWagerLogic(msg.sender, _amountWager);
    smolContract.transferFrom(msg.sender, address(this), _amountWager);
    smolContract.addPlayThrough(
      msg.sender,
      _amountWager,
      percentageWagerTowardsRewards
    );
    (uint16 _phaseId, uint80 _proxyRoundId, ) = getRoundInfoAndPriceUSD(
      _priceFeedProxy
    );
    (, uint64 _aggRoundId) = getAggregatorPhaseAndRoundId(_proxyRoundId);
    uint80 _startRoundId = _getProxyRoundId(
      _phaseId,
      _aggRoundId + roundIdStartOffset
    );

    PredictionConfig memory _config = predictionOptions[_configIndex];
    require(_config.timePeriodSeconds > 0, 'invalid config provided');

    Prediction memory _newPrediction = Prediction({
      priceFeedProxy: _priceFeedProxy,
      configTimePeriodSeconds: _config.timePeriodSeconds,
      configPayoutPercentage: _config.payoutPercentage,
      isLong: _isLong,
      amountWagered: _amountWager,
      startPhaseId: _phaseId,
      startRoundId: _startRoundId,
      endPhaseId: 0,
      endRoundId: 0,
      isDraw: false,
      isWinner: false
    });
    openPredictions[_user].push(predictions[_user].length);
    predictions[_user].push(_newPrediction);

    totalPredictionsMade++;
    _payServiceFee();
    emit Predict(
      msg.sender,
      _priceFeedProxy,
      _phaseId,
      _startRoundId,
      _amountWager
    );
  }

  // in order to settle an open prediction, the settling executor must know the
  // user with the open prediction they are settling and the round ID that corresponds
  // to the time it should be settled.
  function settlePrediction(
    address _user,
    uint256 _openPredIndex,
    uint16 _answeredPhaseId,
    uint80 _answeredAggRoundId
  ) public {
    _user = _user == address(0) ? msg.sender : _user;
    require(predictions[_user].length > 0, 'no predictions created yet');
    uint256 _predIndex = openPredictions[_user][_openPredIndex];
    Prediction storage _openPrediction = predictions[_user][_predIndex];
    require(
      _openPrediction.priceFeedProxy != address(0),
      'no predictions created yet to settle'
    );
    require(
      _openPrediction.endRoundId == 0,
      'latest prediction already settled'
    );

    (uint256 priceStart, uint80 roundActual) = _validateAndGetPriceInfo(
      _openPrediction,
      _answeredPhaseId,
      _answeredAggRoundId
    );

    uint256 settlePrice = getPriceUSDAtRound(
      _openPrediction.priceFeedProxy,
      roundActual
    );

    bool _isDraw = settlePrice == priceStart;
    bool _isWinner = false;
    if (!_isDraw) {
      _isWinner = _openPrediction.isLong
        ? settlePrice > priceStart
        : settlePrice < priceStart;
    }

    _openPrediction.endPhaseId = _answeredPhaseId;
    _openPrediction.endRoundId = roundActual;
    _openPrediction.isDraw = _isDraw;
    _openPrediction.isWinner = _isWinner;

    uint256 _finalWinAmount = _isWinner
      ? (_openPrediction.amountWagered *
        _openPrediction.configPayoutPercentage) / PERCENT_DENOMENATOR
      : 0;

    if (_isDraw || _isWinner) {
      smolContract.transfer(_user, _openPrediction.amountWagered);
      if (_finalWinAmount > 0) {
        smolContract.gameMint(_user, _finalWinAmount);
      }
    } else {
      smolContract.gameBurn(address(this), _openPrediction.amountWagered);
    }

    openPredictions[_user][_openPredIndex] = openPredictions[_user][
      openPredictions[_user].length - 1
    ];
    openPredictions[_user].pop();
    _updateAnalytics(
      _user,
      _isDraw,
      _isWinner,
      _openPrediction.amountWagered,
      _finalWinAmount
    );

    emit Settle(
      _user,
      _openPrediction.priceFeedProxy,
      _isWinner,
      _isDraw,
      _finalWinAmount
    );
  }

  function settlePredictionShortCircuitLoss(uint256 _openPredIndex) external {
    require(predictions[msg.sender].length > 0, 'no predictions created yet');
    uint256 _predIndex = openPredictions[msg.sender][_openPredIndex];
    Prediction storage _prediction = predictions[msg.sender][_predIndex];
    require(
      _prediction.priceFeedProxy != address(0),
      'no predictions created yet to settle'
    );
    require(_prediction.endRoundId == 0, 'prediction already settled');
    // just set the end phase and round to the start if we short circuit here
    _prediction.endPhaseId = _prediction.startPhaseId;
    _prediction.endRoundId = _prediction.startRoundId;
    smolContract.gameBurn(address(this), _prediction.amountWagered);
    openPredictions[msg.sender][_openPredIndex] = openPredictions[msg.sender][
      openPredictions[msg.sender].length - 1
    ];
    openPredictions[msg.sender].pop();
    _updateAnalytics(msg.sender, false, false, _prediction.amountWagered, 0);
    emit Settle(msg.sender, _prediction.priceFeedProxy, false, false, 0);
  }

  function settleMultiplePredictions(
    address[] memory _users,
    uint256[] memory _openIndexes,
    uint16[] memory _phaseIds,
    uint80[] memory _aggRoundIds
  ) external {
    require(
      _users.length == _openIndexes.length,
      'need to be same size arrays'
    );
    require(_users.length == _phaseIds.length, 'need to be same size arrays');
    require(
      _users.length == _aggRoundIds.length,
      'need to be same size arrays'
    );
    for (uint256 i = 0; i < _users.length; i++) {
      settlePrediction(
        _users[i],
        _openIndexes[i],
        _phaseIds[i],
        _aggRoundIds[i]
      );
    }
  }

  function _validateAndGetPriceInfo(
    Prediction memory _openPrediction,
    uint16 _answeredPhaseId,
    uint80 _answeredAggRoundId
  ) internal view returns (uint256, uint80) {
    (
      ,
      uint256 priceStart,
      uint256 timestampStart,
      uint80 answeredInRoundIdStart
    ) = getHistoricalPriceFromAggregatorInfo(
        _openPrediction.priceFeedProxy,
        _openPrediction.startPhaseId,
        _openPrediction.startRoundId,
        true
      );
    require(
      answeredInRoundIdStart > 0 && timestampStart > 0,
      'start round is not fresh'
    );
    (
      uint80 roundActual,
      ,
      uint256 timestampActual,

    ) = getHistoricalPriceFromAggregatorInfo(
        _openPrediction.priceFeedProxy,
        _answeredPhaseId,
        _answeredAggRoundId,
        true
      );
    (, , uint256 timestampAfter, ) = getHistoricalPriceFromAggregatorInfo(
      _openPrediction.priceFeedProxy,
      _answeredPhaseId,
      _answeredAggRoundId + 1,
      false
    );
    require(
      roundActual > 0 && timestampActual > 0,
      'actual round not finished yet'
    );
    require(
      timestampActual <=
        timestampStart + _openPrediction.configTimePeriodSeconds,
      'actual round was completed after our time period'
    );
    require(
      timestampAfter >
        timestampStart + _openPrediction.configTimePeriodSeconds ||
        (timestampAfter == 0 &&
          block.timestamp >
          timestampStart + _openPrediction.configTimePeriodSeconds),
      'after round was completed before our time period'
    );
    return (priceStart, roundActual);
  }

  function _updateAnalytics(
    address _user,
    bool _isDraw,
    bool _isWinner,
    uint256 _amountWagered,
    uint256 _finalWinAmount
  ) internal {
    totalPredictionsWon += _isWinner ? 1 : 0;
    predictionsUserWon[_user] += _isWinner ? 1 : 0;
    totalPredictionsLost += !_isWinner && !_isDraw ? 1 : 0;
    predictionsUserLost[_user] += !_isWinner && !_isDraw ? 1 : 0;
    totalPredictionsDraw += _isDraw ? 1 : 0;
    predictionsUserDraw[_user] += _isDraw ? 1 : 0;
    totalPredictionsAmountWon += _isWinner ? _finalWinAmount : 0;
    predictionsAmountUserWon[_user] += _isWinner ? _finalWinAmount : 0;
    totalPredictionsAmountLost += !_isWinner && !_isDraw ? _amountWagered : 0;
    predictionsAmountUserLost[_user] += !_isWinner && !_isDraw
      ? _amountWagered
      : 0;
  }

  function _getProxyRoundId(uint16 _phaseId, uint80 _aggRoundId)
    internal
    pure
    returns (uint80)
  {
    return uint80((uint256(_phaseId) << 64) | _aggRoundId);
  }

  function getAggregatorPhaseAndRoundId(uint256 _proxyRoundId)
    public
    pure
    returns (uint16, uint64)
  {
    uint16 phaseId = uint16(_proxyRoundId >> 64);
    uint64 aggregatorRoundId = uint64(_proxyRoundId);
    return (phaseId, aggregatorRoundId);
  }

  function getAllPredictionOptions()
    external
    view
    returns (PredictionConfig[] memory)
  {
    return predictionOptions;
  }

  function setMinBalancePerc(uint256 _perc) external onlyOwner {
    require(_perc <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    minBalancePerc = _perc;
  }

  function setMinWagerAbsolute(uint256 _amount) external onlyOwner {
    minWagerAbsolute = _amount;
  }

  function setMaxWagerAbsolute(uint256 _amount) external onlyOwner {
    maxWagerAbsolute = _amount;
  }

  function setMaxOpenPredictions(uint8 _amount) external onlyOwner {
    maxOpenPredictions = _amount;
  }

  function addPredictionOption(uint256 _seconds, uint256 _percentage)
    external
    onlyOwner
  {
    require(_seconds > 60, 'must be longer than 60 seconds');
    require(_percentage <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    predictionOptions.push(
      PredictionConfig({
        timePeriodSeconds: _seconds,
        payoutPercentage: _percentage
      })
    );
  }

  function removePredictionOption(uint256 _index) external onlyOwner {
    predictionOptions[_index] = predictionOptions[predictionOptions.length - 1];
    predictionOptions.pop();
  }

  function updatePredictionOption(
    uint256 _index,
    uint256 _seconds,
    uint256 _percentage
  ) external onlyOwner {
    PredictionConfig storage _pred = predictionOptions[_index];
    _pred.timePeriodSeconds = _seconds;
    _pred.payoutPercentage = _percentage;
  }

  function setWagerToken(address _token) external onlyOwner {
    smol = _token;
    smolContract = ISmoltingInu(_token);
  }

  function setRoundIdStartOffset(uint80 _offset) external onlyOwner {
    require(_offset > 0, 'must be at least an offset of 1 round');
    roundIdStartOffset = _offset;
  }

  function addPriceFeed(address _proxy) external onlyOwner {
    for (uint256 i = 0; i < validPriceFeedProxies.length; i++) {
      if (validPriceFeedProxies[i] == _proxy) {
        require(false, 'price feed already in feed list');
      }
    }
    isValidPriceFeedProxy[_proxy] = true;
    validPriceFeedProxies.push(_proxy);
  }

  function removePriceFeed(address _proxy) external onlyOwner {
    for (uint256 i = 0; i < validPriceFeedProxies.length; i++) {
      if (validPriceFeedProxies[i] == _proxy) {
        delete isValidPriceFeedProxy[_proxy];
        validPriceFeedProxies[i] = validPriceFeedProxies[
          validPriceFeedProxies.length - 1
        ];
        validPriceFeedProxies.pop();
        break;
      }
    }
  }
}