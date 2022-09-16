// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './interfaces/ISmolGame.sol';
import './interfaces/ISmolGameFeeAdjuster.sol';

contract SmolGame is ISmolGame, Ownable {
  address payable public treasury;
  uint256 public serviceFeeUSDCents = 200; // $2
  uint8 public percentageWagerTowardsRewards = 0; // 0%

  address[] public walletsPlayed;
  mapping(address => bool) internal _walletsPlayedIndexed;

  ISmolGameFeeAdjuster internal _feeDiscounter;
  AggregatorV3Interface internal _feeUSDConverterFeed;

  uint256 public gameMinWagerAbsolute;
  uint256 public gameMaxWagerAbsolute;
  uint256 public gameMinWhaleWagerAbsolute = 500 * 10**18;
  uint256 public gameMaxWhaleWagerAbsolute;
  mapping(address => bool) public isGameWhale;

  constructor(address _clPriceFeed) {
    // https://docs.chain.link/docs/reference-contracts/
    // https://github.com/pcaversaccio/chainlink-price-feed/blob/main/README.md
    _feeUSDConverterFeed = AggregatorV3Interface(_clPriceFeed);
  }

  function _payServiceFee() internal {
    uint256 _serviceFeeWei = getFinalServiceFeeWei();
    if (_serviceFeeWei > 0) {
      require(msg.value >= _serviceFeeWei, 'not able to pay service fee');
      address payable _treasury = treasury == address(0)
        ? payable(owner())
        : treasury;
      (bool success, ) = _treasury.call{ value: msg.value }('');
      require(success, 'could not pay service fee');
    }
    if (!_walletsPlayedIndexed[msg.sender]) {
      walletsPlayed.push(msg.sender);
      _walletsPlayedIndexed[msg.sender] = true;
    }
  }

  function getFinalServiceFeeWei() public view override returns (uint256) {
    uint256 _serviceFeeWei = getBaseServiceFeeWei(serviceFeeUSDCents);
    if (address(_feeDiscounter) != address(0)) {
      _serviceFeeWei = _feeDiscounter.getFinalServiceFeeWei(_serviceFeeWei);
    }
    return _serviceFeeWei;
  }

  function getBaseServiceFeeWei(uint256 _costUSDCents)
    public
    view
    override
    returns (uint256)
  {
    // Creates a USD balance with 18 decimals
    uint256 paymentUSD18 = (10**18 * _costUSDCents) / 100;

    // adding back 18 decimals to get returned value in wei
    return (10**18 * paymentUSD18) / _getLatestETHPrice();
  }

  /**
   * Returns the latest ETH/USD price with returned value at 18 decimals
   * https://docs.chain.link/docs/get-the-latest-price/
   */
  function _getLatestETHPrice() internal view returns (uint256) {
    uint8 decimals = _feeUSDConverterFeed.decimals();
    (, int256 price, , , ) = _feeUSDConverterFeed.latestRoundData();
    return uint256(price) * (10**18 / 10**decimals);
  }

  function _enforceMinMaxWagerLogic(address _wagerer, uint256 _wagerAmount)
    internal
    view
  {
    if (isGameWhale[_wagerer]) {
      require(
        _wagerAmount >= gameMinWhaleWagerAbsolute,
        'does not meet minimum whale amount requirements'
      );
      require(
        gameMaxWhaleWagerAbsolute == 0 ||
          _wagerAmount <= gameMaxWhaleWagerAbsolute,
        'exceeds maximum whale amount requirements'
      );
    } else {
      require(
        _wagerAmount >= gameMinWagerAbsolute,
        'does not meet minimum amount requirements'
      );
      require(
        gameMaxWagerAbsolute == 0 || _wagerAmount <= gameMaxWagerAbsolute,
        'exceeds maximum amount requirements'
      );
    }
  }

  function getNumberWalletsPlayed() external view returns (uint256) {
    return walletsPlayed.length;
  }

  function getFeeDiscounter() external view returns (address) {
    return address(_feeDiscounter);
  }

  function setFeeDiscounter(address _discounter) external onlyOwner {
    _feeDiscounter = ISmolGameFeeAdjuster(_discounter);
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = payable(_treasury);
  }

  function setServiceFeeUSDCents(uint256 _cents) external onlyOwner {
    serviceFeeUSDCents = _cents;
  }

  function setPercentageWagerTowardsRewards(uint8 _percent) external onlyOwner {
    require(_percent <= 100, 'cannot be more than 100%');
    percentageWagerTowardsRewards = _percent;
  }

  function setGameMinWagerAbsolute(uint256 _amount) external onlyOwner {
    gameMinWagerAbsolute = _amount;
  }

  function setGameMaxWagerAbsolute(uint256 _amount) external onlyOwner {
    gameMaxWagerAbsolute = _amount;
  }

  function setGameMinWhaleWagerAbsolute(uint256 _amount) external onlyOwner {
    gameMinWhaleWagerAbsolute = _amount;
  }

  function setGameMaxWhaleWagerAbsolute(uint256 _amount) external onlyOwner {
    gameMaxWhaleWagerAbsolute = _amount;
  }

  function setIsGameWhale(address _user, bool _isWhale) external onlyOwner {
    isGameWhale[_user] = _isWhale;
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }
}