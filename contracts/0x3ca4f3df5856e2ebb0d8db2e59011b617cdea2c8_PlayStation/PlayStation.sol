/**
 *Submitted for verification at Etherscan.io on 2023-08-24
*/

/**
 *Submitted for verification at Etherscan.io on 2023-08-22
 */
/*

Telegram: https://t.me/PlayStationFunToken_Eth
Website:  https://ps1.live
Twitter:  https://twitter.com/PS_EthNostalgia

 ################################
 ||                            ||
 ||        Play Station   
 ||    FUN NOSTALGIC FEELING   ||
 ||                            ||
 ################################
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract PlayStation is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    address payable public _marketingWallet;

    uint256 public buyTax = 40;
    uint256 public sellTax = 70;
    uint256 public _buyCount = 0;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 100000000 * 10**_decimals;
    string private constant _name = "PlayStation Token";
    string private constant _symbol = "PlayStation";
    uint256 public _maxTxAmount = 1000000 * 10**_decimals;
    uint256 public _maxWalletSize = 2000000 * 10**_decimals;
    uint256 public tradingCoolDownPeriod;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public tradingOpen = false;
    bool public swapEnabled = false;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    constructor() {
        _marketingWallet = payable(0x738642cabF9365C8343ed2a82AE29F0EC7f04344);
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
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

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            if (from == uniswapV2Pair || to == uniswapV2Pair) {
                require(
                    block.timestamp >= tradingCoolDownPeriod,
                    "Trading is currently off"
                );
            }

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );

                taxAmount = amount.mul(buyTax).div(100);
                _buyCount++;
            } else if (
                to == uniswapV2Pair &&
                from != address(this) &&
                !_isExcludedFromFee[from]
            ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul(sellTax).div(100);
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        if (tokenAmount == 0) {
            return;
        }
        if (!tradingOpen) {
            return;
        }
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

    function setTradingCoolDown(uint256 _time) external onlyOwner {
        tradingCoolDownPeriod = block.timestamp + _time;
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function setMaxTxAmount(uint256 _amount) external onlyOwner {
        _maxTxAmount = _amount;
    }

    function setMaxWalletAmount(uint256 _amount) external onlyOwner {
        _maxWalletSize = _amount;
    }

    function sendETHToFee(uint256 amount) private {
        _marketingWallet.transfer(amount);
    }

    function setBuyTax(uint256 _tax) external onlyOwner {
        buyTax = _tax;
    }

    function setSellTax(uint256 _tax) external onlyOwner {
        sellTax = _tax;
    }

    function isBot(address a) public view returns (bool) {
        return bots[a];
    }

    // Function to add an address as a bot
    function addBot(address botAddress) external onlyOwner {
        bots[botAddress] = true;
    }

    // Function to remove an address from the bot list
    function removeBot(address botAddress) external onlyOwner {
        bots[botAddress] = false;
    }

    function setExcludedFromFee(address account) external onlyOwner {
        require(!_isExcludedFromFee[account], "Account already excluded");
        _isExcludedFromFee[account] = true;
    }

    function removeExcludedFromFee(address account) external onlyOwner {
        require(_isExcludedFromFee[account], "Account is not exlcuded");
        _isExcludedFromFee[account] = false;
    }

    function openTrading(address _lpPair, address _router) external onlyOwner {
        require(!tradingOpen, "trading is already open");
        uniswapV2Pair = _lpPair;
        uniswapV2Router = IUniswapV2Router02(_router);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    function changeMarketingAddress(address _add) external onlyOwner {
        _marketingWallet = payable(_add);
    }

    function withDrawETH() external onlyOwner {
        require(address(this).balance > 0, "Not enough eth");
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawStuckTokens() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        require(balance > 0, "No balance to withdraw");
        _transfer(address(this), owner(), balance);
    }

    function manualSwap() external {
        require(_msgSender() == _marketingWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        } else {
            revert("Not enough value");
        }
    }
}