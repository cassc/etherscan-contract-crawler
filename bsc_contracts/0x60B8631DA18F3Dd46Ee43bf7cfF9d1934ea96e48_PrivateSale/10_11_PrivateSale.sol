pragma solidity ^0.8.0;

import {IToken} from "./interfaces/IToken.sol";
import {IUser} from "./interfaces/IUser.sol";
import {ISaleContract} from "./interfaces/ISaleContract.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./supports/SupportToken.sol";

contract PrivateSale is Ownable, Pausable, SupportToken {
	using SafeMath for uint256;

	IERC20 public token = IERC20(0xe15577611E5Ac55E6640f8530A1231A0d8e60331);
	IERC20 public USDT = IERC20(0xd836549eC7c836174Fedc475C4B346D48281c947);
	address public userContract = 0x79C1eD52820DF3D90908F4201D997dba51f21063;
	address public saleContract = address(0);

	uint256 public tokenPriceRateUSDT = 15000000000000000; // $ 0.015
	uint256 public minBuyUSDT = 3000000000000000000000; // $ 3.000
	uint256 public maxBuyUSDT = 20000000000000000000000; // $ 20.000
	uint256[] public refReward = [9, 6, 3];

	uint256 public totalSell = 0;
	uint256 public startTime = 9999999999;
	uint256 public unlockPercent = 625; // 6.25%
	uint256 constant public timePeriod = 2592000; // 30 days

	event BUY_EVENT(
		address user,
		uint256 amount,
		uint256 amount_token,
		uint256 rate
	);
	event COMMISSION_USDT_EVENT(address user, uint256 amount);

	address public receiver = address(0);

	mapping(address => uint256) public userBuyAmount;
	mapping(address => uint256) public userLockToken;

	receive() external payable {}

	constructor() {
		receiver = msg.sender;
	}

	function buyUSDT(uint256 _amount) public whenNotPaused {
		require(_amount > 0, "Private sale: amount greater than zero");
		require(userBuyAmount[msg.sender] + _amount >= minBuyUSDT, "Private sale: purchase quantity is too low");
		require(userBuyAmount[msg.sender] + _amount <= maxBuyUSDT, "Private sale: purchase quantity is too high");
		require(ISaleContract(saleContract).getUserBuyAmount(msg.sender) > 0, "Private sale: need buy public sale first");
		require(
			USDT.balanceOf(msg.sender) >= _amount,
			"Private sale: your balance not enough."
		);

		uint256 amountToken = getRateTokenUSDT(_amount);
		require(
			token.balanceOf(address(this)) >= amountToken,
			"Private sale: contract not enough token."
		);
		require(userContract != address(0), "Private sale: not found user contract");

		uint256 remains = _amount;
		address _ref = IUser(userContract).getRef(msg.sender);

		for (uint256 i = 0; i < refReward.length; i++) {
			if (_ref != address(0)) {
				// transfer reward to Fn
				USDT.transferFrom(
					msg.sender,
					_ref,
					_amount.mul(refReward[i]).div(100)
				);
				emit COMMISSION_USDT_EVENT(
					_ref,
					_amount.mul(refReward[i]).div(100)
				);
				remains = remains.sub(_amount.mul(refReward[i]).div(100));
				_ref = IUser(userContract).getRef(_ref);
			}
		}

		token.transfer(address(msg.sender), amountToken);
		USDT.transferFrom(msg.sender, receiver, remains);
		emit BUY_EVENT(
			msg.sender,
			_amount,
			amountToken,
			tokenPriceRateUSDT
		);
		userBuyAmount[msg.sender] += _amount;
		userLockToken[msg.sender] += amountToken;
		totalSell = totalSell.add(amountToken);
	}

	function getRateTokenUSDT(uint256 _amount) public view returns (uint256) {
		return _amount.mul(1e18).div(tokenPriceRateUSDT);
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function setToken(address _token) public onlyOwner {
		token = IERC20(_token);
	}

	function setTokenUSDT(address _token) public onlyOwner {
		USDT = IERC20(_token);
	}

	function setTokenPriceRateUSDT(uint256 _rate) public onlyOwner {
		tokenPriceRateUSDT = _rate;
	}

	function setReceiver(address _address) public onlyOwner {
		receiver = _address;
	}

	function setUserContract(address _address) public onlyOwner {
		userContract = _address;
	}

	function setSaleContract(address _address) public onlyOwner {
		saleContract = _address;
	}

	function withdraw() public onlyOwner {
		uint256 amount = address(this).balance;
		payable(msg.sender).transfer(amount);
	}

	function getUserBuyAmount(address _address) public view returns (uint256) {
		return userBuyAmount[_address];
	}

	function setUserBuyAmount(
		address _address,
		uint256 _amount
	) public onlyOwner {
		userBuyAmount[_address] = _amount;
	}

	function setStartTime(uint256 _startTime) public onlyOwner {
		startTime = _startTime;
	}

	function getITransferInvestment(address _wallet)
	external
	view
	returns (uint256)
	{
		uint256 totalLock = 0;
		if (investmentContract != address(0)) {
			totalLock = totalLock.add(
				IToken(investmentContract).getITransferInvestment(_wallet)
			);
		}
		totalLock = totalLock.add(userLockToken[_wallet]);

		if (block.timestamp > startTime) {
			uint256 unlockAmount = userLockToken[_wallet]
			.mul(unlockPercent)
			.div(10000)
			.mul(block.timestamp.sub(startTime).div(timePeriod));

			// unlock TGE
			unlockAmount = unlockAmount.add(userLockToken[_wallet].mul(unlockPercent).div(10000));
			if (unlockAmount > 0) {
				if (unlockAmount >= userLockToken[_wallet]) {
					totalLock = totalLock.sub(
						userLockToken[_wallet]
					);
				} else {
					totalLock = totalLock.sub(unlockAmount);
				}
			}
		}
		return totalLock;
	}

	function setMinMaxBuy(uint256 _min, uint256 _max) public onlyOwner {
		minBuyUSDT = _min;
		maxBuyUSDT = _max;
	}
}