/*

Telegram - https://t.me/onlysulek 
Twitter  - https://twitter.com/onlysulek
Website  - https://sulek.tech

..............,,,,,,...........,+?S#S%*,..............,,..............
...........,:++++;;;,.........,S@@@@@@@S:...........,:++++;::,........
.........,:+%SS%??*+:.........:@@@#S#@@@@?:,........;+**?%S%?+:.......
......,,:;+?S?;+?%%?,........+S#??%%??%#@##%,.......:%SSS%?%S+;:,.....
....,,:;;+?%;.....,,........;#@*:;+*+;+*#@@S,........,:,,..,**+;:,....
...,:;;;+*?+...............,%@#+*??**++*#@@#*...............:*+;;;:...
.,:;;;;+***,...............:S@@SS###SS%S#@@@#+..............,+;;;;;:,.
.;********+:,,,,,,,,,,,,,..,%@@S%SSSSSS%#@@@@%..............:++;;;;+:.
:*?%?**++;;;;;;:::+;:::::::+@@#%#@@##S%%#@@S?;::::::,,,:::,,:++***?**:
;%%%?*++++*?%%?+++*+::::;?SSSS%SS######S#?;:::::+?+;:;;;;+++;;+**%%%%*
.:*%SS%%????%SSS%?**+;:+S#SSSSS#SSSSSSSS#+::;;++**++*???***+;+*?%%SSS?
...,;*SS#SSSSSSS#SS#%**####SSSS##S%%%SS##?;;+?%SS%SSS%%%%????%%SSS#S?:
......,;*%SSS###%*+?%?S######S###SSS#####S+*%SSS%SS##SSSSSSSS###%?+:..
..........,,::;++;:;*S###########S#######@?*??*;;;+?#######S%?+:......
...............,*+;:*#@##@##############@@S+++;;+++*%+;;;;:,,.........
................+*++#@@#@@###########@@@@@@+;;;+*?%%+.................
................,*+%@@##@####@########@@@@@S+++*?%S*,.................
.................:?#@@#@@####@@#######@@@@@@%??%S%;,..................
..................;#@@@@##@##@@#####@@@@@@@@#SSS?,....................
..................:@@@@@@@@#@@@@@@@@@@@@@@@@@#S+,.....................
.................,S@@@@@@@@@@@@@@@@@@@@@@@@@@#:.......................
.................:@@@#@@@@@#@@@@@@@@@@@@@@@@@#,.......................
.................+@@##@@@@@#@@@@@@@@@@@@@@@@@@,.......................

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract Sulek is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    bool public transferDelayEnabled = true;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 405_000_000 * 10 ** _decimals;
    string private constant _name = "SULEK";
    string private constant _symbol = "SLK";

    uint256 public _maxTxAmount = (_tTotal / 1000) * 15;
    uint256 public _maxWalletSize = (_tTotal / 1000) * 20;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    bool private tradingOpen;
    bool private inSwap = false;

    address public taxWallet;
    uint256 public initialBlock;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    constructor(address _taxWallet) {
        taxWallet = _taxWallet;
        _balances[_msgSender()] = _tTotal;

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

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
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
        require(!bots[from] && !bots[to]);

        uint256 currentTaxFee = calculateTaxFee();

        uint256 taxAmount = 0;
        uint256 amountAfterTax = amount;

        if (from != owner() && to != owner()) {
            if (transferDelayEnabled) {
                if (
                    to != address(uniswapV2Router) &&
                    to != address(uniswapV2Pair)
                ) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "Transfer Delay enabled. Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
            }

            if (currentTaxFee > 0) {
                taxAmount = amount.mul(currentTaxFee).div(100);
                amountAfterTax = amount.sub(taxAmount);
            }
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amountAfterTax);

        if (taxAmount > 0) {
            _balances[taxWallet] = _balances[taxWallet].add(taxAmount);
            emit Transfer(from, taxWallet, taxAmount);
        }

        emit Transfer(from, to, amountAfterTax);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
        for (uint256 i = 0; i < notbot.length; i++) {
            bots[notbot[i]] = false;
        }
    }

    function isBot(address a) public view returns (bool) {
        return bots[a];
    }

    function calculateTaxFee() internal view returns (uint256) {
        uint256 blocksPassed = block.number - initialBlock;
        if (blocksPassed >= 50) {
            return 0;
        }

        uint256 taxDecreaseIntervals = blocksPassed / 5;
        uint256 currentTaxFee = 10 - taxDecreaseIntervals;

        return currentTaxFee;
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        initialBlock = block.number;
        tradingOpen = true;
    }

    receive() external payable {}
}