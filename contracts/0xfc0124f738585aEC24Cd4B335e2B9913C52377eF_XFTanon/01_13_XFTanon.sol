// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Shifter.sol";
import "./Interfaces/ElasticIERC20.sol";
import "./Interfaces/SafeEERC20.sol";
import "./Interfaces/IOracle.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XFTanon is Shifter, Pausable, Ownable {
  using SafeEERC20 for ElasticIERC20;
  ElasticIERC20 public immutable xft;
  ElasticIERC20 public immutable token;
  IOracle public oracle;
  uint256 public tokenPrice;
  address public xftPool;
  address public tokenPool;
  address public weth9;
  address public chainlinkFeed;
  uint256 public flexFeeThreshold;
  bool public oracleActive = true;
  event SetOracle(address oracle);
  event SimpleShift(uint256 amount, address recipient, uint256 output);
  event SetFlexFeeThreshold(uint256 _threshold);
  event SetChainlinkFeed(address _chainlink);
  event SetPool(address _pool);

  constructor(
    IVerifier _verifier,
    IHasher _hasher,
    IStorage _storage,
    uint256 _denomination,
    uint256 _ethDenomination,
    uint32 _merkleTreeHeight,
    ElasticIERC20 _xft,
    ElasticIERC20 _token,
    IOracle _oracle,
    address _xftPool,
    address _tokenPool,
    address _weth9,
    address _chainlinkFeed,
    uint256 _flexFeeThreshold
  ) Shifter(_verifier, _hasher, _storage, _denomination, _ethDenomination, _merkleTreeHeight) {
    if (_tokenPool == address(0x0) || _xftPool == address(0x0)) oracleActive = false;
    oracle = _oracle;
    xft = _xft;
    token = _token;
    xftPool = _xftPool;
    tokenPool = _tokenPool;
    weth9 = _weth9;
    chainlinkFeed = _chainlinkFeed;
    flexFeeThreshold = _flexFeeThreshold;
  }
  function pause() external onlyOwner {
    _pause();
  }
  function setOracle(IOracle _oracle) external onlyOwner whenNotPaused {
    oracle = _oracle;
    emit SetOracle(address(_oracle));
  }
  function setChainlinkFeed(address _chainlink) external onlyOwner whenNotPaused {
    chainlinkFeed = _chainlink;
    emit SetChainlinkFeed(_chainlink);
  }
  function setXFTPool(address _xftPool) external onlyOwner whenNotPaused {
    xftPool = _xftPool;
    emit SetPool(_xftPool);
  }
  function setTokenPool(address _tokenPool) external onlyOwner whenNotPaused {
    tokenPool = _tokenPool;
    emit SetPool(_tokenPool);
  }
  function setFlexFeeThreshold(uint256 _threshold) external onlyOwner whenNotPaused {
    flexFeeThreshold = _threshold;
    emit SetFlexFeeThreshold(flexFeeThreshold);
  }
  function simpleShift(uint256 _amount, address _recipient) public whenNotPaused {
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        uint256 _output = oracle.getCostSimpleShift(_amount, chainlinkFeed, xftPool, tokenPool);
        token.burn(msg.sender, _amount);
        xft.mint(_recipient, _output);
        emit SimpleShift(_amount, _recipient, _output);
  }
  function getDenomination() external view returns (uint256) {
    return denomination;
  }

  function getCost(uint256 _amount) public view returns (uint256) {
    if (!oracleActive) return _amount;
    return oracle.getCost(_amount, chainlinkFeed, xftPool);
  }

  function _processDeposit() internal override whenNotPaused {
    uint256 depositCost = getCost(denomination);
    require(xft.balanceOf(msg.sender) >= depositCost, "Insufficient Balance");
    xft.burn(msg.sender, depositCost);
  }

  function _processWithdraw (
    address payable _recipient,
    address payable _relayer,
    uint256 _fee, // Fee is in USD
    uint256 _refund
  ) internal override {
    require(msg.value == _refund, "Incorrect refund amount received by the contract");

    token.mint(_recipient, denomination - _fee);
    if (_fee > 0) {
      token.mint(_relayer, _fee);
    }

    if (_refund + ethDenomination > 0) {
      (bool success, ) = _recipient.call{ value: _refund + ethDenomination }("");
      if (!success) {
        // let's return back to the relayer
        _relayer.transfer(_refund + ethDenomination);
      }
    }
    
  }
}