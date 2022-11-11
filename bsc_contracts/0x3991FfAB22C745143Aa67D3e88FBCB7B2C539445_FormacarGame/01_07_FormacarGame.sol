// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './ISwap.sol';
import './Governance.sol';


contract FormacarGame is ERC20, Governance
{


struct WhaleData
{
	uint buyPeriod;
	uint buyVolume1;
	uint buyVolume2;
	uint buyVolume3;
	uint buyVolumeTemp;
	uint sellPeriod;
	uint sellVolume1;
	uint sellVolume2;
	uint sellVolume3;
	uint sellVolumeTemp;
}

struct Market
{
	bool isMarket;

	bool antiBotEnabled;
	bool launchAllowed;
	uint launchedAt;

	uint buyFeeMillis;
	uint sellFeeMillis;

	uint minWhaleLimit;
	uint buyWhaleLimit;
	uint sellWhaleLimit;

	// To fix compilation stack error
	WhaleData whale;
}

struct Trader
{
	uint firstBuyAt;
	uint8 buyCount;
}


// Trading fees
address public feeReceiver;
bool private _feeReceiverLocked;
mapping(address => bool) public isFeeExcluded;

// Antiwhale
mapping(address => bool) public isWhaleExcluded;
uint8 public whaleRatePercents = 3; // Max deal volume from whole trade volume by market

// AMMs
mapping(address => Market) public markets;
mapping(address => bool) public isDexPeriphery;

// Antisnipe
mapping(address => bool) public isSnipeExcluded;
mapping(address => Trader) public traders;
uint8 public snipeTargetBuyCount = 5; // On what antisnipe will triggered
uint16 public snipeMonitorPeriod = 60;
uint16 public snipeWholePeriod = 360; // Monitor + lock periods

// Antidump
uint16 public dumpDurationSeconds = 3600;
uint16 public dumpThresholdPercents = 175; // 100 + real difference (for calculations)
uint8 public dumpFeePercents = 60;
uint public dumpMinControlVolume = 25000 ether; // 25K FCG;
uint public dumpActivatedAt;
uint private ad_currentPeriod;
uint private ad_buyVolume;
uint private ad_sellVolume;
uint private ad_buyVolumeTemp;
uint private ad_sellVolumeTemp;

// Low market fee temps
uint private _lowFeeAt;
uint16 private _lowFeeBuyMillis;
uint16 private _lowFeeSellMillis;
address private _lowFeePair;


event MarketFeeUpdated(address indexed pair, uint buyMillis, uint sellMillis);
event FeeExcluded(address indexed account, bool isExcluded);
event AntiWhaleExcluded(address indexed account, bool isExcluded);
event AntiSnipeExcluded(address indexed account, bool isExcluded);
event AntiDumpActivated();
event NewMarket(address indexed pair);
event MarketRemoved(address indexed pair);
event NewDexPeriphery(address indexed thing);
event DexPeripheryRemoved(address indexed thing);
event MarketLaunched(address indexed pair);


constructor(
	address[] memory validators_,
	address[] memory workers_,
	uint[] memory levels_,
	address feeReceiver_
)
	ERC20('FormacarGame', 'FCG')
	Governance(validators_, workers_, levels_)
{
	_mint(workers_[0], 1000000000 ether); // 1B FCG, whole supply to first worker

	for (uint i; i < validators_.length; i++) _excludeFromAll(validators_[i]);
	for (uint i; i < workers_.length; i++) _excludeFromAll(workers_[i]);

	require(feeReceiver_ != address(0), 'FCG: invalid fee receiver');
	_excludeFromAll(feeReceiver_);
	feeReceiver = feeReceiver_;

	_excludeFromAll(address(this));
}


function _excludeFromAll(address account) private
{
	isFeeExcluded[account] = true;
	isWhaleExcluded[account] = true;
	isSnipeExcluded[account] = true;

	emit FeeExcluded(account, true);
	emit AntiWhaleExcluded(account, true);
	emit AntiSnipeExcluded(account, true);
}


function _setFeeReceiver(address account) private
{
	require(account != address(0) && account != feeReceiver, 'FCG: invalid address');
	require(!_feeReceiverLocked, 'FCG: locked');

	_excludeFromAll(account);
	feeReceiver = account;
}

function _allowLaunchMarket(address pair) private
{
	Market storage market = markets[pair];
	require(market.isMarket, 'FCG: not exist');
	require(!market.launchAllowed, 'FCG: already allowed');

	market.launchAllowed = true;
}

function _setMarketFee(address pair, uint buyMillis, uint sellMillis) private
{
	Market storage market = markets[pair];

	require(market.isMarket, 'FCG: not exist');
	require(sellMillis >= 20 && sellMillis <= 1000 &&
		buyMillis >= 20 && buyMillis <= 1000, 'FCG: limit is 20-1000 millis');

	if (market.buyFeeMillis != buyMillis) market.buyFeeMillis = buyMillis;
	if (market.sellFeeMillis != sellMillis) market.sellFeeMillis = sellMillis;

	emit MarketFeeUpdated(pair, buyMillis, sellMillis);
}

function _setLowMarketFeeTemps(address pair, uint buyMillis, uint sellMillis) private
{
	require(markets[pair].isMarket, 'FCG: not exist');
	require(sellMillis < 1000 && buyMillis < 1000, 'FCG: limit is 1000 millis');

	_lowFeePair = pair;
	_lowFeeBuyMillis = uint16(buyMillis);
	_lowFeeSellMillis = uint16(sellMillis);
	_lowFeeAt = block.timestamp;
}

function getLowMarketFeeTemps() external view returns(address pair, uint buyMillis, uint sellMillis, uint at)
{
	if (_lowFeeAt + 1 hours > block.timestamp)
	{
		pair = _lowFeePair;
		buyMillis = _lowFeeBuyMillis;
		sellMillis = _lowFeeSellMillis;
		at = _lowFeeAt;
	}
}

function acceptLowMarketFee() external
{
	require(msg.sender == feeReceiver, 'FCG: only fee receiver');
	require(_lowFeeAt + 1 hours > block.timestamp, 'FCG: expired');

	Market storage market = markets[_lowFeePair];
	require(market.isMarket, 'FCG: is not market');

	if (market.buyFeeMillis != _lowFeeBuyMillis) market.buyFeeMillis = _lowFeeBuyMillis;
	if (market.sellFeeMillis != _lowFeeSellMillis) market.sellFeeMillis = _lowFeeSellMillis;
	_lowFeeAt = 0;

	emit MarketFeeUpdated(_lowFeePair, _lowFeeBuyMillis, _lowFeeSellMillis);
}

function _setFeeExcluded(address account, bool isExcluded) private
{
	require(account != address(0), 'FCG: invalid address');

	isFeeExcluded[account] = isExcluded;
	emit FeeExcluded(account, isExcluded);
}

function _setFeeExcludedMany(address[] memory accounts, bool[] memory isExcludeds) private
{
	require(accounts.length > 0 && accounts.length == isExcludeds.length,
		'FCG: invalid input arrays');

	for (uint i; i < accounts.length; i++)
	{
		if (accounts[i] == address(0)) continue;
		
		isFeeExcluded[accounts[i]] = isExcludeds[i];
		emit FeeExcluded(accounts[i], isExcludeds[i]);
	}
}


/// Anti whale ///

function _setWhaleExcluded(address account, bool isExcluded) private
{
	require(account != address(0), 'FCG: invalid address');

	isWhaleExcluded[account] = isExcluded;
	emit AntiWhaleExcluded(account, isExcluded);
}

function _setWhaleExcludedMany(address[] memory accounts, bool[] memory isExcludeds)
	private
{
	require(accounts.length > 0 && accounts.length == isExcludeds.length,
		'FCG: invalid input arrays');

	for (uint256 i; i < accounts.length; i++)
	{
		if (accounts[i] != address(0))
		{
			isWhaleExcluded[accounts[i]] = isExcludeds[i];
			emit AntiWhaleExcluded(accounts[i], isExcludeds[i]);
		}
	}
}

function _setWhaleMinLimit(address pair, uint newValue) private
{
	Market storage market = markets[pair];
	require(market.isMarket, 'FCG: invalid pair');
	require(newValue != market.minWhaleLimit, 'FCG: same value');

	market.minWhaleLimit = newValue;
	if (market.buyWhaleLimit < newValue) market.buyWhaleLimit = newValue;
	if (market.sellWhaleLimit < newValue) market.sellWhaleLimit = newValue;
}

function _setWhaleRatePercents(uint ratePercents) private
{
	require(ratePercents >= 1 && ratePercents <= 15, 'FCG: invalid rate');
	require(whaleRatePercents != ratePercents, 'FCG: same');

	whaleRatePercents = uint8(ratePercents);
}


/// Anti snipe ///

function _setSnipeExcluded(address account, bool isExcluded) private
{
	require(account != address(0), 'FCG: invalid address');

	isSnipeExcluded[account] = isExcluded;
	emit AntiSnipeExcluded(account, isExcluded);
}

function _setSnipeExcludedMany(address[] memory accounts, bool[] memory isExcludeds) private
{
	require(accounts.length > 0 && accounts.length == isExcludeds.length,
		'FCG: invalid input arrays');

	for (uint256 i; i < accounts.length; i++)
	{
		if (accounts[i] != address(0))
		{
			isSnipeExcluded[accounts[i]] = isExcludeds[i];
			emit AntiSnipeExcluded(accounts[i], isExcludeds[i]);
		}
	}
}

function _setSnipeControlValues(uint targetBuyCount, uint monitorPeriod, uint lockPeriod) private
{
	require(targetBuyCount >= 1 && targetBuyCount <= 25, 'FCG: invalid count');
	require(monitorPeriod >= 12 && monitorPeriod <= 300, 'FCG: invalid monitor');
	require(lockPeriod >= 60 && targetBuyCount <= 1500, 'FCG: invalid lock');

	if (snipeTargetBuyCount != targetBuyCount) snipeTargetBuyCount = uint8(targetBuyCount);
	if (snipeMonitorPeriod != monitorPeriod) snipeMonitorPeriod = uint16(monitorPeriod);

	uint wholePeriod = monitorPeriod + lockPeriod;
	if (snipeWholePeriod != wholePeriod) snipeWholePeriod = uint16(wholePeriod);
}


/// Antidump ///

function _setDumpControlValues(uint thresholdPercents, uint minControlVolume, uint durationSeconds, uint feePercents) private
{
	require(thresholdPercents >= 15 && thresholdPercents <= 375, 'FCG: invalid threshold');
	require(minControlVolume >= 100 ether, 'FCG: invalid volume');
	require(durationSeconds >= 720 && durationSeconds <= 18000, 'FCG: invalid duration');
	require(feePercents >= 12 && feePercents <= 100, 'FCG: invalid fee');

	thresholdPercents += 100; // For calculations
	if (dumpThresholdPercents != thresholdPercents) dumpThresholdPercents = uint16(thresholdPercents);
	if (dumpMinControlVolume != minControlVolume) dumpMinControlVolume = minControlVolume;
	if (dumpDurationSeconds != durationSeconds) dumpDurationSeconds = uint16(durationSeconds);
	if (dumpFeePercents != feePercents) dumpFeePercents = uint8(feePercents);
}


/// Trading markets management ///

// Add/remove an important contract of certain DEX (router, NPM)
function _addDexPeriphery(address thing) private
{
	require(thing != address(0), 'FCG: invalid address');
	require(!isDexPeriphery[thing], 'FCG: already');
	require(!markets[thing].isMarket, 'FCG: is market');

	isDexPeriphery[thing] = true;
	emit NewDexPeriphery(thing);
}

function _removeDexPeriphery(address thing) private
{
	require(isDexPeriphery[thing], 'FCG: not exist');

	isDexPeriphery[thing] = false;
	emit DexPeripheryRemoved(thing);
}

// Create new pair on factory and add it
function _createMarketV2(address factory, address token) private
{
	require(factory != address(0) && token != address(0)
		&& factory != token && token != address(this), 'FCG: invalid address');

	address pair = ISwapFactoryV2(factory).createPair(address(this), token);
	_insertMarket(pair, 0);
}

function _createMarketV3(address factory, address token, uint24 fee) private
{
	require(factory != address(0) && token != address(0)
		&& factory != token && token != address(this), 'FCG: invalid address');

	address pool = ISwapFactoryV3(factory).createPool(address(this), token, fee);
	_insertMarket(pool, 0);
}

// Add previously created pair/pool to control list
function _addMarket(address pair, bool force) private
{
	require(pair != address(0), 'FCG: invalid address');
	require(!isDexPeriphery[pair], 'FCG: is periphery');

	if (!force)
	{
		ISwapPair swapPair = ISwapPair(pair);
		require(swapPair.token0() == address(this) || swapPair.token1() == address(this), 'FCG: invalid pair');
	}

	_insertMarket(pair, 1);
}

// Main adding logic, also insert new router
function _insertMarket(address pair, uint launchedAt) private
{
	Market storage market = markets[pair];
	require(!market.isMarket, 'FCG: market exist');

	market.isMarket = true;
	market.launchedAt = launchedAt;
	market.buyFeeMillis = 20;
	market.sellFeeMillis = 20;
	market.minWhaleLimit = 10000 ether;
	market.buyWhaleLimit = market.minWhaleLimit;
	market.sellWhaleLimit = market.minWhaleLimit;
	emit NewMarket(pair);
}

function _removeMarket(address pair) private
{
	Market storage market = markets[pair];
	require(market.isMarket, 'FCG: not exist');

	market.isMarket = false;
	emit MarketRemoved(pair);
}


// Override transfering to process protection and fee cases
function _transfer(address from, address to, uint256 amount) internal virtual override
{
	// Basic ERC20 checks
	require(from != address(0), 'ERC20: transfer from the zero address');
	require(to != address(0), 'ERC20: transfer to the zero address');
	require(balanceOf(from) >= amount, 'ERC20: transfer amount exceeds balance');


	// Detect DEX relations
	Market storage toAsMarket = markets[to];
	Market storage fromAsMarket = markets[from];

	bool isSell = toAsMarket.isMarket;
	bool isBuy = fromAsMarket.isMarket;


	// Detect when add first liq to protected pair
	if (toAsMarket.isMarket && toAsMarket.launchedAt == 0)
	{
		require(getWorkerLevel(msg.sender) > 0, 'FCG: not permitted to launch this pair');
		require(toAsMarket.launchAllowed, 'FCG: launch not allowed');

		toAsMarket.launchedAt = block.timestamp;
		toAsMarket.antiBotEnabled = true;

		emit MarketLaunched(to);
	}


	// Detect trading case and set trader address at one time
	address traderAddress = isBuy != isSell ? (isBuy ? to : from) : address(0);
	
	// If it's trading case and not interact with periphery
	if (traderAddress != address(0) && !isDexPeriphery[traderAddress])
	{
		Market storage market = isBuy ? fromAsMarket : toAsMarket;


		// Anti snipe
		if (!isSnipeExcluded[traderAddress])
		{
			Trader storage trader = traders[traderAddress];
			uint timePassed = block.timestamp - trader.firstBuyAt;

			if (timePassed > snipeMonitorPeriod)
			{
				// Block the sniper
				if (timePassed < snipeWholePeriod)
					require(trader.buyCount < snipeTargetBuyCount, 'FCG: antisnipe lock');

				// Else init new control period
				if (isBuy)
				{
					trader.firstBuyAt = block.timestamp;
					trader.buyCount = 1;
				}
			}
			else if (isBuy) trader.buyCount++;
		}


		// Check amount limit by daily volume (antiwhale)
		if (!isWhaleExcluded[traderAddress]) require(
			amount <= (isBuy ? market.buyWhaleLimit : market.sellWhaleLimit), 'FCG: anti whale limit');


		// Process daily trading volume of this market for antiwhale limit
		uint period = block.timestamp / 21600; // 6 hours, 4 periods per day
		if (isBuy)
		{
			WhaleData storage whale = market.whale;
			if (whale.buyPeriod < period)
			{
				uint whaleLimit = (whale.buyVolume1 + whale.buyVolume2
					+ whale.buyVolume3 + whale.buyVolumeTemp) * whaleRatePercents / 100;

				if (whaleLimit > market.minWhaleLimit) market.buyWhaleLimit = whaleLimit;
				else market.buyWhaleLimit = market.minWhaleLimit;

				whale.buyVolume1 = whale.buyVolume2;
				whale.buyVolume2 = whale.buyVolume3;
				whale.buyVolume3 = whale.buyVolumeTemp;
				whale.buyVolumeTemp = amount;
				whale.buyPeriod = period;
			}
			else whale.buyVolumeTemp += amount;
		}
		else
		{
			WhaleData storage whale = market.whale;
			if (whale.sellPeriod < period)
			{
				uint whaleLimit = (whale.sellVolume1 + whale.sellVolume2
					+ whale.sellVolume3 + whale.sellVolumeTemp) * whaleRatePercents / 100;

				if (whaleLimit > market.minWhaleLimit) market.sellWhaleLimit = whaleLimit;
				else market.sellWhaleLimit = market.minWhaleLimit;

				whale.sellVolume1 = whale.sellVolume2;
				whale.sellVolume2 = whale.sellVolume3;
				whale.sellVolume3 = whale.sellVolumeTemp;
				whale.sellVolumeTemp = amount;
				whale.sellPeriod = period;
			}
			else whale.sellVolumeTemp += amount;
		}


		// Process antidump
		period = block.timestamp / 1800; // Half of hour
		if (ad_currentPeriod < period)
		{
			uint hourlyBuyVolume = ad_buyVolume + ad_buyVolumeTemp;
			uint hourlySellVolume = ad_sellVolume + ad_sellVolumeTemp;

			// Activation
			if (hourlyBuyVolume + hourlySellVolume > dumpMinControlVolume &&
				hourlySellVolume > hourlyBuyVolume * dumpThresholdPercents / 100)
			{
				dumpActivatedAt = block.timestamp;
				emit AntiDumpActivated();
			}

			ad_currentPeriod = period;
			ad_buyVolume = ad_buyVolumeTemp;
			ad_sellVolume = ad_sellVolumeTemp;
			ad_buyVolumeTemp = isBuy ? amount : 0;
			ad_sellVolumeTemp = isSell ? amount : 0;
		}
		else
		{
			if (isBuy) ad_buyVolumeTemp += amount;
			else ad_sellVolumeTemp += amount;
		}


		// Process fees
		if (!isFeeExcluded[traderAddress])
		{
			// Calculate fee
			uint feeAmount = amount * (isBuy ? market.buyFeeMillis : market.sellFeeMillis) / 1000;

			if (isSell)
			{
				// Bot penalties on sell at market launch (antibot)
				if (market.antiBotEnabled)
				{
					if (market.launchedAt + 3600 > block.timestamp) feeAmount *= 20;
					else market.antiBotEnabled = false;
				}

				// Antidump applying
				if (dumpActivatedAt + dumpDurationSeconds > block.timestamp)
					feeAmount += amount * dumpFeePercents / 100;
			}
				

			// Apply fee
			if (feeAmount > 0)
			{
				// Clamp overflowed fee
				if (feeAmount > amount) feeAmount = amount;

				// Subtract from amount
				if (isBuy) amount -= feeAmount;

				// Get extra fee
				else require(balanceOf(from) >= amount + feeAmount, 'FCG: not enough balance for fee');
				
				super._transfer(from, feeReceiver, feeAmount);
			}
		}
	}


	// Do main transfer
	if (amount > 0) super._transfer(from, to, amount);
}


/// Governance actions

// Governance actions descriptions
function _getActionDescription(uint actionId) internal pure virtual override returns(string memory)
{
	if (actionId == 3) return 'SetFeeExcluded/Many (account/s, isExcluded/s)';
	if (actionId == 4) return 'SetWhaleExcluded/Many (account/s, isExcluded/s)';
	if (actionId == 5) return 'SetSnipeExcluded/Many (account/s, isExcluded/s)';
	if (actionId == 6) return 'ExcludeFromAll (account)';
	if (actionId == 7) return 'SetMarketFee (pair, buyFeeMillis, sellFeeMillis)';
	if (actionId == 8) return 'SetDumpControlValues (thresholdPercents, minControlVolume, durationSeconds, feePercents)';
	if (actionId == 9) return 'SetWhaleMinLimit (pair, newValue)';
	if (actionId == 10) return 'CreateMarketV2 (factory, token)';
	if (actionId == 11) return 'CreateMarketV3 (factory, token, fee)';
	if (actionId == 12) return 'AddMarket (pair)';
	if (actionId == 13) return 'AllowLaunchMarket (pair)';
	if (actionId == 14) return 'RemoveMarket (pair)';
	if (actionId == 15) return 'AddDexPeriphery (thing)';
	if (actionId == 16) return 'RemoveDexPeriphery (thing)';
	if (actionId == 17) return 'SetFeeReceiver (account)';
	if (actionId == 18) return 'LockFeeReceiver ()';
	if (actionId == 19) return 'SetLowMarketFeeTemps (pair, buyMillis, sellMillis)';
	if (actionId == 20) return 'SetSnipeControlValues (targetBuyCount, monitorPeriod, lockPeriod)';
	if (actionId == 21) return 'SetWhaleRatePercents (ratePercents)';
	return super._getActionDescription(actionId);
}

// Governance actions importance level that workers need to have
function _getActionLevel(uint actionId) internal pure virtual override returns(uint)
{
	if (actionId == 3) return 1; // SetFeeExcluded/Many
	if (actionId == 4) return 1; // SetWhaleExcluded/Many
	if (actionId == 5) return 1; // SetSnipeExcluded/Many
	if (actionId == 6) return 1; // ExcludeFromAll
	if (actionId == 7) return 2; // SetMarketFee
	if (actionId == 8) return 2; // SetDumpControlValues
	if (actionId == 9) return 2; // SetWhaleMinLimit
	if (actionId == 10) return 2; // CreateMarketV2
	if (actionId == 11) return 2; // CreateMarketV3
	if (actionId == 12) return 2; // AddMarket
	if (actionId == 13) return 2; // AllowLaunchMarket
	if (actionId == 14) return 2; // RemoveMarket
	if (actionId == 15) return 2; // AddDexPeriphery
	if (actionId == 16) return 2; // RemoveDexPeriphery
	if (actionId == 17) return 3; // SetFeeReceiver
	if (actionId == 18) return 3; // LockFeeReceiver
	if (actionId == 19) return 2; // SetLowMarketFeeTemps
	if (actionId == 20) return 2; // SetSnipeControlValues
	if (actionId == 21) return 2; // SetWhaleRatePercents
	return super._getActionLevel(actionId);
}

// Governance validators count that need to accept action
function _getActionApproveCount(uint actionId) internal pure virtual override returns(uint)
{
	if (actionId == 3) return 1; // SetFeeExcluded/Many
	if (actionId == 4) return 1; // SetWhaleExcluded/Many
	if (actionId == 5) return 1; // SetSnipeExcluded/Many
	if (actionId == 6) return 1; // ExcludeFromAll
	if (actionId == 7) return 2; // SetMarketFee
	if (actionId == 8) return 3; // SetDumpControlValues
	if (actionId == 9) return 2; // SetWhaleMinLimit
	if (actionId == 10) return 2; // CreateMarketV2
	if (actionId == 11) return 2; // CreateMarketV3
	if (actionId == 12) return 2; // AddMarket
	if (actionId == 13) return 3; // AllowLaunchMarket
	if (actionId == 14) return 3; // RemoveMarket
	if (actionId == 15) return 3; // AddDexPeriphery
	if (actionId == 16) return 3; // RemoveDexPeriphery
	if (actionId == 17) return 4; // SetFeeReceiver
	if (actionId == 18) return 4; // LockFeeReceiver
	if (actionId == 19) return 2; // SetLowMarketFeeTemps
	if (actionId == 20) return 3; // SetSnipeControlValues
	if (actionId == 21) return 3; // SetWhaleRatePercents
	return super._getActionApproveCount(actionId);
}

// Governance decrees applying
function _acceptDecree(uint decreeId, uint actionId) internal virtual override
{
	if (actionId == 3) // SetFeeExcluded/Many
	{
		address[] memory dudes = _getAddressArrayParam(decreeId);
		if (dudes.length > 0) _setFeeExcludedMany(dudes, _getBoolArrayParam(decreeId));
		else _setFeeExcluded(_getAddressParam(decreeId), _getBoolParam(decreeId));
	}

	else if (actionId == 4) // SetWhaleExcluded/Many
	{
		address[] memory dudes = _getAddressArrayParam(decreeId);
		if (dudes.length > 0) _setWhaleExcludedMany(dudes, _getBoolArrayParam(decreeId));
		else _setWhaleExcluded(_getAddressParam(decreeId), _getBoolParam(decreeId));
	}

	else if (actionId == 5) // SetSnipeExcluded/Many
	{
		address[] memory dudes = _getAddressArrayParam(decreeId);
		if (dudes.length > 0) _setSnipeExcludedMany(dudes, _getBoolArrayParam(decreeId));
		else _setSnipeExcluded(_getAddressParam(decreeId), _getBoolParam(decreeId));
	}

	else if (actionId == 6) // ExcludeFromAll
		_excludeFromAll(_getAddressParam(decreeId));

	else if (actionId == 7) // SetMarketFee
	{
		uint[] memory fees = _getUintArrayParam(decreeId);
		require(fees.length == 2, 'FCG: invalid fees array');

		_setMarketFee(_getAddressParam(decreeId), fees[0], fees[1]);
	}

	else if (actionId == 8) // SetDumpControlValues
	{
		uint[] memory vals = _getUintArrayParam(decreeId);
		require(vals.length == 4, 'FCG: invalid values array');

		_setDumpControlValues(vals[0], vals[1], vals[2], vals[3]);
	}

	else if (actionId == 9) // SetWhaleMinLimit
		_setWhaleMinLimit(_getAddressParam(decreeId), _getUintParam(decreeId));

	else if (actionId == 10) // CreateMarketV2
	{
		address[] memory factoryAndToken = _getAddressArrayParam(decreeId);
		require(factoryAndToken.length == 2, 'FCG: invalid params');

		_createMarketV2(factoryAndToken[0], factoryAndToken[1]);
	}

	else if (actionId == 11) // CreateMarketV3
	{
		address[] memory factoryAndToken = _getAddressArrayParam(decreeId);
		require(factoryAndToken.length == 2, 'FCG: invalid params');

		_createMarketV3(factoryAndToken[0], factoryAndToken[1], uint24(_getUintParam(decreeId)));
	}

	else if (actionId == 12) // AddMarket
		_addMarket(_getAddressParam(decreeId), _getBoolParam(decreeId));

	else if (actionId == 13) // AllowLaunchMarket
		_allowLaunchMarket(_getAddressParam(decreeId));

	else if (actionId == 14) // RemoveMarket
		_removeMarket(_getAddressParam(decreeId));

	else if (actionId == 15) // AddDexPeriphery
		_addDexPeriphery(_getAddressParam(decreeId));

	else if (actionId == 16) // RemoveDexPeriphery
		_removeDexPeriphery(_getAddressParam(decreeId));

	else if (actionId == 17) // SetFeeReceiver
		_setFeeReceiver(_getAddressParam(decreeId));

	else if (actionId == 18) // LockFeeReceiver
		_feeReceiverLocked = true;

	else if (actionId == 19) // SetLowMarketFeeTemps
	{
		uint[] memory fees = _getUintArrayParam(decreeId);
		require(fees.length == 2, 'FCG: invalid fees array');

		_setLowMarketFeeTemps(_getAddressParam(decreeId), fees[0], fees[1]);
	}

	else if (actionId == 20) // SetSnipeControlValues
	{
		uint[] memory vals = _getUintArrayParam(decreeId);
		require(vals.length == 3, 'FCG: invalid values array');

		_setSnipeControlValues(vals[0], vals[1], vals[2]);
	}

	else if (actionId == 21) // SetWhaleRatePercents
		_setWhaleRatePercents(_getUintParam(decreeId));

	else super._acceptDecree(decreeId, actionId);
}


}