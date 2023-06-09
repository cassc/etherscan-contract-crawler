/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
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

library Address {
	function isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		(bool success, ) = recipient.call{value: amount}("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}

	function functionCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
		functionCallWithValue(
			target,
			data,
			value,
			"Address: low-level call with value failed"
		);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{value: value}(
		data
		);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data)
	internal
	view
	returns (bytes memory)
	{
		return
		functionStaticCall(
			target,
			data,
			"Address: low-level static call failed"
		);
	}

	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");

		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return
		functionDelegateCall(
			target,
			data,
			"Address: low-level delegate call failed"
		);
	}

	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");

		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) private pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
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

    constructor() {
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

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
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

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract xBBPP is Ownable, ERC20 {
    using Address for address;

    IRouter public uniswapV2Router;
    address public immutable uniswapV2Pair;

    string private constant _name = "xBBPP";
    string private constant _symbol = "xBBPP";

    bool public isTradingEnabled;

    uint256 public initialSupply = 100000000 * (10**18);

    // max wallet is 1% of initialSupply
    uint256 public maxWalletAmount = initialSupply * 1 / 100;

    bool private _swapping;
    uint256 public minimumTokensBeforeSwap = initialSupply * 25 / 100000;

    address public buyBackWallet;
    address public stakingAddress;
    address public targetBAddress;

    struct CustomTaxPeriod {
        bytes23 periodName;
        uint8 buyBackFeeOnBuy;
        uint8 buyBackFeeOnSell;
        uint8 targetBFeeOnBuy;
        uint8 targetBFeeOnSell;
        uint8 stakingFeeOnBuy;
        uint8 stakingFeeOnSell;
        uint8 feeOnTransfer;
    }

    CustomTaxPeriod private _base = CustomTaxPeriod("base", 0, 25, 20, 50, 0, 25, 50);

    mapping(address => bool) private _isAllowedToTradeWhenDisabled;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint8 private _totalFee;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event WalletChange(string indexed indentifier,address indexed newWallet,address indexed oldWallet);
    event FeeChange(string indexed identifier,uint8 buyBackFee, uint8 targetBFee, uint8 stakingFee,uint8 feeOnTransfer);
    event CustomTaxPeriodChange(uint256 indexed newValue,uint256 indexed oldValue,string indexed taxType,bytes23 period);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ClaimOverflow(address token, uint256 amount);
    event TradingStatusChange(bool indexed newValue, bool indexed oldValue);
    event Minted(address indexed mintAddress, uint256 indexed mintAmount);
    event FeesApplied(uint8 totalFee);
    event StakingTokensSent(uint256 tokensSent);

    constructor() ERC20(_name, _symbol) {
        buyBackWallet = owner();
        stakingAddress = owner();
        targetBAddress = owner();

        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(address(this),_uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isAllowedToTradeWhenDisabled[owner()] = true;
        _isAllowedToTradeWhenDisabled[address(this)] = true;

        _isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;

        _mint(owner(), initialSupply);
    }

    receive() external payable {}

    function activateTrading() external onlyOwner {
        isTradingEnabled = true;
        emit TradingStatusChange(true, false);
    }
    function deactivateTrading() external onlyOwner {
        isTradingEnabled = false;
        emit TradingStatusChange(false, true);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value,"xBBPP: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
        _isAllowedToTradeWhenDisabled[account] = allowed;
        emit AllowedWhenTradingDisabledChange(account, allowed);
    }
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFee[account] != excluded,"xBBPP: Account is already the value of 'excluded'");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded,"xBBPP: Account is already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }
    function setWallets(address newBuyBackWallet,address newStakingAddress, address newTargetBAddress) external onlyOwner {
        if (buyBackWallet != newBuyBackWallet) {
            require(newBuyBackWallet != address(0), "xBBPP: The buyBackWallet cannot be 0");
            emit WalletChange("buyBackWallet", newBuyBackWallet, buyBackWallet);
            buyBackWallet = newBuyBackWallet;
        }
        if (targetBAddress != newTargetBAddress) {
            require(newTargetBAddress != address(0), "xBBPP: The targetBAddress cannot be 0");
            emit WalletChange("targetBAddress", newTargetBAddress, targetBAddress);
            targetBAddress = newTargetBAddress;
        }
        if (stakingAddress != newStakingAddress) {
            require(newStakingAddress != address(0), "xBBPP: The stakingAddress cannot be 0");
            emit WalletChange("stakingAddress", newStakingAddress, stakingAddress);
            stakingAddress = newStakingAddress;
        }
    }
    function setBaseFeesOnBuy(uint8 _buyBackFeeOnBuy, uint8 _targetBFeeOnBuy, uint8 _stakingFeeOnBuy,uint8 _feeOnTransfer) external onlyOwner {
        require(_buyBackFeeOnBuy + _targetBFeeOnBuy + _stakingFeeOnBuy + _feeOnTransfer <= 150, "xBBPP: Collective taxes must be less than 15%");
        _setCustomBuyTaxPeriod(_base,_buyBackFeeOnBuy,_targetBFeeOnBuy,_stakingFeeOnBuy,_feeOnTransfer);
        emit FeeChange("baseFees-Buy",_buyBackFeeOnBuy,_targetBFeeOnBuy,_stakingFeeOnBuy,_feeOnTransfer);
    }
    function setBaseFeesOnSell(uint8 _buyBackFeeOnSell,uint8 _targetBFeeOnSell, uint8 _stakingFeeOnSell) external onlyOwner {
        require(_buyBackFeeOnSell + _targetBFeeOnSell + _stakingFeeOnSell + _base.feeOnTransfer <= 150, "xBBPP: Collective taxes must be less than 15%");
        _setCustomSellTaxPeriod(_base,_buyBackFeeOnSell,_targetBFeeOnSell, _stakingFeeOnSell);
        emit FeeChange("baseFees-Sell",_buyBackFeeOnSell,_targetBFeeOnSell, _stakingFeeOnSell, _base.feeOnTransfer);
    }
    function setUniswapRouter(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router),"xBBPP: The router already has that address");
        emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
        uniswapV2Router = IRouter(newAddress);
    }
    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxWalletAmount,"xBBPP: Cannot update maxWalletAmount to same value");
        require(newValue >= initialSupply * 5 / 1000, "xBBPP: Cannot update maxWalletAmount to value less than 0.5% of supply");
        emit MaxWalletAmountChange(newValue, maxWalletAmount);
        maxWalletAmount = newValue;
    }
    function setMinimumTokensBeforeSwap(uint256 newValue) external onlyOwner {
        require(newValue != minimumTokensBeforeSwap,"xBBPP: Cannot update minimumTokensBeforeSwap to same value");
        emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newValue;
    }
    function mintToAddress(address mintAddress, uint256 mintAmount) external onlyOwner {
        super._mint(mintAddress, mintAmount);
        emit Minted(mintAddress, mintAmount);
    }
    function claimETHOverflow(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "xBBPP: Cannot send more than contract balance");
        (bool success, ) = address(owner()).call{ value: amount }("");
        if (success) {
            emit ClaimOverflow(uniswapV2Router.WETH(), amount);
        }
    }

    // Getters
    function getBaseBuyFees() external view returns (uint8,uint8,uint8,uint8) {
        return (_base.buyBackFeeOnBuy,_base.targetBFeeOnBuy,_base.stakingFeeOnBuy,_base.feeOnTransfer);
    }
    function getBaseSellFees() external view returns (uint8,uint8,uint8) {
        return (_base.buyBackFeeOnSell,_base.targetBFeeOnSell,_base.stakingFeeOnSell);
    }
    // Main
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
            require(isTradingEnabled, "xBBPP: Trading is currently disabled.");
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require((balanceOf(to) + amount) <= maxWalletAmount, "xBBPP: Expected wallet amount exceeds the maxWalletAmount.");
            }
        }

        _totalFee = automatedMarketMakerPairs[from] ? (_base.buyBackFeeOnBuy + _base.targetBFeeOnBuy + _base.stakingFeeOnBuy) : automatedMarketMakerPairs[to] ? (_base.buyBackFeeOnSell + _base.targetBFeeOnSell + _base.stakingFeeOnSell) : _base.feeOnTransfer;
        emit FeesApplied(_totalFee);

        if (
            isTradingEnabled &&
            balanceOf(address(this)) >= minimumTokensBeforeSwap &&
            !_swapping &&
            _totalFee > 0 &&
            automatedMarketMakerPairs[to]
        ) {
            _swapping = true;
            _swap();
            _swapping = false;
        }

        bool takeFee = !_swapping && isTradingEnabled;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (takeFee && _totalFee > 0) {
            uint256 fee = (amount * _totalFee) / 1000;
            amount = amount - fee;
            super._transfer(from, address(this), fee);
        }
        super._transfer(from, to, amount);
    }
    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,uint8 _buyBackFeeOnSell,uint8 _targetBFeeOnSell, uint8 _stakingFeeOnSell) private {
        if (map.buyBackFeeOnSell != _buyBackFeeOnSell) {
            emit CustomTaxPeriodChange(_buyBackFeeOnSell,map.buyBackFeeOnSell,"buyBackFeeOnSell",map.periodName);
            map.buyBackFeeOnSell = _buyBackFeeOnSell;
        }
        if (map.targetBFeeOnSell != _targetBFeeOnSell) {
            emit CustomTaxPeriodChange(_targetBFeeOnSell,map.targetBFeeOnSell,"targetBFeeOnSell",map.periodName);
            map.targetBFeeOnSell = _targetBFeeOnSell;
        }
        if (map.stakingFeeOnSell != _stakingFeeOnSell) {
            emit CustomTaxPeriodChange(_stakingFeeOnSell,map.stakingFeeOnSell,"stakingFeeOnSell",map.periodName);
            map.stakingFeeOnSell = _stakingFeeOnSell;
        }
    }
    function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,uint8 _buyBackFeeOnBuy,uint8 _targetBFeeOnBuy, uint8 _stakingFeeOnBuy,uint8 _feeOnTransfer) private {
        if (map.buyBackFeeOnBuy != _buyBackFeeOnBuy) {
            emit CustomTaxPeriodChange(_buyBackFeeOnBuy,map.buyBackFeeOnBuy,"buyBackFeeOnBuy",map.periodName);
            map.buyBackFeeOnBuy = _buyBackFeeOnBuy;
        }
        if (map.targetBFeeOnBuy != _targetBFeeOnBuy) {
            emit CustomTaxPeriodChange(_targetBFeeOnBuy,map.targetBFeeOnBuy,"targetBFeeOnBuy",map.periodName);
            map.targetBFeeOnBuy = _targetBFeeOnBuy;
        }
        if (map.stakingFeeOnBuy != _stakingFeeOnBuy) {
            emit CustomTaxPeriodChange(_stakingFeeOnBuy,map.stakingFeeOnBuy,"stakingFeeOnBuy",map.periodName);
            map.stakingFeeOnBuy = _stakingFeeOnBuy;
        }
        if (map.feeOnTransfer != _feeOnTransfer) {
            emit CustomTaxPeriodChange(_feeOnTransfer,map.feeOnTransfer,"feeOnTransfer",map.periodName);
            map.feeOnTransfer = _feeOnTransfer;
        }
    }
    function _swap() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialETHBalance = address(this).balance;
        uint8 totalFeePrior = _totalFee;

        uint256 amountForStaking = (contractBalance * _base.stakingFeeOnSell) / _totalFee;
        uint256 amountToSwap = contractBalance - amountForStaking;

        _swapTokensForETH(amountToSwap);

        uint256 ETHBalanceAfterSwap = address(this).balance - initialETHBalance;
        uint256 totalETHFee = totalFeePrior - _base.stakingFeeOnSell;
        uint256 amountETHBuyback = ETHBalanceAfterSwap * _base.buyBackFeeOnSell / totalETHFee;
        uint256 amountETHTargetB = ETHBalanceAfterSwap - amountETHBuyback;

        Address.sendValue(payable(buyBackWallet), amountETHBuyback);
        Address.sendValue(payable(targetBAddress), amountETHTargetB);

        (bool stakingSuccess) = IERC20(address(this)).transfer(address(stakingAddress), amountForStaking);
			if(stakingSuccess) {
			emit StakingTokensSent(amountForStaking);
		}

        _totalFee = totalFeePrior;
    }
    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            1, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}