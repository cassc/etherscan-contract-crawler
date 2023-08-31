// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// Telegram Chat: https://t.me/saintbot_deployers
// TOKEN DEPLOYED USING Saintbot!
// CONTRACT RENOUNCED AUTOMATICALLY
// THIS HAS LIQUIDITY LOCKED FOR 30 DAYS on UNCX, 0 OWNER TOKENS, ANTI-RUG BY DEFAULT!
// Saintbot
// Deploy and manage fair launch anti-rug tokens seamlessly and lightning-fast with low gas on our free-to-use Telegram bot.
// Website: saintbot.app/
// Twitter: twitter.com/TeamSaintbot
// Telegram Bot: https://t.me/saintbot_deployer_bot
// Docs: https://saintbots-organization.gitbook.io/saintbot-docs/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Factory {
    function ethLiquidityTax() external view returns (address);
    function tradingTaxes() external view returns (address);
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
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract ModelERC20V2 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    bool public transferDelayEnabled = true;
    address payable public _taxWallet;

    uint256 private constant _initialBuyTax = 5;
    uint256 private constant _initialSellTax = 5;
    uint256 private constant _finalBuyTax = 5;
    uint256 private constant _finalSellTax = 5;
    uint256 private constant _reduceBuyTaxAt = 25;
    uint256 private constant _reduceSellTaxAt = 25;
    uint256 private constant _preventSwapBefore = 5;
    uint256 public _buyCount = 0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100_000_000 * 10 ** _decimals;
    string private _name;
    string private _symbol;

    uint256 public constant _maxTxAmount = 3_000_000 * 10 ** _decimals;
    uint256 public constant _maxWalletSize = 6_000_000 * 10 ** _decimals;
    uint256 public constant _taxSwapThreshold = 500_000 * 10 ** _decimals;
    uint256 public constant _maxTaxSwap = 500_000 * 10 ** _decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap;
    bool private swapEnabled;

    bool private initialized;

    address public factory;

    // Since our contracts dont have ownership by default, we set this so scanners realize this
    address private constant _owner = address(0);

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function init(string memory _nameIn, string memory _symbolIn, address _user)
        external
        payable
        returns (address poolAddress)
    {
        require(!initialized, "reinit");

        _name = _nameIn;
        _symbol = _symbolIn;

        _taxWallet = payable(_user);
        _balances[address(this)] = _tTotal;
        _isExcludedFromFee[tx.origin] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        factory = msg.sender;

        inSwap = false;

        initialized = true;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _approve(address(this), address(uniswapV2Router), _tTotal);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 liquidityTax = msg.value / 100;

        (bool success,) = payable(Factory(msg.sender).ethLiquidityTax()).call{value: liquidityTax}("");
        require(success, "failed sending eth");

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this), balanceOf(address(this)), 0, 0, msg.sender, block.timestamp
        );

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);

        swapEnabled = true;
        tradingOpen = true;

        emit Transfer(address(0), _msgSender(), _tTotal);

        return uniswapV2Pair;
    }

    function _distributeMultisigs(uint256 _amount) private {
        Factory _factory = Factory(factory);

        address payable revShareMultisig = payable(_factory.tradingTaxes());

        (bool success,) = revShareMultisig.call{value: _amount}("");
        require(success, "failed sending eth");
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxAmount;

        if (from != _taxWallet && to != _taxWallet) {
            taxAmount = amount.mul((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax).div(100);
            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount.mul((_buyCount > _reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            if (
                !inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold
                    && _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 5000000000000000) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (!tradingOpen) {
            taxAmount = 0;
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));

        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        uint256 taxWalletAmount = (amount * 90) / 100;

        _taxWallet.transfer(taxWalletAmount);

        _distributeMultisigs(amount - taxWalletAmount);
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender() == _taxWallet || Factory(factory).tradingTaxes() == _msgSender());

        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }
    
    function owner() public view returns (address) {
        return _owner;
    }

    function updateTaxWallet(address _updateTaxWallet) external {
        require(msg.sender == _taxWallet, "auth");
        require(_updateTaxWallet != address(0), "address(0)");

        _taxWallet = payable(_updateTaxWallet);
    }
}