// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';
import 'solmate/utils/FixedPointMathLib.sol';

import './libraries/Ownership.sol';
import './libraries/BlockDelay.sol';
import './interfaces/IERC4626.sol';
import './Strategy.sol';

contract Vault is ERC20, IERC4626, Ownership, BlockDelay {
	using SafeTransferLib for ERC20;
	using FixedPointMathLib for uint256;

	/// @notice token which the vault uses and accumulates
	ERC20 public immutable asset;

	/// @notice whether deposits and withdrawals are paused
	bool public paused;

	uint256 private _lockedProfit;
	/// @notice timestamp of last report, used for locked profit calculations
	uint256 public lastReport;
	/// @notice period over which profits are gradually unlocked, defense against sandwich attacks
	uint256 public lockedProfitDuration = 6 hours;
	uint256 internal constant MAX_LOCKED_PROFIT_DURATION = 3 days;

	/// @dev maximum user can deposit in a single tx
	uint256 private _maxDeposit = type(uint256).max;

	struct StrategyParams {
		bool added;
		uint256 debt;
		uint256 debtRatio;
	}

	Strategy[] private _queue;
	mapping(Strategy => StrategyParams) public strategies;

	uint8 internal constant MAX_QUEUE_LENGTH = 20;

	uint256 public totalDebt;
	uint256 public totalDebtRatio;
	uint256 internal constant MAX_TOTAL_DEBT_RATIO = 1_000;

	/*//////////////////
	/      Events      /
	//////////////////*/

	event Report(Strategy indexed strategy, uint256 harvested, uint256 gain, uint256 loss);
	event Lend(Strategy indexed strategy, uint256 assets, uint256 slippage);
	event Collect(Strategy indexed strategy, uint256 received, uint256 slippage);

	event StrategyAdded(Strategy indexed strategy, uint256 debtRatio);
	event StrategyDebtRatioChanged(Strategy indexed strategy, uint256 newDebtRatio);
	event StrategyRemoved(Strategy indexed strategy);
	event StrategyQueuePositionsSwapped(uint8 i, uint8 j, Strategy indexed newI, Strategy indexed newJ);

	event LockedProfitDurationChanged(uint256 newDuration);
	event MaxDepositChanged(uint256 newMaxDeposit);

	/*//////////////////
	/      Errors      /
	//////////////////*/

	error Zero();
	error BelowMinimum(uint256);
	error AboveMaximum(uint256);

	error AboveMaxDeposit();

	error AlreadyStrategy();
	error NotStrategy();
	error StrategyDoesNotBelongToQueue();
	error StrategyQueueFull();

	error AlreadyValue();

	error Paused();

	/// @dev e.g. USDC becomes 'Unagii USD Coin Vault v3' and 'uUSDCv3'
	constructor(
		ERC20 _asset,
		address[] memory _authorized,
		uint8 _blockDelay
	)
		ERC20(
			string(abi.encodePacked('Unagii ', _asset.name(), ' Vault v3')),
			string(abi.encodePacked('u', _asset.symbol(), 'v3')),
			_asset.decimals()
		)
		Ownership(_authorized)
		BlockDelay(_blockDelay)
	{
		asset = _asset;
	}

	/*///////////////////////
	/      Public View      /
	///////////////////////*/

	function queue() external view returns (Strategy[] memory) {
		return _queue;
	}

	function totalAssets() public view returns (uint256 assets) {
		return asset.balanceOf(address(this)) + totalDebt;
	}

	function lockedProfit() public view returns (uint256 lockedAssets) {
		uint256 last = lastReport;
		uint256 duration = lockedProfitDuration;

		unchecked {
			// won't overflow since time is nowhere near uint256.max
			if (block.timestamp >= last + duration) return 0;
			// can overflow if _lockedProfit * difference > uint256.max but in practice should never happen
			return _lockedProfit - _lockedProfit.mulDivDown(block.timestamp - last, duration);
		}
	}

	function freeAssets() public view returns (uint256 assets) {
		return totalAssets() - lockedProfit();
	}

	function convertToShares(uint256 _assets) public view returns (uint256 shares) {
		uint256 supply = totalSupply;
		return supply == 0 ? _assets : _assets.mulDivDown(supply, totalAssets());
	}

	function convertToAssets(uint256 _shares) public view returns (uint256 assets) {
		uint256 supply = totalSupply;
		return supply == 0 ? _shares : _shares.mulDivDown(totalAssets(), supply);
	}

	function maxDeposit(address) external view returns (uint256 assets) {
		return _maxDeposit;
	}

	function previewDeposit(uint256 _assets) public view returns (uint256 shares) {
		return convertToShares(_assets);
	}

	function maxMint(address) external view returns (uint256 shares) {
		return convertToShares(_maxDeposit);
	}

	function previewMint(uint256 shares) public view returns (uint256 assets) {
		uint256 supply = totalSupply;
		return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
	}

	function maxWithdraw(address owner) external view returns (uint256 assets) {
		return convertToAssets(balanceOf[owner]);
	}

	function previewWithdraw(uint256 assets) public view returns (uint256 shares) {
		uint256 supply = totalSupply;

		return supply == 0 ? assets : assets.mulDivUp(supply, freeAssets());
	}

	function maxRedeem(address _owner) external view returns (uint256 shares) {
		return balanceOf[_owner];
	}

	function previewRedeem(uint256 shares) public view returns (uint256 assets) {
		uint256 supply = totalSupply;
		return supply == 0 ? shares : shares.mulDivDown(freeAssets(), supply);
	}

	/*////////////////////////////
	/      Public Functions      /
	////////////////////////////*/

	function safeDeposit(
		uint256 _assets,
		address _receiver,
		uint256 _minShares
	) external returns (uint256 shares) {
		shares = deposit(_assets, _receiver);
		if (shares < _minShares) revert BelowMinimum(shares);
	}

	function safeMint(
		uint256 _shares,
		address _receiver,
		uint256 _maxAssets
	) external returns (uint256 assets) {
		assets = mint(_shares, _receiver);
		if (assets > _maxAssets) revert AboveMaximum(assets);
	}

	function safeWithdraw(
		uint256 _assets,
		address _receiver,
		address _owner,
		uint256 _maxShares
	) external returns (uint256 shares) {
		shares = withdraw(_assets, _receiver, _owner);
		if (shares > _maxShares) revert AboveMaximum(shares);
	}

	function safeRedeem(
		uint256 _shares,
		address _receiver,
		address _owner,
		uint256 _minAssets
	) external returns (uint256 assets) {
		assets = redeem(_shares, _receiver, _owner);
		if (assets < _minAssets) revert BelowMinimum(assets);
	}

	/*////////////////////////////////////
	/      ERC4626 Public Functions      /
	////////////////////////////////////*/

	function deposit(uint256 _assets, address _receiver) public whenNotPaused returns (uint256 shares) {
		if ((shares = previewDeposit(_assets)) == 0) revert Zero();

		_deposit(_assets, shares, _receiver);
	}

	function mint(uint256 _shares, address _receiver) public whenNotPaused returns (uint256 assets) {
		if (_shares == 0) revert Zero();
		assets = previewMint(_shares);

		_deposit(assets, _shares, _receiver);
	}

	function withdraw(
		uint256 _assets,
		address _receiver,
		address _owner
	) public returns (uint256 shares) {
		if (_assets == 0) revert Zero();
		shares = previewWithdraw(_assets);

		_withdraw(_assets, shares, _owner, _receiver);
	}

	function redeem(
		uint256 _shares,
		address _receiver,
		address _owner
	) public returns (uint256 assets) {
		if ((assets = previewRedeem(_shares)) == 0) revert Zero();

		return _withdraw(assets, _shares, _owner, _receiver);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function addStrategy(Strategy _strategy, uint256 _debtRatio) external onlyOwner {
		if (_strategy.vault() != this) revert StrategyDoesNotBelongToQueue();
		if (strategies[_strategy].added) revert AlreadyStrategy();
		if (_queue.length >= MAX_QUEUE_LENGTH) revert StrategyQueueFull();

		totalDebtRatio += _debtRatio;
		if (totalDebtRatio > MAX_TOTAL_DEBT_RATIO) revert AboveMaximum(totalDebtRatio);

		strategies[_strategy] = StrategyParams({added: true, debt: 0, debtRatio: _debtRatio});
		_queue.push(_strategy);

		emit StrategyAdded(_strategy, _debtRatio);
	}

	/*////////////////////////////////////////////
	/      Restricted Functions: onlyAdmins      /
	////////////////////////////////////////////*/

	function removeStrategy(Strategy _strategy, uint256 _minReceived) external onlyAdmins {
		if (!strategies[_strategy].added) revert NotStrategy();
		totalDebtRatio -= strategies[_strategy].debtRatio;

		if (strategies[_strategy].debt > 0) {
			(uint256 received, ) = _collect(_strategy, type(uint256).max, address(this));
			if (received < _minReceived) revert BelowMinimum(received);
		}

		// reorganize queue, filling in the empty strategy
		Strategy[] memory newQueue = new Strategy[](_queue.length - 1);

		bool found;
		uint8 length = uint8(newQueue.length);
		for (uint8 i = 0; i < length; ++i) {
			if (_queue[i] == _strategy) found = true;

			if (found) newQueue[i] = _queue[i + 1];
			else newQueue[i] = _queue[i];
		}

		delete strategies[_strategy];
		_queue = newQueue;

		emit StrategyRemoved(_strategy);
	}

	function swapQueuePositions(uint8 _i, uint8 _j) external onlyAdmins {
		Strategy s1 = _queue[_i];
		Strategy s2 = _queue[_j];

		_queue[_i] = s2;
		_queue[_j] = s1;

		emit StrategyQueuePositionsSwapped(_i, _j, s2, s1);
	}

	function setDebtRatio(Strategy _strategy, uint256 _newDebtRatio) external onlyAdmins {
		if (!strategies[_strategy].added) revert NotStrategy();
		_setDebtRatio(_strategy, _newDebtRatio);
	}

	/// @dev locked profit duration can be 0
	function setLockedProfitDuration(uint256 _newDuration) external onlyAdmins {
		if (_newDuration > MAX_LOCKED_PROFIT_DURATION) revert AboveMaximum(_newDuration);
		if (_newDuration == lockedProfitDuration) revert AlreadyValue();
		lockedProfitDuration = _newDuration;
		emit LockedProfitDurationChanged(_newDuration);
	}

	function setBlockDelay(uint8 _newDelay) external onlyAdmins {
		_setBlockDelay(_newDelay);
	}

	/*///////////////////////////////////////////////
	/      Restricted Functions: onlyAuthorized     /
	///////////////////////////////////////////////*/

	function suspendStrategy(Strategy _strategy) external onlyAuthorized {
		if (!strategies[_strategy].added) revert NotStrategy();
		_setDebtRatio(_strategy, 0);
	}

	function collectFromStrategy(
		Strategy _strategy,
		uint256 _assets,
		uint256 _minReceived
	) external onlyAuthorized returns (uint256 received) {
		if (!strategies[_strategy].added) revert NotStrategy();
		(received, ) = _collect(_strategy, _assets, address(this));
		if (received < _minReceived) revert BelowMinimum(received);
	}

	function pause() external onlyAuthorized {
		if (paused) revert AlreadyValue();
		paused = true;
	}

	function unpause() external onlyAuthorized {
		if (!paused) revert AlreadyValue();
		paused = false;
	}

	function setMaxDeposit(uint256 _newMaxDeposit) external onlyAuthorized {
		if (_maxDeposit == _newMaxDeposit) revert AlreadyValue();
		_maxDeposit = _newMaxDeposit;
		emit MaxDepositChanged(_newMaxDeposit);
	}

	/// @dev costs less gas than multiple harvests if active strategies > 1
	function harvestAll() external onlyAuthorized updateLastReport {
		uint8 length = uint8(_queue.length);
		for (uint8 i = 0; i < length; ++i) {
			_harvest(_queue[i]);
		}
	}

	/// @dev costs less gas than multiple reports if active strategies > 1
	function reportAll() external onlyAuthorized updateLastReport {
		uint8 length = uint8(_queue.length);
		for (uint8 i = 0; i < length; ++i) {
			_report(_queue[i], 0);
		}
	}

	function harvest(Strategy _strategy) external onlyAuthorized updateLastReport {
		if (!strategies[_strategy].added) revert NotStrategy();

		_harvest(_strategy);
	}

	function report(Strategy _strategy) external onlyAuthorized updateLastReport {
		if (!strategies[_strategy].added) revert NotStrategy();

		_report(_strategy, 0);
	}

	/*///////////////////////////////////////////
	/      Internal Override: useBlockDelay     /
	///////////////////////////////////////////*/

	/// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
	function _mint(address _to, uint256 _amount) internal override useBlockDelay(_to) {
		if (_to == address(0)) revert Zero();
		ERC20._mint(_to, _amount);
	}

	/// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
	function _burn(address _from, uint256 _amount) internal override useBlockDelay(_from) {
		ERC20._burn(_from, _amount);
	}

	/// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
	function transfer(address _to, uint256 _amount)
		public
		override
		useBlockDelay(msg.sender)
		useBlockDelay(_to)
		returns (bool)
	{
		return ERC20.transfer(_to, _amount);
	}

	/// @dev address cannot mint/burn/send/receive share tokens on same block, defense against flash loan exploits
	function transferFrom(
		address _from,
		address _to,
		uint256 _amount
	) public override useBlockDelay(_from) useBlockDelay(_to) returns (bool) {
		return ERC20.transferFrom(_from, _to, _amount);
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _deposit(
		uint256 _assets,
		uint256 _shares,
		address _receiver
	) internal {
		if (_assets > _maxDeposit) revert AboveMaxDeposit();

		asset.safeTransferFrom(msg.sender, address(this), _assets);
		_mint(_receiver, _shares);
		emit Deposit(msg.sender, _receiver, _assets, _shares);
	}

	function _withdraw(
		uint256 _assets,
		uint256 _shares,
		address _owner,
		address _receiver
	) internal returns (uint256 received) {
		if (msg.sender != _owner) {
			uint256 allowed = allowance[_owner][msg.sender];
			if (allowed != type(uint256).max) allowance[_owner][msg.sender] = allowed - _shares;
		}

		_burn(_owner, _shares);

		emit Withdraw(msg.sender, _receiver, _owner, _assets, _shares);

		// first, withdraw from balance
		uint256 balance = asset.balanceOf(address(this));

		if (balance > 0) {
			uint256 amount = _assets > balance ? balance : _assets;
			asset.safeTransfer(_receiver, amount);
			_assets -= amount;
			received += amount;
		}

		// next, withdraw from strategies
		uint8 length = uint8(_queue.length);
		for (uint8 i = 0; i < length; ++i) {
			if (_assets == 0) break;
			(uint256 receivedFromStrategy, uint256 slippage) = _collect(_queue[i], _assets, _receiver);
			_assets -= receivedFromStrategy + slippage; // user pays for slippage, if any
			received += receivedFromStrategy;
		}
	}

	function _lend(Strategy _strategy, uint256 _assets) internal {
		uint256 balance = asset.balanceOf(address(this));
		uint256 amount = _assets > balance ? balance : _assets;

		asset.safeTransfer(address(_strategy), amount);
		_strategy.invest();

		uint256 debtBefore = strategies[_strategy].debt;
		uint256 debtAfter = _strategy.totalAssets();
		strategies[_strategy].debt = debtAfter;

		uint256 slippage = debtBefore > debtAfter ? debtBefore - debtAfter : 0;

		totalDebt += amount - slippage;

		emit Lend(_strategy, amount, slippage);
	}

	/// @dev overflow is handled by strategy
	function _collect(
		Strategy _strategy,
		uint256 _assets,
		address _receiver
	) internal returns (uint256 received, uint256 slippage) {
		(received, slippage) = _strategy.withdraw(_assets, _receiver);

		uint256 debt = strategies[_strategy].debt;

		uint256 amount = debt > received ? received : debt;

		strategies[_strategy].debt -= amount;
		totalDebt -= amount;

		if (_receiver == address(this)) emit Collect(_strategy, received, slippage);
	}

	function _harvest(Strategy _strategy) internal {
		_report(_strategy, _strategy.harvest());
	}

	function _report(Strategy _strategy, uint256 _harvested) internal {
		uint256 assets = _strategy.totalAssets();
		uint256 debt = strategies[_strategy].debt;

		strategies[_strategy].debt = assets; // update debt

		uint256 gain;
		uint256 loss;

		uint256 lockedProfitBefore = lockedProfit();

		if (assets > debt) {
			unchecked {
				gain = assets - debt;
			}
			totalDebt += gain;

			_lockedProfit = lockedProfitBefore + gain + _harvested;
		} else if (debt > assets) {
			unchecked {
				loss = debt - assets;
				totalDebt -= loss;

				_lockedProfit = lockedProfitBefore + _harvested > loss ? lockedProfitBefore + _harvested - loss : 0;
			}
		}

		uint256 possibleDebt = totalDebtRatio == 0
			? 0
			: totalAssets().mulDivDown(strategies[_strategy].debtRatio, totalDebtRatio);

		if (possibleDebt > assets) _lend(_strategy, possibleDebt - assets);
		else if (assets > possibleDebt) _collect(_strategy, assets - possibleDebt, address(this));

		emit Report(_strategy, _harvested, gain, loss);
	}

	function _setDebtRatio(Strategy _strategy, uint256 _newDebtRatio) internal {
		uint256 currentDebtRatio = strategies[_strategy].debtRatio;
		if (_newDebtRatio == currentDebtRatio) revert AlreadyValue();

		uint256 newTotalDebtRatio = totalDebtRatio + _newDebtRatio - currentDebtRatio;
		if (newTotalDebtRatio > MAX_TOTAL_DEBT_RATIO) revert AboveMaximum(newTotalDebtRatio);

		strategies[_strategy].debtRatio = _newDebtRatio;
		totalDebtRatio = newTotalDebtRatio;

		emit StrategyDebtRatioChanged(_strategy, _newDebtRatio);
	}

	/*/////////////////////
	/      Modifiers      /
	/////////////////////*/

	modifier updateLastReport() {
		_;
		lastReport = block.timestamp;
	}

	modifier whenNotPaused() {
		if (paused) revert Paused();
		_;
	}
}