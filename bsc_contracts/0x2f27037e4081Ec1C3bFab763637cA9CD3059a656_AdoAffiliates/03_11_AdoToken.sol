// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AdoAffiliates.sol";
import "./libraries/SafeMath.sol";
import "./LPManager.sol";
import "./abstracts/Ownable.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IPancakeSwapV2Pair.sol";
import "./interfaces/IPancakeSwapV2Factory.sol";
import "./interfaces/IPancakeSwapV2Router02.sol";

contract AdoToken is IBEP20, Ownable {
	using SafeMath for uint256;
	address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
	address public immutable deployer;
	address public mainLPToken;
	IPancakeSwapV2Router02 public pancakeSwapV2Router;
	IPancakeSwapV2Pair public pancakeSwapWETHV2Pair;
	IPancakeSwapV2Pair public pancakeSwapBUSDV2Pair;
	AdoAffiliates public affiliatesContract;
	LPManager public lpManager;
	IBEP20 public busdContract;

	string private _name = "ADO Protocol";
	string private _symbol = "ADO";
	uint8 private _decimals = 18;
	bool public swapEnabled = false;
	bool private _swapping = false;
	bool private _affiliateContractSet = false;
	bool private _busdContractSet = false;
	bool private _lpManagerSet = false;
	uint256 private _totalSupply = 1000000000 * (10 ** _decimals);
	uint256 private _tokensToLiqudate = _totalSupply.div(10000);
	uint256 private _lpWeight;
	uint256 private _buyBackBalance;
	uint256 private _feeDivider = 1;
	uint256 private _fee = 10;
	uint256 private _cursor;
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	mapping (address => bool) private _isExcludedFromFee;

	event ExcludedAddress(address indexed account);
	event TokenFeeUpdate(uint256 oldFee, uint256 newFee);
	event LPWeight(uint256 lp, uint256 bb);
	event TokenBalanceToLiqudate(uint256 indexed newValue, uint256 indexed oldValue);
	event BuyBackUpdate(address indexed token, uint256 indexed eth, uint256 busd);
	event MainLPSwitch(address indexed newToken);
	event MinTxValueForCommission(uint256 indexed oldValue, uint256 indexed newValue);

	modifier onlyDeployer() {
		require(_msgSender() == deployer, "Token: Only the token deployer can call this function");
		_;
	}

	constructor() {
		deployer = owner();
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[BURN_ADDRESS] = true;
		_balances[owner()] = _totalSupply;
		emit Transfer(address(0), owner(), _totalSupply);
	}

	receive() external payable {}

	function name() external view override returns (string memory) {
		return _name;
	}

	function symbol() external view override returns (string memory) {
		return _symbol;
	}

	function decimals() external view override returns (uint8) {
		return _decimals;
	}

	function totalSupply() external view override returns (uint256) {
		return _totalSupply;
	}

	function getOwner() public view returns (address) {
		return owner();
	}

	function fee() external view returns(uint256 value, uint256 divider) {
		value = _fee;
		divider = _feeDivider;
	}

	function balanceOf(address account) external view override returns (uint256) {
		return _balances[account];
	}

	function isExcludedFromFee(address account) external view returns(bool) {
		return _isExcludedFromFee[account];
	}

	function tokensToLiqudate() external view returns(uint256) {
		return _tokensToLiqudate;
	}

	function cursor() external view returns(uint256) {
		return _cursor;
	}

	function lpvsbb() external view returns(uint256 lp, uint256 bb) {
		uint256 weight = 10;
		lp = _lpWeight;
		bb = weight.sub(_lpWeight);
	}

	function buyBackBalance() external view returns(uint256 eth, uint256 busd) {
		eth = _buyBackBalance;
		busd = busdContract.balanceOf(address(this));
	}

	function referrerStats(address account) external view returns (uint256 transactions, uint256 bonus, uint256 totalValue, uint256 commissions) {
		return affiliatesContract.referrerStats(account);
	}

	function referredSwaps() external view returns (uint256) {
		return affiliatesContract.referredSwaps();
	}

	function minTxValue() external view returns (uint256) {
		return affiliatesContract.minTxValue();
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) external override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Token: transfer amount exceeds allowance"));
		return true;
	}

	function updateLPWeight(uint256 lpWeight) external onlyDeployer returns (bool) {
		require(lpWeight <= 10, "Token: LPWeight must be between 0 and 10");
		_lpWeight = lpWeight;
		emit LPWeight(_lpWeight, 10 - _lpWeight);
		return true;
	}

	function updateFee(uint256 newFee) external onlyDeployer returns (bool) {
		require(_fee != 0, "Token: The Fee has been removed");
		require(newFee != _fee, "Token: The Fee is already set to the requested value");
		require(newFee == 2 || newFee == 5 || newFee == 10, "Token: The fee can only be 2 5 or 10");
		emit TokenFeeUpdate(_fee, newFee);
		_fee = newFee;
		_feeDivider = newFee == 10 ? 1 : newFee == 5 ? 2 : 5;
		return true;
	}

	function updateMinTxValue(uint256 newValue) external onlyDeployer {
		require(newValue >= 10 ** 18 && newValue <= 100000 * 10 ** 18, "Token: minTxValue must be between 1 and 100.000 ADO");
		emit MinTxValueForCommission(affiliatesContract.minTxValue(), newValue);
		affiliatesContract.updateMinTxValue(newValue);
	}

	function updateTokensToLiqudate(uint256 newValue) external onlyDeployer returns (bool) {
		require(newValue >= 10 ** 18 && newValue <= 1000000 * 10 ** 18, "Token: numTokensToLiqudate must be between 100 and 1.000.000 ADO");
		emit TokenBalanceToLiqudate(newValue, _tokensToLiqudate);
		_tokensToLiqudate = newValue;
		return true;
	}

	function buyBack(uint256 amount) external onlyDeployer {
		if (mainLPToken == pancakeSwapV2Router.WETH()) {
			require(amount <= _buyBackBalance, "Token: Insufficient funds.");
			swapETHForTokens(BURN_ADDRESS, 0, amount);
			_buyBackBalance = address(this).balance;
		} else {
			require(amount <= busdContract.balanceOf(address(this)), "Token: Insufficient funds.");
			address[] memory path = new address[](2);
			path[0] = address(busdContract);
			path[1] = address(this);
			busdContract.approve(address(pancakeSwapV2Router), amount);
			pancakeSwapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
				amount,
				0,
				path,
				BURN_ADDRESS,
				block.timestamp
			);
		}
	}

	function processTax() external onlyDeployer {
		require(_balances[address(this)] > _tokensToLiqudate, "Token: Insufficient tokens");
		_swapping = true;
		swapAndAddLpOrBB();
		_swapping = false;
	}

	function excludeAddressFromFee(address account) external onlyDeployer returns (bool) {
		require(_isExcludedFromFee[account] == false, "Token: Account is already excluded");
		_isExcludedFromFee[account] = true;
		emit ExcludedAddress(account);
		return true;
	}

	function removeTax() external onlyDeployer returns (uint256) {
		_fee = 0;
		uint256 burnedAmount = _balances[address(this)];
		_transfer(address(this), BURN_ADDRESS, burnedAmount);
		_buyBackBalance = address(this).balance;
		uint256 dBurnedAmount = affiliatesContract.burnTheHouseDown();
		return burnedAmount.add(dBurnedAmount);
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "Token: approve from the zero address");
		require(spender != address(0), "Token: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function swapBUSDforETH(uint256 amount, address to) private returns (uint256) {
		uint256 initialBalance = address(this).balance;
		address[] memory path = new address[](2);
		path[0] = address(busdContract);
		path[1] = pancakeSwapV2Router.WETH();
		busdContract.approve(address(pancakeSwapV2Router), amount);
		pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount,
			0,
			path,
			to,
			block.timestamp
		);
		return address(this).balance.sub(initialBalance);
	}

	function swapETHforBUSD(uint256 amount, address to) private returns (uint256) {
		uint256 initialBalance = busdContract.balanceOf(address(this));
		address[] memory path = new address[](2);
		path[0] = pancakeSwapV2Router.WETH();
		path[1] = address(busdContract);
		pancakeSwapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, to, block.timestamp);
		return busdContract.balanceOf(address(this)).sub(initialBalance);
	}

	function swapETHForTokens(address recipient, uint256 minTokenAmount, uint256 amount) private {
		address[] memory path = new address[](2);
		path[0] = pancakeSwapV2Router.WETH();
		path[1] = address(this);
		pancakeSwapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
			minTokenAmount,
			path,
			recipient,
			block.timestamp
		);
	}
	
	function swapTokensForETH(uint256 tokenAmount) private returns (uint256) {
		uint256 pathlength = mainLPToken == pancakeSwapV2Router.WETH() ? 2 : 3;
		address[] memory path = new address[](pathlength);
		path[0] = address(this);
		path[1] = mainLPToken;
		if (mainLPToken != pancakeSwapV2Router.WETH()) {
			path[2] = pancakeSwapV2Router.WETH();
		}
		uint256 initialBalance = address(this).balance;
		_approve(address(this), address(pancakeSwapV2Router), tokenAmount);
		pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			address(this),
			block.timestamp
		);
		uint256 eth = address(this).balance.sub(initialBalance);
		return eth;
	}

	function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount) private {
		_approve(address(this), address(pancakeSwapV2Router), tokenAmount);
		pancakeSwapV2Router.addLiquidityETH{value: ethAmount}(
			address(this),
			tokenAmount,
			0,
			0,
			address(lpManager),
			block.timestamp
		);
	}

	function addLiquidityBUSD(uint256 tokenAmount, uint256 busdAmount) private {
		_approve(address(this), address(pancakeSwapV2Router), tokenAmount);
		busdContract.approve(address(pancakeSwapV2Router), busdAmount);
		pancakeSwapV2Router.addLiquidity(
			address(this),
			address(busdContract),
			tokenAmount,
			busdAmount,
			0,
			0,
			address(lpManager),
			block.timestamp
		);
	}

	function swapAndAddLpOrBB() private {
		_cursor++;
		uint256 swapTokensAmount = _tokensToLiqudate;
		bool addLP = _cursor.mod(10) < _lpWeight;
		if (addLP) {
			swapTokensAmount = _tokensToLiqudate.div(2);
		}
		uint256 eth = swapTokensForETH(swapTokensAmount);
		if (mainLPToken == pancakeSwapV2Router.WETH()) {
			if (addLP) {
				addLiquidityETH(swapTokensAmount, eth);
			}
			_buyBackBalance = address(this).balance;
		} else {
			uint256 busd = swapETHforBUSD(eth, address(this));
			if (addLP) {
				addLiquidityBUSD(swapTokensAmount, busd);
			}
		}
	}

	function _transfer(address from, address to, uint256 amount) private {
		require(from != address(0), "Token: Transfer from the zero address");
		require(to != address(0), "Token: Transfer to the zero address");
		require(amount > 0, "Token: Transfer amount must be greater than zero");
		require(swapEnabled || from == deployer, "Token: Public transfer has not yet been activated");
		require(_affiliateContractSet, "Token: Dividend Contract Token is not set");

		bool takeFee = true;
		if (
			_isExcludedFromFee[from] ||
			_isExcludedFromFee[to]
		) {
			takeFee = false;
		}
		if (!_swapping && _fee > 0 && takeFee) {
			uint256 contractTokenBalance = _balances[address(this)];
			bool canSwap = contractTokenBalance > _tokensToLiqudate;
			if (canSwap) {
				if (
					(mainLPToken == pancakeSwapV2Router.WETH() && from != address(pancakeSwapWETHV2Pair)) ||
					(mainLPToken == address(busdContract) && from != address(pancakeSwapBUSDV2Pair)))
				{
					_swapping = true;
					swapAndAddLpOrBB();
					_swapping = false;
				}
			}
			if (
				to == address(pancakeSwapWETHV2Pair) ||
				to == address(pancakeSwapBUSDV2Pair) ||
				from == address(pancakeSwapWETHV2Pair) ||
				from == address(pancakeSwapBUSDV2Pair)
			) {
				uint256 txFee = amount.div(100).mul(_fee);
				amount = amount.sub(txFee);
				_balances[from] = _balances[from].sub(txFee, "Token: Transfer amount exceeds balance");
				_balances[address(this)] = _balances[address(this)].add(txFee);
				emit Transfer(from, address(this), txFee);
			}
		}
		_balances[from] = _balances[from].sub(amount, "Token: Transfer amount exceeds balance");
		_balances[to] = _balances[to].add(amount);
		emit Transfer(from, to, amount);
	}

	function setAffiliateContract(address _adoAffiliates) external onlyOwner {
		affiliatesContract = AdoAffiliates(_adoAffiliates);
		_affiliateContractSet = true;
		_isExcludedFromFee[_adoAffiliates] = true;
	}

	function setLPManeger(address _lpManager) external onlyOwner {
		require(!_lpManagerSet, "Token: LP Maneger is already set");
		require(address(pancakeSwapV2Router) != address(0), "Token: PancakeSwapV2 Router is not set");
		require(address(pancakeSwapWETHV2Pair) != address(0), "Token: PancakeSwapV2 WETH Pair is not set");
		require(address(pancakeSwapBUSDV2Pair) != address(0), "Token: PancakeSwapV2 BUSD Pair is not set");
		lpManager = LPManager(payable(_lpManager));
		_lpManagerSet = true;
		_isExcludedFromFee[_lpManager] = true;
	}

	function setBUSDContract(address _busd) external onlyOwner {
		require(!_busdContractSet, "Token: BUSD Token is already set");
		busdContract = IBEP20(_busd);
		_busdContractSet = true;
	}

	function createPancakeSwapPairs(address PancakeSwapRouter) external onlyOwner {
		require(_affiliateContractSet, "Token: Affiliate Contract is not set");
		require(_busdContractSet, "Token: BUSD Token Contract is not set");
		pancakeSwapV2Router = IPancakeSwapV2Router02(PancakeSwapRouter);
		pancakeSwapWETHV2Pair = IPancakeSwapV2Pair(IPancakeSwapV2Factory(pancakeSwapV2Router
			.factory())
			.createPair(address(this), pancakeSwapV2Router.WETH()));
		mainLPToken = pancakeSwapV2Router.WETH();
		pancakeSwapBUSDV2Pair = IPancakeSwapV2Pair(IPancakeSwapV2Factory(pancakeSwapV2Router
			.factory())
			.createPair(address(this), address(busdContract)));
	}

	function enableSwap() external onlyDeployer returns (bool) {
		require(!swapEnabled, "Token: PublicSwap is already enabeled");
		require(address(pancakeSwapV2Router) != address(0), "Token: PancakeSwapV2 Router is not set");
		swapEnabled = true;
		return swapEnabled;
	}

	function swapETHForExactTokens(uint256 amountOut, address referrer) external payable returns (uint256) {
		address[] memory path = new address[](2);
		path[1] = address(this);
		if (mainLPToken == pancakeSwapV2Router.WETH()) {
			path[0] = pancakeSwapV2Router.WETH();
			pancakeSwapV2Router.swapETHForExactTokens{value: msg.value}(
				amountOut,
				path,
				_msgSender(),
				block.timestamp
			);
			uint256 ethBack = address(this).balance
				.sub(_buyBackBalance);
			(bool refund, ) = _msgSender().call{value: ethBack, gas: 3000}("");
			require(refund, "Token: Refund Failed");
		} else {
			uint256 initialBUSDBalance = busdContract.balanceOf(address(this));
			path[0] = address(busdContract);
			uint256 busdAmount = swapETHforBUSD(msg.value, address(this));
			busdContract.approve(address(pancakeSwapV2Router), busdAmount);
			pancakeSwapV2Router.swapTokensForExactTokens(
				amountOut,
				busdAmount,
				path,
				_msgSender(),
				block.timestamp
			);
			uint256 busdBack = busdContract.balanceOf(address(this))
				.sub(initialBUSDBalance);
			swapBUSDforETH(busdBack, _msgSender());
		}
		uint256 txFee = amountOut.div(100).mul(_fee);
		uint256 amount = amountOut.sub(txFee);
		if (referrer != address(0) && referrer != _msgSender() && _fee > 0) {
			affiliatesContract.payCommission(referrer, amount, _feeDivider);
		}
		return amount;
	}

	function swapBUSDForExactTokens(uint256 busdAmount, uint256 amountOut, address referrer) external returns (uint256) {
		uint256 initialBUSDBalance = busdContract.balanceOf(address(this));
		busdContract.transferFrom(_msgSender(), address(this), busdAmount);
		address[] memory path = new address[](2);
		path[1] = address(this);
		if (mainLPToken == pancakeSwapV2Router.WETH()) {
			uint256 eth = swapBUSDforETH(busdAmount, address(this));
			path[0] = pancakeSwapV2Router.WETH();
			pancakeSwapV2Router.swapETHForExactTokens{value: eth}(
				amountOut,
				path,
				_msgSender(),
				block.timestamp
			);
			uint256 ethBack = address(this).balance
				.sub(_buyBackBalance);
			swapETHforBUSD(ethBack, _msgSender());
		} else {
			path[0] = address(busdContract);
			busdContract.approve(address(pancakeSwapV2Router), busdAmount);
			pancakeSwapV2Router.swapTokensForExactTokens(
				amountOut,
				busdAmount,
				path,
				_msgSender(),
				block.timestamp
			);
			uint256 busdBack = busdContract.balanceOf(address(this))
				.sub(initialBUSDBalance);
			busdContract.transfer(_msgSender(), busdBack);
		}
		uint256 txFee = amountOut.div(100).mul(_fee);
		uint256 amount = amountOut.sub(txFee);
		if (referrer != address(0) && referrer != _msgSender() && _fee > 0) {
			affiliatesContract.payCommission(referrer, amount, _feeDivider);
		}
		return amount;
	}

	function swapExactETHForTokens(uint256 amountOutMin, address referrer) external payable returns (uint256) {
		uint256 initialTokenBalance = _balances[_msgSender()];
		if (mainLPToken == pancakeSwapV2Router.WETH()) {
			swapETHForTokens(_msgSender(), amountOutMin, msg.value);
		} else {
			uint256 busdAmount = swapETHforBUSD(msg.value, address(this));
			address[] memory path = new address[](2);
			path[0] = address(busdContract);
			path[1] = address(this);
			busdContract.approve(address(pancakeSwapV2Router), busdAmount);
			pancakeSwapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
				busdAmount,
				amountOutMin,
				path,
				_msgSender(),
				block.timestamp
			);
		}
		uint256 amount = _balances[_msgSender()].sub(initialTokenBalance);
		if (referrer != address(0) && referrer != _msgSender() && _fee > 0) {
			affiliatesContract.payCommission(referrer, amount, _feeDivider);
		}
		return amount;
	}

	function swapExactBUSDForTokens(uint256 busdAmount, uint256 amountOutMin, address referrer) external returns (uint256) {
		busdContract.transferFrom(_msgSender(), address(this), busdAmount);
		uint256 initialTokenBalance = _balances[_msgSender()];
		if (mainLPToken == pancakeSwapV2Router.WETH()) {
			uint256 eth = swapBUSDforETH(busdAmount, address(this));
			swapETHForTokens(_msgSender(), amountOutMin, eth);
		} else {
			address[] memory path = new address[](2);
			path[0] = address(busdContract);
			path[1] = address(this);
			busdContract.approve(address(pancakeSwapV2Router), busdAmount);
			pancakeSwapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
				busdAmount,
				amountOutMin,
				path,
				_msgSender(),
				block.timestamp
			);
		}
		uint256 amount = _balances[_msgSender()].sub(initialTokenBalance);
		if (referrer != address(0) && referrer != _msgSender() && _fee > 0) {
			affiliatesContract.payCommission(referrer, amount, _feeDivider);
		}
		return amount;
	}

	function switchPool(uint bp) external onlyDeployer returns (address) {
		require(bp <= 5 , "Token: Burn to high");
		_swapping = true;
		(address lptoken, bool updateBB) = lpManager.switchPool(bp);
		_swapping = false;
		mainLPToken = lptoken;
		if (updateBB) {
			_buyBackBalance = address(this).balance;
		}
		emit MainLPSwitch(mainLPToken);
		return lptoken;
	}

	function addToBuyBack() external payable returns (uint256) {
		require(msg.value > 0, "Token: Transfer amount must be greater than zero");
		_buyBackBalance = _buyBackBalance.add(msg.value);
		emit BuyBackUpdate(_msgSender(), msg.value, 0);
		return _buyBackBalance;
	}

	function swapBuyBack2BNB() external onlyDeployer returns (uint256) {
		uint256 busd = busdContract.balanceOf(address(this));
		require(busd > 0, "Token: Insufficient funds.");
		uint256 eth = swapBUSDforETH(busdContract.balanceOf(address(this)), address(this));
		emit BuyBackUpdate(pancakeSwapV2Router.WETH(), eth, busd);
		_buyBackBalance = _buyBackBalance.add(eth);
		return eth;
	}

	function swapBuyBack2BUSD() external onlyDeployer returns (uint256) {
		require(_buyBackBalance > 0, "Token: Insufficient funds.");
		uint256 busd = swapETHforBUSD(_buyBackBalance, address(this));
		emit BuyBackUpdate(address(busdContract), _buyBackBalance, busd);
		_buyBackBalance = 0;
		return busd;
	}
}