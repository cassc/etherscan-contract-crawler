/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

// SPDX-License-Identifier: UNLICENSE

/**
 * website: https://headdy.io/
 * telegram: https://t.me/DynamiteHeaddyETH
 * twitter: https://twitter.com/HeaddyETH
 */

pragma solidity ^0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
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

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
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

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract DynamiteHeaddy is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    string private constant _name = "Dynamite Headdy";
    string private constant _symbol = "HEADDY";
    uint256 private constant _supply = 9000000000;
    uint8 private constant _decimals = 9;

    bool private tradingEnabled = false;
    bool private swapEnabled = false;
    bool private swapping;
    uint256 public swapTokensAtAmount;
    uint256 private maxTaxSwap;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; //Keep last transfer timestamp temporarily during launch
    bool private transferDelayEnabled = true; //Protect launch from bots

    address public maketingWallet;
    address public rewardWallet;
    uint256 public buyFee;
    uint256 public sellFee;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;

    mapping(address => bool) private isExcludedFromFees;
    mapping(address => bool) private isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    constructor() ERC20(_name, _symbol, _decimals) {
        uint256 totalSupply = _supply.mul(10**decimals());
        maxTransactionAmount = totalSupply.mul(15).div(1000);
        maxWallet = totalSupply.mul(2).div(100);
        swapTokensAtAmount = totalSupply.mul(1).div(10000);
        maxTaxSwap = totalSupply.mul(12).div(100);

        maketingWallet = _msgSender();
        rewardWallet = address(0xA9d2D9cff588318326649E48F560Fc5B43E5d77C);
        buyFee = 18;
        sellFee = 35;

        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[maketingWallet] = true;
        isExcludedFromFees[rewardWallet] = true;

        isExcludedMaxTransactionAmount[owner()] = true;
        isExcludedMaxTransactionAmount[address(this)] = true;
        isExcludedMaxTransactionAmount[address(0xdead)] = true;
        isExcludedMaxTransactionAmount[maketingWallet] = true;
        isExcludedMaxTransactionAmount[rewardWallet] = true;

        // REWARD POOL
        _mint(rewardWallet, totalSupply.mul(9).div(100));
        _mint(address(0xaA6ed543C87243E840b7e1B43c6CE00da5927471), totalSupply.mul(1).div(100));
        _mint(_msgSender(), totalSupply.mul(90).div(100));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }

    function openTrading() external onlyOwner() {
        require(!tradingEnabled, "Trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        isExcludedMaxTransactionAmount[address(_uniswapV2Router)] = true;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        automatedMarketMakerPairs[address(uniswapV2Pair)] = true;
        isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;

        _approve(address(this), address(uniswapV2Router), totalSupply());
        uniswapV2Router.addLiquidityETH{value : address(this).balance}(
            address(this),
            balanceOf(address(this)).mul(100 - buyFee).div(100),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        tradingEnabled = swapEnabled = true;
    }

    function toggleSwapEnabled() external onlyOwner {
        swapEnabled = !swapEnabled;
    }

    function toggleTransferDelayEnabled() external onlyOwner {
        transferDelayEnabled = !transferDelayEnabled;
    }

    function setMaxWalletAndTxnAmount(uint256 _maxTransactionAmount, uint256 _maxWallet) external onlyOwner {
        _maxTransactionAmount = _maxTransactionAmount.mul(10**decimals());
        _maxWallet = _maxWallet.mul(10**decimals());
        uint256 limit = totalSupply().mul(5).div(1000);
        require(_maxTransactionAmount >= limit && _maxWallet >= limit, "Cannot set maxWallet or maxTxn lower than 0.5%");
        maxTransactionAmount = _maxTransactionAmount;
        maxWallet = _maxWallet;
    }

    function removeLimits() external onlyOwner {
        maxTransactionAmount = maxWallet = totalSupply();
        transferDelayEnabled = false;
    }

    function setFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= 5, "Must keep buy fee at 5% or less");
        require(_sellFee <= 5, "Must keep sell fee at 5% or less");
        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function removeFees() external onlyOwner {
        buyFee = sellFee = 3;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address.");
        require(to != address(0), "ERC20: transfer to the zero address.");
        require(amount > 0, "ERC20: transfer amount must be greater than zero.");

        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
            if (!tradingEnabled) {
                require(isExcludedFromFees[from] || isExcludedFromFees[to], "Trading is not active.");
            }

            //if the transfer delay is enabled at launch
            if (transferDelayEnabled) {
                if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one purchase per block allowed.");
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (automatedMarketMakerPairs[from] && !isExcludedMaxTransactionAmount[to]) {
                require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the max transaction amount.");
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded.");
            } else if (automatedMarketMakerPairs[to] && !isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the max transaction amount.");
            } else if (!isExcludedMaxTransactionAmount[to]) {
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded.");
            }
        }

        bool takeFee = !swapping;
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellFee > 0) {
                fees = amount.mul(sellFee).div(100);
            } else if (automatedMarketMakerPairs[from] && buyFee > 0) {
                fees = amount.mul(buyFee).div(100);
            }
            amount -= fees;
        }

        uint256 contractBalance = balanceOf(address(this));
        bool canSwap = contractBalance >= swapTokensAtAmount;
        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapping = true;
            bool success;
            swapTokensForEth(min(amount, min(contractBalance, maxTaxSwap)));
            (success, ) = address(maketingWallet).call{value: address(this).balance}("");
            swapping = false;
        }

        if (fees > 0) {
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    //Use this in case ETH are sent to the contract by mistake
    function rescueETH(uint256 mount) external onlyOwner {
        require(address(this).balance >= mount, "Insufficient balance");
        payable(_msgSender()).transfer(mount);
    }

    //Use this in case ERC20 Tokens are sent to the contract by mistake
    function rescueAnyERC20Tokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
        require(_tokenAddress != address(this), "Owner can't claim contract's balance of its own tokens");
        ERC20(_tokenAddress).transfer(_to, _amount);
    }

    receive() external payable {}
}