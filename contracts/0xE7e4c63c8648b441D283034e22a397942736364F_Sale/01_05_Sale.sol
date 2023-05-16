// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Sale is Ownable {
    IERC20 private immutable _KUMA;
    AggregatorV3Interface private immutable _PRICEFEED;

    uint256 public rate;
    uint256 public awaitingOwners;
    bool public isStarted;
    bool public isWithdrawable;

    mapping (address => bool) private _whitelist;
    mapping (address => uint256) private _availableToWithdraw; 

    constructor(address _kuma, address _pricefeed, uint256 _cost) {
        _KUMA = IERC20(_kuma);
        rate = _cost;
        // 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        _PRICEFEED = AggregatorV3Interface(_pricefeed);
    }

    receive() external payable {
        _buy();
    }

    function _buy() private {
        if (!isStarted || !_whitelist[msg.sender]) {

        }
        else {
        uint256 _wei = msg.value;
        uint256 _usd = _getConversionRate(_wei);
        uint256 _tokensAmount = _usd * rate;
        uint256 _amountToSendNow = _calculateStartedPercent(_tokensAmount);
        _availableToWithdraw[msg.sender] += _tokensAmount - _amountToSendNow;
        awaitingOwners += _tokensAmount - _amountToSendNow;
        _KUMA.transfer(msg.sender, _amountToSendNow);
        }
    }

    function withdraw() external {
        require(isWithdrawable);
        uint256 _amountTotransfer = _availableToWithdraw[msg.sender];
        awaitingOwners -= _amountTotransfer;
        _KUMA.transfer(msg.sender, _amountTotransfer);
        _availableToWithdraw[msg.sender] = 0;
    }

    /* OWNER */

    function withdrawAll() external onlyOwner {
        uint256 balance = _KUMA.balanceOf(address(this));
        _KUMA.transfer(msg.sender, balance - awaitingOwners);
    }

    function withdrawOwnable() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function startSale() external onlyOwner {
        isStarted = true;
    }

    function stopSale() external onlyOwner {
        isStarted = false;
    }

    function startWithdraw() external onlyOwner {
        isWithdrawable = true;
    }

        function addInWhitelist(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            _whitelist[_users[i]] = true;
        }
    }

    /* GETTERS */

    function getPrice() public view returns (uint256) {
         (,int256 price,,,) = _PRICEFEED.latestRoundData();
        return uint256(price * (1 * 10 ** 10));
    }

    function _getConversionRate(uint256 _amount) private view returns (uint256) {
        uint256 _ethPrice = getPrice();
        uint256 _ethInUSD = (_ethPrice * _amount) / (1 * 10 ** 18);
        return _ethInUSD;
    }

    function getTokenBalance() public view returns (uint256) {
        uint256 _balance = _KUMA.balanceOf(address(this));
        return _balance;
    }

    function getMaticBalance() public view returns (uint256) {
        address _this = address(this);
        uint256 _balance = _this.balance;
        return _balance;
    }

    function getUSDBalance() public view returns (uint) {
        uint256 _balance = getMaticBalance();
        uint256 _usd = _getConversionRate(_balance);
        return _usd;
    }

    function _calculateStartedPercent(uint256 _amount) private pure returns (uint256) {
        return (_amount * 3000) / 10000;
    }
}