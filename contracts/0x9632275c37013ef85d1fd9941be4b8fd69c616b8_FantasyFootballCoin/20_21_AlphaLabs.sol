// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

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

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
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

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

contract AlphaLabs is ERC20, Ownable {
    IRouter public uniswapV2Router;
    address public immutable uniswapV2Pair;

    string private constant _name = "Alpha Labs";
    string private constant _symbol = "$ALAB";
    uint8 private constant _decimals = 18;

    // initialSupply
    uint256 private constant totalTokens = 10_000_000 * (10**_decimals);
    uint256 public maxWalletAmount = 200_000 * 10 ** 18; //2%

    bool private _swapping;
    uint256 public minimumTokensBeforeSwap = totalTokens * 25 / 100000;

    address public taxWallet;

    struct CustomTaxPeriod {
        bytes23 periodName;
        uint8 blocksInPeriod;
        uint256 timeInPeriod;
        uint8 taxFeeOnBuy;
        uint8 taxFeeOnSell;
    }


    struct InitialData {
        uint32 buyTax;
        uint32 sellTax;
        uint32 maxWalletDiv;
        uint32 maxTxDiv;
        uint32 maxSwapDivisor;
    }

    struct TaxWallet {
        address wallet;
        uint32 ratio;
    }

    // Base taxes
    CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,20,99);

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public blacklists;

    uint8 private _taxFee;
    uint8 private _totalFee;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event WalletChange(string indexed indentifier, address indexed newWallet, address indexed oldWallet);
    event FeeChange(string indexed identifier, uint8 taxFee);
    event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event Swap(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
    event FeeOnSelectedWalletTransfersChange(address indexed account, bool newValue);
    event ClaimETHOverflow(uint256 amount);
    event FeesApplied(uint8 taxFee, uint256 totalFee);

    constructor(address c, address d, InitialData memory id, TaxWallet[] memory wallets ) ERC20(_name, _symbol) {
        taxWallet = wallets[0].wallet;
        _base.taxFeeOnBuy = uint8(id.buyTax/1000);
        _base.taxFeeOnSell = uint8(id.sellTax/1000);
        maxWalletAmount = totalTokens / id.maxTxDiv;
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Mainnet
        address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[taxWallet] = true;

        _isExcludedFromMaxWalletLimit[address(_uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(_uniswapV2Pair)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[taxWallet] = true;

        _mint(owner(), totalTokens);
    }

    receive() external payable {}

    // Setters
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner{
        require(_isExcludedFromMaxWalletLimit[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;
    }
    function isExcludedFromMaxWalletLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxWalletLimit[account];
    }
    function setWallets(address newtaxWallet) external onlyOwner {
        if(taxWallet != newtaxWallet) {
            require(newtaxWallet != address(0), "The taxWallet cannot be 0");
            emit WalletChange('taxWallet', newtaxWallet, taxWallet);
            taxWallet = newtaxWallet;
        }
    }
    function updateMaxWalletAmt(uint256 amount) external onlyOwner{
        require(amount >= 100);
        maxWalletAmount = amount * 10**18;
    }
    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }
    function isBlacklisting(address account) public view returns(bool) {
        return blacklists[account];
    }
    // Base fees
    function setFeesOnBuy(uint8 _taxFeeOnBuy) external onlyOwner {
        _setCustomBuyTaxPeriod(_base, _taxFeeOnBuy);
        emit FeeChange('baseFees-Buy', _taxFeeOnBuy);
    }
    function setFeesOnSell(uint8 _taxFeeOnSell) external onlyOwner {
        _setCustomSellTaxPeriod(_base, _taxFeeOnSell);
        emit FeeChange('baseFees-Sell', _taxFeeOnSell);
    }
    function setUniswapRouter(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IRouter(newAddress);
    }
    function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
        require(newValue != minimumTokensBeforeSwap, "Cannot update minimumTokensBeforeSwap to same value");
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }
    function claimETHOverflow() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = address(owner()).call{value : amount}("");
        if (success){
            emit ClaimETHOverflow(amount);
        }
    }

    // Getters
    function getBaseBuyFees() external view returns (uint8) {
        return (_base.taxFeeOnBuy);
    }
    function getBaseSellFees() external view returns (uint8) {
        return (_base.taxFeeOnSell);
    }

    // Main
    function _transfer(
        address from,
        address to,
        uint256 amount
        ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (!_isExcludedFromMaxWalletLimit[to]) {
            require((balanceOf(to) + amount) <= maxWalletAmount, "ERC20: Expected wallet amount exceeds the maxWalletAmount.");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isBuyFromLp = automatedMarketMakerPairs[from];
        bool isSelltoLp = automatedMarketMakerPairs[to];

        _adjustTaxes(isBuyFromLp, isSelltoLp);
        bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

        if (
            canSwap &&
            !_swapping &&
            _totalFee > 0 &&
            automatedMarketMakerPairs[to]
        ) {
            _swapping = true;
            _swap();
            _swapping = false;
        }

        bool takeFee = !_swapping;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        if (takeFee && _totalFee > 0) {
            uint256 fee = amount * _totalFee / 100;
            amount = amount - fee;
            super._transfer(from, address(this), fee);
        }

        super._transfer(from, to, amount);
    }
    function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp) private {
        _taxFee = 0;

        if (isBuyFromLp) {
            _taxFee = _base.taxFeeOnBuy;

        }
        if (isSelltoLp) {
            _taxFee = _base.taxFeeOnSell;
        }
        if (!isSelltoLp && !isBuyFromLp) {
            _taxFee = _base.taxFeeOnSell;
		}
        _totalFee = _taxFee;
        emit FeesApplied(_taxFee, _totalFee);
    }
    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
        uint8 _taxFeeOnSell
        ) private {

        if (map.taxFeeOnSell != _taxFeeOnSell) {
            emit CustomTaxPeriodChange(_taxFeeOnSell, map.taxFeeOnSell, 'taxFeeOnSell', map.periodName);
            map.taxFeeOnSell = _taxFeeOnSell;
        }
    }
    function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
        uint8 _taxFeeOnBuy
        ) private {
        if (map.taxFeeOnBuy != _taxFeeOnBuy) {
            emit CustomTaxPeriodChange(_taxFeeOnBuy, map.taxFeeOnBuy, 'taxFeeOnBuy', map.periodName);
            map.taxFeeOnBuy = _taxFeeOnBuy;
        }
    }
    function _swap() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        uint8 _totalFeePrior = _totalFee;

        uint256 amountToSwap = contractBalance;

        _swapTokensForETH(amountToSwap);

        uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
        uint256 totalETHFee = _totalFeePrior;
        uint256 amountETHtax = ETHBalanceAfterSwap * _taxFee / totalETHFee;

        payable(taxWallet).transfer(amountETHtax);

        _totalFee = _totalFeePrior;
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
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
}