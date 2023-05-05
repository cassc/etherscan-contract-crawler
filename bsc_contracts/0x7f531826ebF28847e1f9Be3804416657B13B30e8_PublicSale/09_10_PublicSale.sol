pragma solidity ^0.8.0;

import {IToken} from "./interfaces/IToken.sol";
import {IUser} from "./interfaces/IUser.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./supports/SupportToken.sol";

contract PublicSale is Ownable, Pausable, SupportToken {
	using SafeMath for uint256;

	IERC20 public token = IERC20(0xe15577611E5Ac55E6640f8530A1231A0d8e60331);
	IERC20 public USDT = IERC20(0xd836549eC7c836174Fedc475C4B346D48281c947);
	address public userContract = 0x79C1eD52820DF3D90908F4201D997dba51f21063;

	uint256 public tokenPriceRateUSDT = 25000000000000000; // $ 0.025
	uint256 public minBuyUSDT = 30000000000000000000; // $ 30
	uint256 public maxBuyUSDT = 100000000000000000000; // $ 100
	uint256[] public refReward = [9, 6, 3];

	uint256 public totalSell = 0;
	uint256 public startTime = 9999999999;
	uint256 public unlockPercent = 5; // 5%
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
		require(_amount > 0, "Public sale: amount greater than zero");
		require(userBuyAmount[msg.sender] + _amount >= minBuyUSDT, "Public sale: purchase quantity is too low");
		require(userBuyAmount[msg.sender] + _amount <= maxBuyUSDT, "Public sale: purchase quantity is too high");
		require(
			USDT.balanceOf(msg.sender) >= _amount,
			"Public sale: your balance not enough."
		);

		uint256 amountToken = getRateTokenUSDT(_amount);
		require(
			token.balanceOf(address(this)) >= amountToken,
			"Public sale: contract not enough token."
		);
		require(userContract != address(0), "Public sale: not found user contract");

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
			.div(100)
			.mul(block.timestamp.sub(startTime).div(timePeriod));

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