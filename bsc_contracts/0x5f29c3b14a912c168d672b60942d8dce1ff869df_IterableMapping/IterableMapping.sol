/**
 *Submitted for verification at BscScan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount)
	external
	returns (bool);

	function allowance(address owner, address spender)
	external
	view
	returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

interface IFactory {
	function createPair(address tokenA, address tokenB)
	external
	returns (address pair);

	function getPair(address tokenA, address tokenB)
	external
	view
	returns (address pair);
}

interface IRouter {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
	external
	payable
	returns (
		uint256 amountToken,
		uint256 amountETH,
		uint256 liquidity
	);

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

interface IERC20Metadata is IERC20 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
}

interface DividendPayingTokenInterface {
	function dividendOf(address _owner) external view returns(uint256);
	function distributeDividends() external payable;
	function withdrawDividend() external;
	event DividendsDistributed(
		address indexed from,
		uint256 weiAmount
	);
	event DividendWithdrawn(
		address indexed to,
		uint256 weiAmount
	);
}

interface DividendPayingTokenOptionalInterface {
	function withdrawableDividendOf(address _owner) external view returns(uint256);
	function withdrawnDividendOf(address _owner) external view returns(uint256);
	function accumulativeDividendOf(address _owner) external view returns(uint256);
}

library SafeMath {

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

library SafeMathInt {
	int256 private constant MIN_INT256 = int256(1) << 255;
	int256 private constant MAX_INT256 = ~(int256(1) << 255);

	function mul(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a * b;

		// Detect overflow when multiplying MIN_INT256 with -1
		require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
		require((b == 0) || (c / b == a));
		return c;
	}
	function div(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when dividing MIN_INT256 by -1
		require(b != -1 || a != MIN_INT256);

		// Solidity already throws when dividing by 0.
		return a / b;
	}
	function sub(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b < 0 && c > a));
		return c;
	}
	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a));
		return c;
	}
	function abs(int256 a) internal pure returns (int256) {
		require(a != MIN_INT256);
		return a < 0 ? -a : a;
	}
	function toUint256Safe(int256 a) internal pure returns (uint256) {
		require(a >= 0);
		return uint256(a);
	}
}

library SafeMathUint {
	function toInt256Safe(uint256 a) internal pure returns (int256) {
		int256 b = int256(a);
		require(b >= 0);
		return b;
	}
}

library IterableMapping {
	struct Map {
		address[] keys;
		mapping(address => uint) values;
		mapping(address => uint) indexOf;
		mapping(address => bool) inserted;
	}

	function get(Map storage map, address key) public view returns (uint) {
		return map.values[key];
	}

	function getIndexOfKey(Map storage map, address key) public view returns (int) {
		if(!map.inserted[key]) {
			return -1;
		}
		return int(map.indexOf[key]);
	}

	function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
		return map.keys[index];
	}

	function size(Map storage map) public view returns (uint) {
		return map.keys.length;
	}

	function set(Map storage map, address key, uint val) public {
		if (map.inserted[key]) {
			map.values[key] = val;
		} else {
			map.inserted[key] = true;
			map.values[key] = val;
			map.indexOf[key] = map.keys.length;
			map.keys.push(key);
		}
	}

	function remove(Map storage map, address key) public {
		if (!map.inserted[key]) {
			return;
		}

		delete map.inserted[key];
		delete map.values[key];

		uint index = map.indexOf[key];
		uint lastIndex = map.keys.length - 1;
		address lastKey = map.keys[lastIndex];

		map.indexOf[lastKey] = index;
		delete map.indexOf[key];

		map.keys[index] = lastKey;
		map.keys.pop();
	}
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract ERC20 is Context, IERC20, IERC20Metadata {
	using SafeMath for uint256;

	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;
	string private _name;
	string private _symbol;

	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	function decimals() public view virtual override returns (uint8) {
		return 18;
	}

	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");
		_beforeTokenTransfer(sender, recipient, amount);
		_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");
		_beforeTokenTransfer(address(0), account, amount);
		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");
		_beforeTokenTransfer(account, address(0), amount);
		_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}
}

contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
	using SafeMath for uint256;
	using SafeMathUint for uint256;
	using SafeMathInt for int256;

	uint256 constant internal magnitude = 2**128;
	uint256 internal magnifiedDividendPerShare;
	uint256 public totalDividendsDistributed;
    address public rewardToken;
	address private _BNBAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    IRouter public uniswapV2Router;

	mapping(address => int256) internal magnifiedDividendCorrections;
	mapping(address => uint256) internal withdrawnDividends;

	constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

	receive() external payable {
		distributeDividends();
	}

	function distributeDividends() public override onlyOwner payable {
		require(totalSupply() > 0);
		if (msg.value > 0) {
			magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalSupply());
			emit DividendsDistributed(msg.sender, msg.value);
			totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
		}
	}
	function withdrawDividend() public virtual override onlyOwner {
		_withdrawDividendOfUser(payable(msg.sender));
	}
	function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
		uint256 _withdrawableDividend = withdrawableDividendOf(user);
		if (_withdrawableDividend > 0) {
			withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
			emit DividendWithdrawn(user, _withdrawableDividend);
			if (rewardToken == address(_BNBAddress)) {
				(bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");
				if(!success) {
					withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
					return 0;
				}
				return _withdrawableDividend;
			}
			else {
				return _swapBNBForTokensAndWithdrawDividend(user, _withdrawableDividend);
			}
		}
		return 0;
	}
    function _swapBNBForTokensAndWithdrawDividend(address holder, uint256 bnbAmount) private returns(uint256) {
		address[] memory path = new address[](2);
		path[0] = uniswapV2Router.WETH();
		path[1] = address(rewardToken);

		try uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : bnbAmount}(
		0, // accept any amount of tokens
		path,
		address(holder),
		block.timestamp
		) {
			return bnbAmount;
		} catch {
			withdrawnDividends[holder] = withdrawnDividends[holder].sub(bnbAmount);
			return 0;
		}
	}
	function dividendOf(address _owner) public view override returns(uint256) {
		return withdrawableDividendOf(_owner);
	}
	function withdrawableDividendOf(address _owner) public view override returns(uint256) {
		return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
	}
	function withdrawnDividendOf(address _owner) public view override returns(uint256) {
		return withdrawnDividends[_owner];
	}
	function accumulativeDividendOf(address _owner) public view override returns(uint256) {
		return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
		.add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
	}
	function _transfer(address from, address to, uint256 value) internal virtual override {
		require(false);
		int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
		magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
		magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
	}
	function _mint(address account, uint256 value) internal override {
		super._mint(account, value);
		magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
		.sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
	}
	function _burn(address account, uint256 value) internal override {
		super._burn(account, value);
		magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
		.add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
	}
	function _setBalance(address account, uint256 newBalance) internal {
		uint256 currentBalance = balanceOf(account);
		if(newBalance > currentBalance) {
			uint256 mintAmount = newBalance.sub(currentBalance);
			_mint(account, mintAmount);
		} else if(newBalance < currentBalance) {
			uint256 burnAmount = currentBalance.sub(newBalance);
			_burn(account, burnAmount);
		}
	}
    function _setRewardToken(address token) internal onlyOwner {
		rewardToken = token;
	}
	function _setUniswapRouter(address router) internal onlyOwner {
		uniswapV2Router = IRouter(router);
	}
}

contract Blepe is ERC20, Ownable {
	IRouter public uniswapV2Router;
	address public immutable uniswapV2Pair;

    BlepeDividendTracker public dividendTracker;

	string private constant _name = "Blepe";
	string private constant _symbol = "BLEPE";
	uint8 private constant _decimals = 18;

	bool public isTradingEnabled;
	uint256 private _tradingPausedTimestamp;

	// initialSupply
	uint256 constant initialSupply = 21000000 * (10**18);

	// max wallet is 1.0% of initialSupply
	uint256 public maxWalletAmount = initialSupply * 200 / 10000;

	// max buy and sell tx is 1% and 0.5% of initialSupply
    uint256 public maxTxBuyAmount = initialSupply * 200 / 10000;
	uint256 public maxTxSellAmount = initialSupply * 100 / 10000;

	bool private _swapping;
	uint256 public minimumTokensBeforeSwap = 25000000 * (10**18);
    uint256 public gasForProcessing = 300000;

    address public liquidityWallet;
	address public operationsWallet;
	address public buyBackWallet;

    address public dividendToken = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

	struct CustomTaxPeriod {
		bytes23 periodName;
		uint8 blocksInPeriod;
		uint256 timeInPeriod;
		uint8 liquidityFeeOnBuy;
		uint8 liquidityFeeOnSell;
		uint8 operationsFeeOnBuy;
		uint8 operationsFeeOnSell;
		uint8 buyBackFeeOnBuy;
		uint8 buyBackFeeOnSell;
        uint8 holdersFeeOnBuy;
		uint8 holdersFeeOnSell;
	}

	// Launch taxes
	bool private _isLaunched;
	uint256 private _launchStartTimestamp;
	uint256 private _launchBlockNumber;
	CustomTaxPeriod private _launch1 = CustomTaxPeriod('launch1',5,0,100,1,0,5,0,5,0,3);
	CustomTaxPeriod private _launch2 = CustomTaxPeriod('launch2',0,3600,1,3,5,10,5,10,3,7);
	CustomTaxPeriod private _launch3 = CustomTaxPeriod('launch3',0,82800,1,1,5,10,5,10,3,4);

	// Base taxes
	CustomTaxPeriod private _default = CustomTaxPeriod('default',0,0,1,1,5,5,5,5,3,3);
	CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,1,1,5,5,5,5,3,3);
	// Rush Hour taxes
	uint256 private _RushHourStartTimestamp;
	CustomTaxPeriod private _Rush1 = CustomTaxPeriod('Rush1',0,3600,0,3,0,10,0,10,3,7);
	CustomTaxPeriod private _Rush2 = CustomTaxPeriod('Rush2',0,3600,1,1,5,10,5,10,3,4);

	uint256 private constant _blockedTimeLimit = 172800;
    bool private _feeOnWalletTranfers;
	mapping (address => bool) private _isAllowedToTradeWhenDisabled;
	mapping (address => bool) private _feeOnSelectedWalletTransfers;
	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
	mapping (address => bool) private _isExcludedFromMaxWalletLimit;
	mapping (address => bool) private _isBlocked;
	mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => uint256) private _buyTimesInLaunch;

	uint8 private _liquidityFee;
	uint8 private _operationsFee;
	uint8 private _buyBackFee;
	uint8 private _holdersFee;
	uint8 private _totalFee;

	event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
	event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
	event WalletChange(string indexed walletIdentifier, address indexed newWallet, address indexed oldWallet);
	event FeeChange(string indexed identifier, uint8 liquidityFee, uint8 operationsFee, uint8 buyBackFee, uint8 holdersFee);
	event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
	event BlockedAccountChange(address indexed holder, bool indexed status);
	event RushHourChange(bool indexed newValue, bool indexed oldValue);
    event GasForProcessingChange(uint256 indexed newValue, uint256 indexed oldValue);
    event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event FeeOnWalletTransferChange(bool indexed newValue, bool indexed oldValue);
	event FeeOnSelectedWalletTransfersChange(address indexed account, bool newValue);
    event DividendsSent(uint256 tokensSwapped);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
    event ClaimBNBOverflow(uint256 amount);
    event ProcessedDividendTracker(
		uint256 iterations,
		uint256 claims,
		uint256 lastProcessedIndex,
		bool indexed automatic,
		uint256 gas,
		address indexed processor
	);
	event FeesApplied(uint8 liquidityFee, uint8 operationsFee, uint8 buyBackFee, uint8 holdersFee, uint8 totalFee);

	constructor() ERC20(_name, _symbol) {
        dividendTracker = new BlepeDividendTracker();
        dividendTracker.setUniswapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        dividendTracker.setRewardToken(dividendToken);

        liquidityWallet = owner();
        operationsWallet = owner();
	    buyBackWallet = owner();

		IRouter _uniswapV2Router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet
		address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(
			address(this),
			_uniswapV2Router.WETH()
		);
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(dividendTracker)] = true;

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        _isAllowedToTradeWhenDisabled[owner()] = true;
        _isAllowedToTradeWhenDisabled[address(this)] = true;

		_isExcludedFromMaxTransactionLimit[address(this)] = true;
        _isExcludedFromMaxTransactionLimit[address(dividendTracker)] = true;

		_isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
		_isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(dividendTracker)] = true;
		_isExcludedFromMaxWalletLimit[address(this)] = true;
		_isExcludedFromMaxWalletLimit[owner()] = true;

		_mint(owner(), initialSupply);
	}

	receive() external payable {}

	// Setters
	function launch() external onlyOwner {
		_launchStartTimestamp = block.timestamp;
		_launchBlockNumber = block.number;
		isTradingEnabled = true;
		_isLaunched = true;
	}
	function cancelLaunch() external onlyOwner {
		require(this.isInLaunch(), "Blepe: Launch is not set");
		_launchStartTimestamp = 0;
		_launchBlockNumber = 0;
		_isLaunched = false;
	}
	function activateTrading() external onlyOwner {
		isTradingEnabled = true;
	}
	function deactivateTrading() external onlyOwner {
		isTradingEnabled = false;
		_tradingPausedTimestamp = block.timestamp;
	}
	function setRushHour() external onlyOwner {
		require(!this.isInRushHour(), "Blepe: Rush Hour is already set");
		require(isTradingEnabled, "Blepe: Trading must be enabled first");
		require(!this.isInLaunch(), "Blepe: Must not be in launch period");
		emit RushHourChange(true, false);
		_RushHourStartTimestamp = block.timestamp;
	}
	function cancelRushHour() external onlyOwner {
		require(this.isInRushHour(), "Blepe: blepeRush Hour is not set");
		emit RushHourChange(false, true);
		_RushHourStartTimestamp = 0;
	}
	function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Blepe: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
		_isAllowedToTradeWhenDisabled[account] = allowed;
		emit AllowedWhenTradingDisabledChange(account, allowed);
	}
	function excludeFromFees(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromFee[account] != excluded, "Bitoshi V2: Account is already the value of 'excluded'");
		_isExcludedFromFee[account] = excluded;
		emit ExcludeFromFeesChange(account, excluded);
	}
	function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromMaxTransactionLimit[account] != excluded, "Blepe: Account is already the value of 'excluded'");
		_isExcludedFromMaxTransactionLimit[account] = excluded;
		emit ExcludeFromMaxTransferChange(account, excluded);
	}
	function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
		require(_isExcludedFromMaxWalletLimit[account] != excluded, "Blepe: Account is already the value of 'excluded'");
		_isExcludedFromMaxWalletLimit[account] = excluded;
		emit ExcludeFromMaxWalletChange(account, excluded);
	}
    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }
    function setGasForProcessing(uint256 newValue) external onlyOwner {
		require(newValue != gasForProcessing, "Blepe: Cannot update gasForProcessing to same value");
		emit GasForProcessingChange(newValue, gasForProcessing);
		gasForProcessing = newValue;
	}
	function blockAccount(address account) external onlyOwner {
		require(!_isBlocked[account], "Blepe: Account is already blocked");
		if (_isLaunched) {
			require((block.timestamp - _launchStartTimestamp) < _blockedTimeLimit, "Blepe: Time to block accounts has expired");
		}
		_isBlocked[account] = true;
		emit BlockedAccountChange(account, true);
	}
	function unblockAccount(address account) external onlyOwner {
		require(_isBlocked[account], "Blepe: Account is not blcoked");
		_isBlocked[account] = false;
		emit BlockedAccountChange(account, false);
	}
	function setWallets(address newLiquidityWallet, address newOperationsWallet, address newBuyBackWallet) external onlyOwner {
		if(liquidityWallet != newLiquidityWallet) {
			require(newLiquidityWallet != address(0), "Blepe: The liquidityWallet cannot be 0");
			emit WalletChange('liquidityWallet', newLiquidityWallet, liquidityWallet);
			liquidityWallet = newLiquidityWallet;
		}
		if(operationsWallet != newOperationsWallet) {
			require(newOperationsWallet != address(0), "Blepe: The operationsWallet cannot be 0");
			emit WalletChange('operationsWallet', newOperationsWallet, operationsWallet);
			operationsWallet = newOperationsWallet;
		}
		if(buyBackWallet != newBuyBackWallet) {
			require(newBuyBackWallet != address(0), "Blepe: The buyBackWallet cannot be 0");
			emit WalletChange('buyBackWallet', newBuyBackWallet, buyBackWallet);
			buyBackWallet = newBuyBackWallet;
		}
	}
    function setFeeOnWalletTransfers(bool value) external onlyOwner {
		emit FeeOnWalletTransferChange(value, _feeOnWalletTranfers);
		_feeOnWalletTranfers = value;
	}
	function setFeeOnSelectedWalletTransfers(address account, bool value) external onlyOwner {
		require(_feeOnSelectedWalletTransfers[account] != value, "Blepe: The selected wallet is already set to the value ");
		_feeOnSelectedWalletTransfers[account] = value;
		emit FeeOnSelectedWalletTransfersChange(account, value);
	}
	// Base Fees
	function setBaseFeesOnBuy(uint8 _liquidityFeeOnBuy, uint8 _operationsFeeOnBuy, uint8 _buyBackFeeOnBuy, uint8 _holdersFeeOnBuy) external onlyOwner {
		_setCustomBuyTaxPeriod(_base, _liquidityFeeOnBuy, _operationsFeeOnBuy, _buyBackFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('baseFees-Buy', _liquidityFeeOnBuy, _operationsFeeOnBuy, _buyBackFeeOnBuy, _holdersFeeOnBuy);
	}
	function setBaseFeesOnSell(uint8 _liquidityFeeOnSell,uint8 _operationsFeeOnSell, uint8 _buyBackFeeOnSell, uint8 _holdersFeeOnSell) external onlyOwner {
		_setCustomSellTaxPeriod(_base, _liquidityFeeOnSell, _operationsFeeOnSell, _buyBackFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('baseFees-Sell', _liquidityFeeOnSell, _operationsFeeOnSell, _buyBackFeeOnSell, _holdersFeeOnSell);
	}
	// Blepe Rush1 Hour Fees
	function setRushHour1BuyFees(uint8 _liquidityFeeOnBuy,uint8 _operationsFeeOnBuy, uint8 _buyBackFeeOnBuy, uint8 _holdersFeeOnBuy) external onlyOwner {
		_setCustomBuyTaxPeriod(_Rush1, _liquidityFeeOnBuy, _operationsFeeOnBuy, _buyBackFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('Rush1Fees-Buy', _liquidityFeeOnBuy, _operationsFeeOnBuy, _buyBackFeeOnBuy, _holdersFeeOnBuy);
	}
	function setRushHour1SellFees(uint8 _liquidityFeeOnSell,uint8 _operationsFeeOnSell, uint8 _buyBackFeeOnSell, uint8 _holdersFeeOnSell) external onlyOwner {
		_setCustomSellTaxPeriod(_Rush1, _liquidityFeeOnSell, _operationsFeeOnSell, _buyBackFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('Rush1Fees-Sell', _liquidityFeeOnSell, _operationsFeeOnSell, _buyBackFeeOnSell, _holdersFeeOnSell);
	}
	// BitoshiRush2 Hour Fees
	function setRushHour2BuyFees(uint8 _liquidityFeeOnBuy,uint8 _operationsFeeOnBuy, uint8 _buyBackFeeOnBuy, uint8 _holdersFeeOnBuy) external onlyOwner {
		_setCustomBuyTaxPeriod(_Rush2, _liquidityFeeOnBuy, _operationsFeeOnBuy, _buyBackFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('Rush2Fees-Buy', _liquidityFeeOnBuy, _operationsFeeOnBuy, _buyBackFeeOnBuy, _holdersFeeOnBuy);
	}
	function setRushHour2SellFees(uint8 _liquidityFeeOnSell,uint8 _operationsFeeOnSell, uint8 _buyBackFeeOnSell, uint8 _holdersFeeOnSell) external onlyOwner {
		_setCustomSellTaxPeriod(_Rush2, _liquidityFeeOnSell, _operationsFeeOnSell, _buyBackFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('Rush2Fees-Sell', _liquidityFeeOnSell, _operationsFeeOnSell, _buyBackFeeOnSell, _holdersFeeOnSell);
	}
	function setUniswapRouter(address newAddress) external onlyOwner {
		require(newAddress != address(uniswapV2Router), "Blepe: The router already has that address");
		emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
		uniswapV2Router = IRouter(newAddress);
        dividendTracker.setUniswapRouter(newAddress);
	}
	function setMaxSellTransactionAmount(uint256 newValue) external onlyOwner {
		require(newValue != maxTxSellAmount, "Blepe: Cannot update maxTxSellAmount to same value");
		emit MaxTransactionAmountChange(newValue, maxTxSellAmount);
		maxTxSellAmount = newValue;
	}
	function setMaxBuyTransactionAmount(uint256 newValue) external onlyOwner {
		require(newValue != maxTxBuyAmount, "Blepe: Cannot update maxTxBuyAmount to same value");
		emit MaxTransactionAmountChange(newValue, maxTxBuyAmount);
		maxTxBuyAmount = newValue;
	}
	function setMaxWalletAmount(uint256 newValue) external onlyOwner {
		require(newValue != maxWalletAmount, "Blepe: Cannot update maxWalletAmount to same value");
		emit MaxWalletAmountChange(newValue, maxWalletAmount);
		maxWalletAmount = newValue;
	}
	function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
		require(newValue != minimumTokensBeforeSwap, "Blepe: Cannot update minimumTokensBeforeSwap to same value");
		emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
		minimumTokensBeforeSwap = newValue;
	}
    function setMinimumTokenBalanceForDividends(uint256 newValue) external onlyOwner {
        dividendTracker.setTokenBalanceForDividends(newValue);
    }
	function claimBNBOverflow() external onlyOwner {
	    uint256 amount = address(this).balance;
        (bool success,) = address(owner()).call{value : amount}("");
        if (success){
            emit ClaimBNBOverflow(amount);
        }
	}

	// Getters
	function isInRushHour() external view returns (bool) {
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _RushHourStartTimestamp  ? _tradingPausedTimestamp : block.timestamp;
		uint256 totalBlepeRushTime = _Rush1.timeInPeriod + _Rush2.timeInPeriod;
		uint256 timeSinceBlepeRush = currentTimestamp - _RushHourStartTimestamp;
		if(timeSinceBlepeRush < totalBlepeRushTime) {
			return true;
		} else {
			return false;
		}
	}
	function isInLaunch() external view returns (bool) {
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : block.timestamp;
		uint256 timeSinceLaunch = currentTimestamp - _launchStartTimestamp;
		uint256 blocksSinceLaunch = block.number - _launchBlockNumber;
		uint256 totalLaunchTime =  _launch1.timeInPeriod + _launch2.timeInPeriod + _launch3.timeInPeriod;

		if(_isLaunched && (timeSinceLaunch < totalLaunchTime || blocksSinceLaunch < _launch1.blocksInPeriod )) {
			return true;
		} else {
			return false;
		}
	}
	function BuyFees() external view returns (uint8, uint8, uint8, uint8){
		return (_base.liquidityFeeOnBuy, _base.operationsFeeOnBuy, _base.buyBackFeeOnBuy, _base.holdersFeeOnBuy);
	}
	function getBaseSellFees() external view returns (uint8, uint8, uint8, uint8){
		return (_base.liquidityFeeOnSell, _base.operationsFeeOnSell, _base.buyBackFeeOnSell, _base.holdersFeeOnSell);
	}
	function getRush1BuyFees() external view returns (uint8, uint8, uint8, uint8){
		return (_Rush1.liquidityFeeOnBuy, _Rush1.operationsFeeOnBuy, _Rush1.buyBackFeeOnBuy, _Rush1.holdersFeeOnBuy);
	}
	function getRush1SellFees() external view returns (uint8, uint8, uint8, uint8){
		return (_Rush2.liquidityFeeOnBuy, _Rush2.operationsFeeOnBuy, _Rush2.buyBackFeeOnBuy, _Rush2.holdersFeeOnBuy);
	}
	function getRush2SellFees() external view returns (uint8, uint8, uint8, uint8){
		return (_Rush2.liquidityFeeOnSell, _Rush2.operationsFeeOnSell, _Rush2.buyBackFeeOnSell, _Rush2.holdersFeeOnSell);
	}

	// Main
	function _transfer(
		address from,
		address to,
		uint256 amount
		) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isBuyFromLp = automatedMarketMakerPairs[from];
        bool isSelltoLp = automatedMarketMakerPairs[to];
        bool _isInLaunch = this.isInLaunch();
        uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : block.timestamp;

        if(!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
            require(isTradingEnabled, "Blepe: Trading is currently disabled.");
            require(!_isBlocked[to], "Blepe: Account is blocked");
            require(!_isBlocked[from], "Blepe: Account is blocked");
            if (_isInLaunch && (currentTimestamp - _launchStartTimestamp) <= 300 && isBuyFromLp) {
                require((currentTimestamp - _buyTimesInLaunch[to]) > 60, "Blepe: Cannot buy more than once per min in first 5min of launch");
            }
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                if (isBuyFromLp) {
                    require(amount <= maxTxBuyAmount, "Blepe: Buy amount exceeds the maxTxBuyAmount.");
                }
                if (isSelltoLp) {
                    require(amount <= maxTxSellAmount, "Blepe: Sell amount exceeds the maxTxSellAmount.");
                }
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require((balanceOf(to) + amount) <= maxWalletAmount, "Blepe: Expected wallet amount exceeds the maxWalletAmount.");
            }
        }

        _adjustTaxes(isBuyFromLp, isSelltoLp, _isInLaunch, to, from);
        bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

        if (
            isTradingEnabled &&
            canSwap &&
            !_swapping &&
            _totalFee > 0 &&
            automatedMarketMakerPairs[to]
        ) {
            _swapping = true;
            _swapAndLiquify();
            _swapping = false;
        }

        bool takeFee = !_swapping && isTradingEnabled;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        if (takeFee && _totalFee > 0) {
            uint256 fee = amount * _totalFee / 100;
            amount = amount - fee;
            super._transfer(from, address(this), fee);
        }

        if (_isInLaunch && (currentTimestamp - _launchStartTimestamp) <= 300) {
            if (to != owner() && isBuyFromLp  && (currentTimestamp - _buyTimesInLaunch[to]) > 60) {
                _buyTimesInLaunch[to] = currentTimestamp;
            }
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!_swapping) {
            uint256 gas = gasForProcessing;
            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {}
        }
	}
	function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp, bool isLaunching, address to, address from) private {
		uint256 blocksSinceLaunch = block.number - _launchBlockNumber;
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : block.timestamp;
		uint256 timeSinceLaunch = currentTimestamp - _launchStartTimestamp;
		uint256 timeSinceRush = currentTimestamp - _RushHourStartTimestamp;
		_liquidityFee = 0;
		_operationsFee = 0;
        _buyBackFee = 0;
		_holdersFee = 0;

		if (isBuyFromLp) {
		    _liquidityFee = _base.liquidityFeeOnBuy;
			_operationsFee = _base.operationsFeeOnBuy;
			_buyBackFee = _base.buyBackFeeOnBuy;
			_holdersFee = _base.holdersFeeOnBuy;

			if (isLaunching) {
				if (_isLaunched && blocksSinceLaunch < _launch1.blocksInPeriod) {
					_liquidityFee = _launch1.liquidityFeeOnBuy;
					_operationsFee = _launch1.operationsFeeOnBuy;
                    _buyBackFee = _launch1.buyBackFeeOnBuy;
					_holdersFee = _launch1.holdersFeeOnBuy;
				}
				else if (_isLaunched && timeSinceLaunch <= _launch2.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod) {
					_liquidityFee = _launch2.liquidityFeeOnBuy;
					_operationsFee = _launch2.operationsFeeOnBuy;
                    _buyBackFee = _launch2.buyBackFeeOnBuy;
					_holdersFee = _launch2.holdersFeeOnBuy;
				}
				else {
					_liquidityFee = _launch3.liquidityFeeOnBuy;
					_operationsFee = _launch3.operationsFeeOnBuy;
                    _buyBackFee = _launch3.buyBackFeeOnBuy;
					_holdersFee = _launch3.holdersFeeOnBuy;
				}
			}
			else if (timeSinceRush <= _Rush1.timeInPeriod) {
				_liquidityFee = _Rush1.liquidityFeeOnBuy;
				_operationsFee = _Rush1.operationsFeeOnBuy;
                _buyBackFee = _Rush1.buyBackFeeOnBuy;
				_holdersFee = _Rush1.holdersFeeOnBuy;
			}
			else if (timeSinceRush > _Rush1.timeInPeriod && timeSinceRush <= (_Rush1.timeInPeriod + _Rush2.timeInPeriod)) {
				_liquidityFee = _Rush2.liquidityFeeOnBuy;
				_operationsFee = _Rush2.operationsFeeOnBuy;
                _buyBackFee = _Rush2.buyBackFeeOnBuy;
				_holdersFee = _Rush2.holdersFeeOnBuy;
			}
		}
	    if (isSelltoLp) {
	    	_liquidityFee = _base.liquidityFeeOnSell;
			_operationsFee = _base.operationsFeeOnSell;
            _buyBackFee = _base.buyBackFeeOnSell;
			_holdersFee = _base.holdersFeeOnSell;

			if (isLaunching) {
				if (_isLaunched && blocksSinceLaunch < _launch1.blocksInPeriod) {
					_liquidityFee = _launch1.liquidityFeeOnSell;
					_operationsFee = _launch1.operationsFeeOnSell;
                    _buyBackFee = _launch1.buyBackFeeOnSell;
					_holdersFee = _launch1.holdersFeeOnSell;
				}
				else if (_isLaunched && timeSinceLaunch <= _launch2.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod) {
					_liquidityFee = _launch2.liquidityFeeOnSell;
					_operationsFee = _launch2.operationsFeeOnSell;
                    _buyBackFee = _launch2.buyBackFeeOnSell;
					_holdersFee = _launch2.holdersFeeOnSell;
				}
				else {
					_liquidityFee = _launch3.liquidityFeeOnSell;
					_operationsFee = _launch3.operationsFeeOnSell;
                    _buyBackFee = _launch3.buyBackFeeOnSell;
					_holdersFee = _launch3.holdersFeeOnSell;
				}
			}
			else if (timeSinceRush <= _Rush1.timeInPeriod) {
				_liquidityFee = _Rush1.liquidityFeeOnSell;
				_operationsFee = _Rush1.operationsFeeOnSell;
                _buyBackFee = _Rush1.buyBackFeeOnSell;
				_holdersFee = _Rush1.holdersFeeOnSell;
			}
			else if (timeSinceRush > _Rush1.timeInPeriod && timeSinceRush <= (_Rush1.timeInPeriod + _Rush2.timeInPeriod)) {
				_liquidityFee = _Rush2.liquidityFeeOnSell;
				_operationsFee = _Rush2.operationsFeeOnSell;
                _buyBackFee = _Rush2.buyBackFeeOnSell;
				_holdersFee = _Rush2.holdersFeeOnSell;
			}
		}
		if (!isSelltoLp && !isBuyFromLp && (_feeOnSelectedWalletTransfers[from] || _feeOnSelectedWalletTransfers[to])) {
			_liquidityFee = _base.liquidityFeeOnSell;
			_operationsFee = _base.operationsFeeOnSell;
            _buyBackFee = _base.buyBackFeeOnSell;
			_holdersFee = _base.holdersFeeOnSell;
		}
		else if (!isSelltoLp && !isBuyFromLp && !_feeOnSelectedWalletTransfers[from] && !_feeOnSelectedWalletTransfers[to] && _feeOnWalletTranfers) {
			_liquidityFee = _base.liquidityFeeOnBuy;
			_operationsFee = _base.operationsFeeOnBuy;
            _buyBackFee = _base.buyBackFeeOnBuy;
			_holdersFee = _base.holdersFeeOnBuy;
		}
		_totalFee = _liquidityFee + _operationsFee + _buyBackFee + _holdersFee;
		emit FeesApplied(_liquidityFee, _operationsFee, _buyBackFee, _holdersFee, _totalFee);
	}
	function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
		uint8 _liquidityFeeOnSell,
		uint8 _operationsFeeOnSell,
        uint8 _buyBackFeeOnSell,
		uint8 _holdersFeeOnSell
	) private {
		if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
			emit CustomTaxPeriodChange(_liquidityFeeOnSell, map.liquidityFeeOnSell, 'liquidityFeeOnSell', map.periodName);
			map.liquidityFeeOnSell = _liquidityFeeOnSell;
		}
		if (map.operationsFeeOnSell != _operationsFeeOnSell) {
			emit CustomTaxPeriodChange(_operationsFeeOnSell, map.operationsFeeOnSell, 'operationsFeeOnSell', map.periodName);
			map.operationsFeeOnSell = _operationsFeeOnSell;
		}
        if (map.buyBackFeeOnSell != _buyBackFeeOnSell) {
			emit CustomTaxPeriodChange(_buyBackFeeOnSell, map.buyBackFeeOnSell, 'buyBackFeeOnSell', map.periodName);
			map.buyBackFeeOnSell = _buyBackFeeOnSell;
		}
		if (map.holdersFeeOnSell != _holdersFeeOnSell) {
			emit CustomTaxPeriodChange(_holdersFeeOnSell, map.holdersFeeOnSell, 'holdersFeeOnSell', map.periodName);
			map.holdersFeeOnSell = _holdersFeeOnSell;
		}
	}
	function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
		uint8 _liquidityFeeOnBuy,
		uint8 _operationsFeeOnBuy,
        uint8 _buyBackFeeOnBuy,
		uint8 _holdersFeeOnBuy
		) private {
		if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
			emit CustomTaxPeriodChange(_liquidityFeeOnBuy, map.liquidityFeeOnBuy, 'liquidityFeeOnBuy', map.periodName);
			map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
		}
		if (map.operationsFeeOnBuy != _operationsFeeOnBuy) {
			emit CustomTaxPeriodChange(_operationsFeeOnBuy, map.operationsFeeOnBuy, 'operationsFeeOnBuy', map.periodName);
			map.operationsFeeOnBuy = _operationsFeeOnBuy;
		}
		if (map.buyBackFeeOnBuy != _buyBackFeeOnBuy) {
			emit CustomTaxPeriodChange(_buyBackFeeOnBuy, map.buyBackFeeOnBuy, 'buyBackFeeOnBuy', map.periodName);
			map.buyBackFeeOnBuy = _buyBackFeeOnBuy;
		}
		if (map.holdersFeeOnBuy != _holdersFeeOnBuy) {
			emit CustomTaxPeriodChange(_holdersFeeOnBuy, map.holdersFeeOnBuy, 'holdersFeeOnBuy', map.periodName);
			map.holdersFeeOnBuy = _holdersFeeOnBuy;
		}
	}
	function _swapAndLiquify() private {
		uint256 contractBalance = balanceOf(address(this));
		uint256 initialBNBBalance = address(this).balance;
		uint8 totalFeePrior = _totalFee;

		uint256 amountToLiquify = contractBalance * _liquidityFee / _totalFee / 2;
		uint256 amountToSwap = contractBalance - (amountToLiquify);

		_swapTokensForBNB(amountToSwap);

		uint256 BNBBalanceAfterSwap = address(this).balance - initialBNBBalance;
		uint256 totalBNBFee = _totalFee - (_liquidityFee / 2);

		uint256 amountBNBLiquidity = BNBBalanceAfterSwap * _liquidityFee / totalBNBFee / 2;
		uint256 amountBNBOperations = BNBBalanceAfterSwap * _operationsFee / totalBNBFee;
        uint256 amountBNBBuyBack = BNBBalanceAfterSwap * _buyBackFee / totalBNBFee;
		uint256 amountBNBHolders = BNBBalanceAfterSwap - (amountBNBLiquidity + amountBNBOperations + amountBNBBuyBack);

        payable(operationsWallet).transfer(amountBNBOperations);
        payable(buyBackWallet).transfer(amountBNBBuyBack);

        if (amountToLiquify > 0) {
			_addLiquidity(amountToLiquify, amountBNBLiquidity);
			emit SwapAndLiquify(amountToSwap, amountBNBLiquidity, amountToLiquify);
		}

        (bool dividendSuccess,) = address(dividendTracker).call{value: amountBNBHolders}("");
        if(dividendSuccess) {
            emit DividendsSent(amountBNBHolders);
        }

		_totalFee = totalFeePrior;
	}
	function _swapTokensForBNB(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}
	function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.addLiquidityETH{value: ethAmount}(
			address(this),
			tokenAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			liquidityWallet,
			block.timestamp
		);
	}
}

contract BlepeDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    uint256 public lastProcessedIndex;
    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("Blepe_Dividend_Tracker", "Blepe_Dividend_Tracker") {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 0 * (10**18);
    }
    function setRewardToken(address token) external onlyOwner {
		_setRewardToken(token);
	}
    function setUniswapRouter(address router) external onlyOwner {
		_setUniswapRouter(router);
	}
    function _transfer(address, address, uint256) internal override {
        require(false, "Blepe_Dividend_Tracker: No transfers allowed");
    }
    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludeFromDividends(account);
    }
    function setTokenBalanceForDividends(uint256 newValue) external onlyOwner {
        require(minimumTokenBalanceForDividends != newValue, "Blepe_Dividend_Tracker: minimumTokenBalanceForDividends already the value of 'newValue'.");
        minimumTokenBalanceForDividends = newValue;
    }
    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }
        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }
        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }
        processAccount(account, true);
    }
    function process(uint256 gas) public onlyOwner returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
        if(numberOfTokenHolders == 0) {
        return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;
            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }
            address account = tokenHoldersMap.keys[_lastProcessedIndex];
            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;
            uint256 newGasLeft = gasleft();
            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }
            gasLeft = newGasLeft;
        }
        lastProcessedIndex = _lastProcessedIndex;
        return (iterations, claims, lastProcessedIndex);
    }
    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }
        return false;
    }
}