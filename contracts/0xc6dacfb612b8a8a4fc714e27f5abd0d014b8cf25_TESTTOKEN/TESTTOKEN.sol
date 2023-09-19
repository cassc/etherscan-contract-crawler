/**
 *Submitted for verification at Etherscan.io on 2023-09-04
*/

// This contract was deployed for free on welaunchit.org | T.me/welaunchit

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

contract ERC20 is Context, IERC20, IERC20Metadata {
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

	function transfer(address to, uint256 amount) public virtual override returns (bool) {
		address owner = _msgSender();
		_transfer(owner, to, amount);
		return true;
	}

	function allowance(
		address owner,
		address spender
	) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		address owner = _msgSender();
		_approve(owner, spender, amount);
		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) public virtual override returns (bool) {
		address spender = _msgSender();
		_spendAllowance(from, spender, amount);
		_transfer(from, to, amount);
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		address owner = _msgSender();
		_approve(owner, spender, allowance(owner, spender) + addedValue);
		return true;
	}

	function decreaseAllowance(
		address spender,
		uint256 subtractedValue
	) public virtual returns (bool) {
		address owner = _msgSender();
		uint256 currentAllowance = allowance(owner, spender);
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
		unchecked {
			_approve(owner, spender, currentAllowance - subtractedValue);
		}

		return true;
	}

	function _transfer(address from, address to, uint256 amount) internal virtual {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(from, to, amount);

		uint256 fromBalance = _balances[from];
		require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
		unchecked {
			_balances[from] = fromBalance - amount;
			// Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
			// decrementing then incrementing.
			_balances[to] += amount;
		}

		emit Transfer(from, to, amount);

		_afterTokenTransfer(from, to, amount);
	}

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply += amount;
		unchecked {
			// Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
			_balances[account] += amount;
		}
		emit Transfer(address(0), account, amount);

		_afterTokenTransfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		uint256 accountBalance = _balances[account];
		require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
		unchecked {
			_balances[account] = accountBalance - amount;
			// Overflow not possible: amount <= accountBalance <= totalSupply.
			_totalSupply -= amount;
		}

		emit Transfer(account, address(0), amount);

		_afterTokenTransfer(account, address(0), amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance != type(uint256).max) {
			require(currentAllowance >= amount, "ERC20: insufficient allowance");
			unchecked {
				_approve(owner, spender, currentAllowance - amount);
			}
		}
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

	function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

interface IUniswapV2Factory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);

	function allPairs(uint) external view returns (address pair);

	function allPairsLength() external view returns (uint);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setFeeTo(address) external;

	function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint amountADesired,
		uint amountBDesired,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB, uint liquidity);

	function addLiquidityETH(
		address token,
		uint amountTokenDesired,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB);

	function removeLiquidityETH(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external returns (uint amountToken, uint amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint amountA, uint amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint amountToken, uint amountETH);

	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapExactETHForTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external payable returns (uint[] memory amounts);

	function swapTokensForExactETH(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapExactTokensForETH(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapETHForExactTokens(
		uint amountOut,
		address[] calldata path,
		address to,
		uint deadline
	) external payable returns (uint[] memory amounts);

	function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

	function getAmountOut(
		uint amountIn,
		uint reserveIn,
		uint reserveOut
	) external pure returns (uint amountOut);

	function getAmountIn(
		uint amountOut,
		uint reserveIn,
		uint reserveOut
	) external pure returns (uint amountIn);

	function getAmountsOut(
		uint amountIn,
		address[] calldata path
	) external view returns (uint[] memory amounts);

	function getAmountsIn(
		uint amountOut,
		address[] calldata path
	) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external returns (uint amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint amountETH);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
}

abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		_transferOwnership(_msgSender());
	}

	modifier onlyOwner() {
		_checkOwner();
		_;
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	function _checkOwner() internal view virtual {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
	}

	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

contract TESTTOKEN is ERC20, Ownable {
	event TransferFee(uint256 makertingTax, uint256 devTax, uint256 indexed lpTax);
	event MarketingWalletUpdated(address newWallet, address oldWallet);
	event DevWalletUpdated(address newWallet, address oldWallet);

	struct TokenInfo {// hard code these values 
		string name;
		string symbol;
		address marketingFeeReceiver;
		address devFeeReceiver;
		uint256 marketingTaxBuy;
		uint256 marketingTaxSell;
		uint256 devTaxSell;
		uint256 devTaxBuy;
		uint256 lpTaxBuy;
		uint256 lpTaxSell;
		uint256 totalSupply;
		uint256 maxPercentageForWallet;
		uint256 maxPercentageForTx;
		//address swapRouter; // used outside constructor 
	}

	TokenInfo private tokenInfo;

	mapping(address => bool) public isExcludeFromFee;
	mapping(address => bool) public isExcludeFromTxLimit;
	mapping(address => bool) public isExcludeFromWalletLimit;

	address deployer;
	address public swapPair;
	address public weth;
	uint256 private deployerTax;
	uint256 public maxAmountForWallet;
	uint256 public maxAmountForTx;

	bool public swapping;

	uint256 tokensForMarketing;
	uint256 tokensForDev;
	uint256 tokensForLiquidity;
	uint256 tokensForDeployer;

	modifier onlySwapping() {
		swapping = true;
		_;
		swapping = false;
	}

	constructor() ERC20("TESTTOKEN", "TESTTOKEN") {
		deployer = 0xeb71D0766CAaEFdFf3A438e1455a929aA59b8e88;

		tokenInfo = TokenInfo({
        name: "TESTTOKEN",
       symbol: "TESTTOKEN",
        marketingFeeReceiver: 0x2f065014fb7EeDCd49bf7E0a4756d698767B06f0,
        devFeeReceiver: 0x2f065014fb7EeDCd49bf7E0a4756d698767B06f0,
        marketingTaxBuy: 5, // Example value, adjust accordingly
        marketingTaxSell: 5, // Example value
        devTaxBuy: 0, // Example value
        devTaxSell: 0, // Example value
        lpTaxBuy: 0, // Example value
        lpTaxSell: 0, // Example value
        totalSupply: 1000000 ether, // Example value
        maxPercentageForWallet: 100 ether, // Example value
        maxPercentageForTx: 100 ether // Example value
     //   swapRouter: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    });

	// pancake 0x10ED43C718714eb63d5aA57B78B54704E256024E
	// UNI 

		deployerTax = 0;

		uint256 uBuyFee = tokenInfo.devTaxBuy + tokenInfo.lpTaxBuy + tokenInfo.marketingTaxBuy;
		uint256 uSellFee = tokenInfo.devTaxSell + tokenInfo.lpTaxSell + tokenInfo.marketingTaxSell;
		require(uBuyFee <= 15 ether && uSellFee <= 15 ether, "TDP1"); // 15 % max fee here << 

		maxAmountForWallet = (tokenInfo.maxPercentageForWallet * tokenInfo.totalSupply) / 100 ether;
		maxAmountForTx = (tokenInfo.maxPercentageForTx * tokenInfo.totalSupply) / 100 ether;

		//address swapFactory = IUniswapV2Router02(tokenInfo.swapRouter).factory();
		//weth = IUniswapV2Router02(tokenInfo.swapRouter).WETH();
		//swapPair = IUniswapV2Factory(swapFactory).createPair(address(this), weth); // delete this line 

		isExcludeFromFee[address(this)] = true;
		isExcludeFromFee[tokenInfo.marketingFeeReceiver] = true;
		isExcludeFromFee[tokenInfo.devFeeReceiver] = true;

		isExcludeFromTxLimit[address(this)] = true;
		isExcludeFromTxLimit[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
		isExcludeFromTxLimit[tokenInfo.marketingFeeReceiver] = true;
		isExcludeFromTxLimit[tokenInfo.devFeeReceiver] = true;

		isExcludeFromWalletLimit[address(this)] = true;
		isExcludeFromWalletLimit[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
		isExcludeFromWalletLimit[tokenInfo.marketingFeeReceiver] = true;
		isExcludeFromWalletLimit[tokenInfo.devFeeReceiver] = true;
		//isExcludeFromWalletLimit[swapPair] = true;

		super._mint(address(this), tokenInfo.totalSupply); 
		//_approve(address(this), tokenInfo.swapRouter, type(uint256).max); 
	}

     function addLiquidity() external payable onlyOwner {
        // approve token transfer to cover all possible scenarios
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        _approve(address(this), address(_uniswapV2Router), totalSupply());
        // add the liquidity
        swapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        isExcludeFromWalletLimit[swapPair] = true;

        _uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this), //token address
            totalSupply(), // liquidity amount
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(), // LP tokens are sent to the owner
            block.timestamp
        );
    }

	function getTokenInfo() public view returns (TokenInfo memory tokenInfo) {
		tokenInfo = tokenInfo;
	}

	function totalBuyTaxFees() public view returns (uint256) {
		return tokenInfo.devTaxBuy + tokenInfo.lpTaxBuy + tokenInfo.marketingTaxBuy;
	}

	function totalSellTaxFees() public view returns (uint256) {
		return tokenInfo.devTaxSell + tokenInfo.lpTaxSell + tokenInfo.marketingTaxSell;
	}

	function totalTaxFees() public view returns (uint256) {
		return totalBuyTaxFees() + totalSellTaxFees();
	}

	function getMarketingBuyTax() external view returns (uint256) {
		return tokenInfo.marketingTaxBuy;
	}

	function getMarketingSellTax() external view returns (uint256) {
		return tokenInfo.marketingTaxSell;
	}

	function getDevBuyTax() external view returns (uint256) {
		return tokenInfo.devTaxBuy;
	}

	function getDevSellTax() external view returns (uint256) {
		return tokenInfo.devTaxSell;
	}

	function getLpBuyTax() external view returns (uint256) {
		return tokenInfo.lpTaxBuy;
	}

	function getLpSellTax() external view returns (uint256) {
		return tokenInfo.lpTaxSell;
	}

	function setExclusionFromFee(address account, bool value) public onlyOwner {
		isExcludeFromFee[account] = value;
	}

	function setExclusionFromTxLimit(address account, bool value) public onlyOwner {
		isExcludeFromTxLimit[account] = value;
	}

	function setExclusionFromWalletLimit(address account, bool value) public onlyOwner {
		isExcludeFromWalletLimit[account] = value;
	}

	function updateMarketingWallet(address newWallet) external onlyOwner {
		address oldWallet = tokenInfo.marketingFeeReceiver;
		tokenInfo.marketingFeeReceiver = newWallet;

		emit MarketingWalletUpdated(newWallet, oldWallet);
	}

	function updateDevWallet(address newWallet) external onlyOwner {
		address oldWallet = tokenInfo.marketingFeeReceiver;
		tokenInfo.devFeeReceiver = newWallet;

		emit DevWalletUpdated(newWallet, oldWallet);
	}

	function updateMarketingBuyTax(uint256 tax) external onlyOwner {
		tokenInfo.marketingTaxBuy = tax;
		require(totalBuyTaxFees() <= 15 ether, "TDP1");
	}

	function updateMarketingSellTax(uint256 tax) external onlyOwner {
		tokenInfo.marketingTaxSell = tax;
		require(totalSellTaxFees() <= 15 ether, "TDP1");
	}

	function updateDevBuyTax(uint256 tax) external onlyOwner {
		tokenInfo.devTaxBuy = tax;
		require(totalBuyTaxFees() <= 15 ether, "TDP1");
	}

	function updateDevSellTax(uint256 tax) external onlyOwner {
		tokenInfo.devTaxSell = tax;
		require(totalSellTaxFees() <= 15 ether, "TDP1");
	}

	function updateLpBuyTax(uint256 tax) external onlyOwner {
		tokenInfo.lpTaxBuy = tax;
		require(totalBuyTaxFees() <= 15 ether, "TDP1");
	}

	function updateLpSellTax(uint256 tax) external onlyOwner {
		tokenInfo.lpTaxSell = tax;
		require(totalSellTaxFees() <= 15 ether, "TDP1");
	}

	function updateMaxWalletAmount(uint256 maxWallet) external onlyOwner {
		require(maxWallet <= 100 ether && maxWallet >= 0.5 ether, "TDP4");
		tokenInfo.maxPercentageForWallet = maxWallet;
		maxAmountForWallet = (maxWallet * tokenInfo.totalSupply) / 100 ether;
	}

	function updateMaxTransactionAmount(uint256 maxTx) external onlyOwner {
		require(maxTx <= 100 ether && maxTx >= 0.5 ether, "TDP4");
		tokenInfo.maxPercentageForTx = maxTx;
		maxAmountForTx = (maxTx * tokenInfo.totalSupply) / 100 ether;
	}

	function _swapAndAddLiquidity() internal onlySwapping {
		uint256 totalFees = tokensForMarketing + tokensForDev + tokensForLiquidity + tokensForDeployer;

		require(totalFees > 0);

		address swapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
		uint256 halfLpFee = tokensForLiquidity / 2;
		totalFees -= halfLpFee;

		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = weth;

		uint256 beforeEthBalance = address(this).balance;

		IUniswapV2Router02(swapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
			totalFees,
			0,
			path,
			address(this),
			block.timestamp + 60
		);

		uint256 ethBalance = address(this).balance - beforeEthBalance;

		uint256 lpTaxFeeETH = (ethBalance * halfLpFee) / totalFees;
		uint256 marketingTaxFeeETH = (ethBalance * tokensForMarketing) / totalFees;
		uint256 devTaxFeeETH = (ethBalance * tokensForDev) / totalFees;

		if (marketingTaxFeeETH > 0) {
			payable(tokenInfo.marketingFeeReceiver).transfer(marketingTaxFeeETH);
		}
		if (devTaxFeeETH > 0) {
			payable(tokenInfo.devFeeReceiver).transfer(devTaxFeeETH);
		}
		

		if (lpTaxFeeETH > 0 && halfLpFee > 0) {
			IUniswapV2Router02(swapRouter).addLiquidityETH{ value: lpTaxFeeETH }(
				address(this),
				halfLpFee,
				0,
				0,
				owner(),
				block.timestamp + 60
			);
		}

		tokensForMarketing = 0;
		tokensForDev = 0;
		tokensForLiquidity = 0;
		tokensForDeployer = 0;

		emit TransferFee(tokensForMarketing, tokensForDev, tokensForLiquidity);
	}

	function _transfer(address from, address to, uint256 amount) internal override {
		if (!isExcludeFromTxLimit[from] && !isExcludeFromTxLimit[to])
			require(maxAmountForTx >= amount, "TDP2");
		if (!isExcludeFromWalletLimit[to])
			require((balanceOf(to) + amount) <= maxAmountForWallet, "TDP3");

		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}

		uint256 fees;
		if (
			!swapping &&
			!isExcludeFromFee[from] &&
			!isExcludeFromFee[to] &&
			(from == swapPair || to == swapPair)
		) {
			uint256 uBuyFee = totalBuyTaxFees() + deployerTax;
			uint256 uSellFee = totalSellTaxFees() + deployerTax;

			if (from == swapPair && uBuyFee > 0) {
				fees = (amount * uBuyFee) / (100 ether);
				tokensForDeployer += (fees * deployerTax) / uBuyFee;
				tokensForDev += (fees * tokenInfo.devTaxBuy) / uBuyFee;
				tokensForLiquidity += (fees * tokenInfo.lpTaxBuy) / uBuyFee;
				tokensForMarketing += (fees * tokenInfo.marketingTaxBuy) / uBuyFee;
			}
			if (to == swapPair && uSellFee > 0) {
				fees = (amount * uSellFee) / (100 ether);
				tokensForDeployer += (fees * deployerTax) / uSellFee;
				tokensForDev += (fees * tokenInfo.devTaxSell) / uSellFee;
				tokensForLiquidity += (fees * tokenInfo.lpTaxSell) / uSellFee;
				tokensForMarketing += (fees * tokenInfo.marketingTaxSell) / uSellFee;
			}

			super._transfer(from, address(this), fees);

			if (to == swapPair && fees > 0) {
				_swapAndAddLiquidity();
			}
		}

		super._transfer(from, to, amount - fees);
	}

	receive() external payable {}
}