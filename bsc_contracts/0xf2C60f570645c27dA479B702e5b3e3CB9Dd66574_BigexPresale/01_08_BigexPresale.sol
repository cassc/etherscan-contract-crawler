// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {IBigexInterface} from "./interfaces/BigexInterfaceToken.sol";
import {IBigexAirdrop} from "./interfaces/IBigexAirdrop.sol";

contract BigexPresale is Ownable, Pausable {
	using SafeMath for uint256;

	IERC20 public bigexToken;
	IERC20 public paymentToken;

	uint256 public timeTGE;
	uint256 public timePeriod;
	uint256 public receivePercentage;
	uint256 public minBuy;
	uint256 public maxBuy;
	uint256 public minBuyBnb;
	uint256 public maxBuyBnb;
	uint256 public tokenPriceRate;
	uint256 public tokenPriceRateBnb;
	uint256 public rateBnbToUsd;
	uint256 public totalSell = 0;
	uint256[] public refReward = [7, 5, 3];

	mapping(address => uint256[]) public userLockDetail;
	mapping(address => uint256) public userTotalPayment;
	mapping(address => uint256) public userTotalPaymentBnb;

	address public otherInvestmentContract;
	address public airDropContract;
	address public defaultRef = 0x6CAf58372Ea9809A64C4AE4C7731d3792B8548cA;

	bool public activeBuyBNB = true;
	bool public activeBuyToken = true;

	event BuyToken(address user, address paymentToken, uint256 amountToken, uint256 amountPayment, uint256 timestamp);
	event BuyTokenBnb(address user, uint256 amountToken, uint256 amountPayment, uint256 timestamp);

	constructor (
		address _addressBigexToken,
		address _paymentToken,
		uint256 _timePeriod,
		uint256 _receivePercentage,
		uint256 _minBuy,
		uint256 _maxBuy,
		uint256 _tokenPriceRate
	) {
		bigexToken = IERC20(_addressBigexToken);
		paymentToken = IERC20(_paymentToken);
		timePeriod = _timePeriod;
		timeTGE = block.timestamp;
		receivePercentage = _receivePercentage;
		minBuy = _minBuy;
		maxBuy = _maxBuy;
		tokenPriceRate = _tokenPriceRate;
	}

	receive() external payable {}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function setAirDropContract(address _airDropContract) public onlyOwner {
		airDropContract = _airDropContract;
	}

	function setRefReward(uint256[] memory _refReward) public onlyOwner {
		refReward = _refReward;
	}

	function setRateBnbToUsd(uint256 _rate) public onlyOwner {
		rateBnbToUsd = _rate;
	}

	function setActiveBuyBNB(bool _result) public onlyOwner {
		activeBuyBNB = _result;
	}

	function setActiveBuyToken(bool _result) public onlyOwner {
		activeBuyToken = _result;
	}

	function setMinMaxBuy(uint256 _minBuy, uint256 _maxBuy) public onlyOwner {
		minBuy = _minBuy;
		maxBuy = _maxBuy;
	}

	function setMinMaxBuyBnb(uint256 _minBuy, uint256 _maxBuy) public onlyOwner {
		minBuyBnb = _minBuy;
		maxBuyBnb = _maxBuy;
	}

	function setTokenPriceRate(uint256 _tokenPriceRate) public onlyOwner {
		tokenPriceRate = _tokenPriceRate;
	}

	function setTokenPriceRateBnb(uint256 _tokenPriceRate) public onlyOwner {
		tokenPriceRateBnb = _tokenPriceRate;
	}

	function setPaymentToken(address _paymentToken) public onlyOwner {
		paymentToken = IERC20(_paymentToken);
	}

	function setBigexToken(address _bigexToken) public onlyOwner {
		bigexToken = IERC20(_bigexToken);
	}

	function setOtherInvestmentContract(address _otherInvestmentContract) public onlyOwner {
		otherInvestmentContract = _otherInvestmentContract;
	}

	function totalBuy(address _wallet) public view returns (uint256){
		return userTotalPayment[_wallet];
	}

	function totalBuyBnb(address _wallet) public view returns (uint256){
		return userTotalPaymentBnb[_wallet];
	}

	function getITransferInvestment(address _wallet) external view returns (uint256){
		uint256 totalLock = 0;
		if (otherInvestmentContract != address(0)) {
			totalLock = totalLock.add(IBigexInterface(otherInvestmentContract).getITransferInvestment(_wallet));
		}
		for (uint256 i = 0; i < userLockDetail[_wallet].length; i++) {
			totalLock = totalLock.add(userLockDetail[_wallet][i]);
			if (block.timestamp > timeTGE) {
				uint256 unlockAmount = userLockDetail[_wallet][i].mul(receivePercentage).div(100).mul(
					block.timestamp.sub(timeTGE).div(timePeriod)
				);
				if (unlockAmount > 0) {
					if (unlockAmount >= userLockDetail[_wallet][i]) {
						totalLock = totalLock.sub(userLockDetail[_wallet][i]);
					} else {
						totalLock = totalLock.sub(unlockAmount);
					}
				}
			}
		}
		return totalLock;
	}

	function usdToBNB(uint256 _paymentUsd) public view returns (uint256) {
		return _paymentUsd.mul(10e18).div(100).div(rateBnbToUsd).mul(10);
	}

	function bnbToUSD(uint256 _paymentBnb) public view returns (uint256) {
		uint256 usd = _paymentBnb.mul(rateBnbToUsd).div(1e18);
		return usd;
	}

	function buyToken(uint256 _paymentAmount) public whenNotPaused {
		require(activeBuyToken, "PreSale: function is not active");

		require(minBuy <= _paymentAmount && _paymentAmount <= maxBuy, "PreSale: min max buy is not valid");
		require(totalBuy(msg.sender) + _paymentAmount <= maxBuy, "PreSale: limit buy token");

		// check allowance
		require(paymentToken.allowance(msg.sender, address(this)) >= _paymentAmount, "PreSale: insufficient allowance");

		// check balance payment token before buy token
		require(paymentToken.balanceOf(msg.sender) >= _paymentAmount, "PreSale: balance not enough");

		uint256 totalToken = _paymentAmount.mul(1e18).div(tokenPriceRate);
		totalSell = totalSell.add(totalToken);

		// check balance token contract
		require(bigexToken.balanceOf(address(this)) >= totalToken, "PreSale: contract not enough balance");

		address _ref = IBigexAirdrop(airDropContract).getRef(msg.sender);
		uint256 remains = _paymentAmount;

		if (_ref == address(0)) {
			_ref = defaultRef;
		}

		if (_ref != address(0)) {
			// transfer reward f0
			paymentToken.transferFrom(msg.sender, _ref, _paymentAmount.mul(refReward[0]).div(100));
			remains = remains.sub(_paymentAmount.mul(refReward[0]).div(100));
			address ref = IBigexAirdrop(airDropContract).getRef(_ref);
			for (uint256 i = 1; i < refReward.length; i++) {
				if (ref != address(0)) {
					// transfer reward to Fn
					paymentToken.transferFrom(msg.sender, ref, _paymentAmount.mul(refReward[i]).div(100));
					remains = remains.sub(_paymentAmount.mul(refReward[i]).div(100));
					ref = IBigexAirdrop(airDropContract).getRef(ref);
				}
			}
		}

		// get token from user to contract
		paymentToken.transferFrom(msg.sender, address(this), remains);

		// transfer token to wallet
		bigexToken.transfer(msg.sender, totalToken);

		// update lock detail
		userLockDetail[msg.sender].push(totalToken);

		// update total payment amount
		userTotalPayment[msg.sender] = userTotalPayment[msg.sender].add(_paymentAmount);
		userTotalPaymentBnb[msg.sender] = userTotalPaymentBnb[msg.sender].add(usdToBNB(_paymentAmount));

		emit BuyToken(msg.sender, address(paymentToken), totalToken, _paymentAmount, block.timestamp);
	}

	function buyTokenBNB() public payable whenNotPaused {
		require(activeBuyBNB, "PreSale: function is not active");

		uint256 _paymentBnb = msg.value;
		uint256 remains = _paymentBnb;
		uint256 _paymentAmount = bnbToUSD(_paymentBnb);

		require(minBuyBnb <= _paymentBnb && _paymentBnb <= maxBuyBnb, "PreSale: min max buy is not valid");
		require(totalBuyBnb(msg.sender) + _paymentBnb <= maxBuyBnb, "PreSale: limit buy token");

		// check balance payment token before buy token
		require(address(msg.sender).balance >= _paymentBnb, "PreSale: balance not enough");

		uint256 totalToken = _paymentBnb.mul(1e18).div(tokenPriceRateBnb);
		totalSell = totalSell.add(totalToken);

		// check balance token contract
		require(bigexToken.balanceOf(address(this)) >= totalToken, "PreSale: contract not enough balance");

		address _ref = IBigexAirdrop(airDropContract).getRef(msg.sender);

		if (_ref == address(0)) {
			_ref = defaultRef;
		}

		if (_ref != address(0)) {
			// transfer reward f0
			payable(_ref).transfer(_paymentBnb.mul(refReward[0]).div(100));
			remains = remains.sub(_paymentBnb.mul(refReward[0]).div(100));
			address ref = IBigexAirdrop(airDropContract).getRef(_ref);
			for (uint256 i = 1; i < refReward.length; i++) {
				if (ref != address(0)) {
					// transfer reward to Fn
					payable(ref).transfer(_paymentBnb.mul(refReward[i]).div(100));
					remains = remains.sub(_paymentBnb.mul(refReward[i]).div(100));
					ref = IBigexAirdrop(airDropContract).getRef(ref);
				}
			}
		}
		payable(address(this)).transfer(remains);

		// transfer token to wallet
		bigexToken.transfer(msg.sender, totalToken);

		// update lock detail
		userLockDetail[msg.sender].push(totalToken);

		// update total payment amount
		userTotalPaymentBnb[msg.sender] = userTotalPaymentBnb[msg.sender].add(_paymentBnb);
		userTotalPayment[msg.sender] = userTotalPayment[msg.sender].add(_paymentAmount);

		emit BuyTokenBnb(msg.sender, totalToken, _paymentAmount, block.timestamp);
	}

	function getUserLockDetailLength(address _wallet) public view returns (uint256){
		return userLockDetail[_wallet].length;
	}

	function setUserLockDetail(address _wallet, uint256[] memory lockDetail) public onlyOwner {
		userLockDetail[_wallet] = lockDetail;
	}

	function setTotalSell(uint256 _amount) public onlyOwner {
		totalSell = _amount;
	}

	function setUserTotalPayment(address _user, uint256 _amount) public onlyOwner {
		userTotalPayment[_user] = _amount;
	}

	function setUserTotalPaymentBnb(address _user, uint256 _amount) public onlyOwner {
		userTotalPaymentBnb[_user] = _amount;
	}

	function updateNewTimeTGEAndTimePeriod(uint256 _newTimeTGE, uint256 _newTimePeriod) public onlyOwner {
		require(_newTimeTGE > block.timestamp, "Presale: request time greater than current time");
		timeTGE = _newTimeTGE;
		timePeriod = _newTimePeriod;
	}

	function setDefaultRef(address _address) public onlyOwner {
		defaultRef = _address;
	}
	/**
	Clear unknow token
	*/
	function clearUnknownToken(address _tokenAddress) public onlyOwner {
		uint256 contractBalance = IERC20(_tokenAddress).balanceOf(address(this));
		IERC20(_tokenAddress).transfer(address(msg.sender), contractBalance);
	}

	/**
	Withdraw bnb
	*/
	function withdraw(address _to) public onlyOwner {
		require(_to != address(0), "Presale: wrong address withdraw");
		uint256 amount = address(this).balance;
		payable(_to).transfer(amount);
	}
}