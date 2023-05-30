// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBank is IERC20 {
	function mint(uint) external returns (uint);
	function burn(uint) external returns (uint);
	function circulatingSupply() external view returns (uint);
}

interface IFavor {
	function start() external;
	function resetContributions() external;
	function getFavors() external view returns (uint, uint);
}

interface IPoolLP {
	function start() external;
}

interface IRandom {
	function getRandomNb(uint) external view returns (uint);
}

contract Staking is Ownable {
	struct Epoch {
		uint8 winner;
		uint amount;
	}

	IERC20 public immutable TOKEN;
	IBank public immutable BANK1;
	IBank public immutable BANK2;
	IFavor public immutable FAVOR;
	IPoolLP public immutable POOL_LP;
	IRandom public immutable RANDOM;

	uint public roundStartTime;
	uint public UNLOCKED_DURATION = 8 hours;
	uint public EPOCH_DURATION = 1 days;

	uint public PAYOUT = 1000;
	uint public MAX_WIN_RATE = 7500;
	uint public MIN_WIN_RATE = 2500;
	uint public FEE = 100;
	uint private constant DENOMINATOR = 10000;

	uint public epochNb;
	Epoch[] public epoch;

	address public receiver;

	constructor(
		IERC20 token, 
		IBank bank1, 
		IBank bank2, 
		IFavor favor, 
		IPoolLP poolLP, 
		IRandom random, 
		address receiver_
	) 
	{
		TOKEN = token;
		BANK1 = bank1;
		BANK2 = bank2;
		FAVOR = favor;
		POOL_LP = poolLP;
		RANDOM = random;
		receiver = receiver_;
	}

	function start() external onlyOwner {
		require(roundStartTime == 0, "Already initialized");
		roundStartTime = block.timestamp;
		FAVOR.start();
		POOL_LP.start();
	}

	function stake(bool bank, uint amountIn) external {
		_update();

		(uint amount, uint fee) = _computeAmountAndFee(amountIn);
		TOKEN.transferFrom(msg.sender, address(this), amount);
		if (fee > 0) TOKEN.transferFrom(msg.sender, receiver, fee);

		if (!bank) BANK1.transfer(msg.sender, amount);
		else BANK2.transfer(msg.sender, amount);
	}

	function unstake(bool bank, uint amountIn) external {
		_update();

		if (!bank) BANK1.transferFrom(msg.sender, address(this), amountIn);
		else BANK2.transferFrom(msg.sender, address(this), amountIn);
		
		(uint amount, uint fee) = _computeAmountAndFee(amountIn);
		TOKEN.transfer(msg.sender, amount);
		if (fee > 0) TOKEN.transfer(receiver, fee);
	}

	function jump(bool bank) external {
		if (!bank) {
			uint amountIn = BANK1.balanceOf(msg.sender);
			(uint amount, uint fee) = _computeAmountAndFee(amountIn);

			BANK1.transferFrom(msg.sender, address(this), amountIn);
			BANK2.transfer(msg.sender, amount);
			if (fee > 0) TOKEN.transfer(receiver, fee);
		} else {
			uint amountIn = BANK2.balanceOf(msg.sender);
			(uint amount, uint fee) = _computeAmountAndFee(amountIn);

			BANK2.transferFrom(msg.sender, address(this), amountIn);
			BANK1.transfer(msg.sender, amount);
			if (fee > 0) TOKEN.transfer(receiver, fee);
		}
	}

	function setReceiver(address newReceiver) external onlyOwner {
		receiver = newReceiver;
	}

	function updateStorage(uint[] calldata array) external onlyOwner {
		UNLOCKED_DURATION = array[0];
		EPOCH_DURATION = array[1];
		PAYOUT = array[2];
		MAX_WIN_RATE = array[3];
		MIN_WIN_RATE = array[4];
		FEE = array[5];
	}

	function epochLength() public view returns (uint) {
		return epoch.length;
	}

	function getEpochs(uint cursor, uint size) external view returns (Epoch[] memory out) {
		uint maxLength = epochLength();
		uint length = size > maxLength - cursor ? maxLength - cursor : size;
		out = new Epoch[](length);
		for (uint i; i < length; i++) out[i] = epoch[cursor + i];
	}

	function getWinRates() public view returns (uint winRate1, uint winRate2) {
		uint staked1 = BANK1.circulatingSupply();
		uint staked2 = BANK2.circulatingSupply();

		if (staked1 == 0 && staked2 == 0) return (0, 0);

		winRate1 = staked1 * DENOMINATOR / (staked1 + staked2);
		winRate2 = DENOMINATOR - winRate1;
	}

	function getWinRatesWithFavors() public view returns (uint winRate1, uint winRate2) {
		(winRate1,) = getWinRates();
		if (winRate1 == 0 || winRate1 == DENOMINATOR) return (0, 0);

		(uint favor1, uint favor2) = FAVOR.getFavors();
		if (favor1 > 0) {
			winRate1 += favor1;
		} else if (favor2 > 0) {
			if (favor2 > winRate1) winRate1 = MIN_WIN_RATE;
			else winRate1 -= favor2;
		}
		if (winRate1 > MAX_WIN_RATE) winRate1 = MAX_WIN_RATE;
		if (winRate1 < MIN_WIN_RATE) winRate1 = MIN_WIN_RATE;

		winRate2 = DENOMINATOR - winRate1;
	}

	function _update() internal {
		uint roundStartTimeCached = roundStartTime;
		require(roundStartTimeCached != 0, "Didn't start yet");

		if (block.timestamp > roundStartTimeCached + EPOCH_DURATION) {
			roundStartTime = block.timestamp;
			_endEpoch();
		} else if (block.timestamp > roundStartTimeCached + UNLOCKED_DURATION) {
			revert("Tokens are locked");
		}
	}

	function _endEpoch() internal {
		(uint winRate1,) = getWinRatesWithFavors();
		if (winRate1 == 0) return;

		FAVOR.resetContributions();

		uint randomNumber = RANDOM.getRandomNb(DENOMINATOR);
		if (randomNumber < winRate1) {
			uint payout = BANK2.circulatingSupply() * PAYOUT / DENOMINATOR;
			BANK1.mint(payout);
			BANK2.burn(payout);
			epoch.push(Epoch(1,payout));
		} else {
			uint payout = BANK1.circulatingSupply() * PAYOUT / DENOMINATOR;
			BANK2.mint(payout);
			BANK1.burn(payout);
			epoch.push(Epoch(2,payout));
		}
		epochNb += 1;
	}

	function _computeAmountAndFee(uint amount) internal view returns (uint, uint) {
		uint fee = amount * FEE / DENOMINATOR;
		amount -= fee;
		return (amount, fee);
	}
}