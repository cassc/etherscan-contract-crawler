/**
 *Submitted for verification at BscScan.com on 2023-05-04
*/

/**
 *telergam: t.me/OggyInuCoin        safe100%   web : oggyinu.com
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable is Context {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external;
}

contract oggyinucoin is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    uint256 private _totalFeesOnBuy = 0;
    uint256 private _totalFeesOnSell = 8;

    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) public taxedPairs;

    mapping(address => bool) private _isBlacklisted;
    bool private blacklistDisable = false;

    bool public taxDisable = false;

    mapping(address => bool) private _isExcludedFromFees;

    IAntisnipe public antisnipe;
    bool public antisnipeDisable;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event BuyFeesUpdate(uint256 totalFeesOnBuy);
    event SellFeesUpdate(uint256 totalFeesOnSell);

    constructor() {
        _name = 'oggyinucoin';
        _symbol = 'oggyinucoin';
        _decimals = 18;
        _totalSupply = 420_000_000 * (10 ** 18);
        _balances[msg.sender] = _totalSupply;

        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[address(this)] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _processTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _processTransfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                'BEP20: transfer amount exceeds allowance'
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                'BEP20: decreased allowance below zero'
            )
        );
        return true;
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function _processTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (
            sender != address(0) &&
            recipient != address(0) &&
            !antisnipeDisable &&
            address(antisnipe) != address(0)
        ) antisnipe.assureCanTransfer(msg.sender, sender, recipient, amount);

        if (!blacklistDisable) {
            if (recipient != owner()) {
                require(!_isBlacklisted[sender], 'ERC20: sender address blacklisted');
                require(
                    !_isBlacklisted[recipient],
                    'ERC20: transfer to blacklisted address'
                );
            }
        }

        bool takeFee = true;
        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if (!taxedPairs[sender] && !taxedPairs[recipient]) {
            takeFee = false;
        }

        if (taxDisable) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 _totalFees;
            if (taxedPairs[sender]) {
                _totalFees = _totalFeesOnBuy;
            } else {
                _totalFees = _totalFeesOnSell;
            }
            if (_totalFees > 0) {
                uint256 fees = (amount * _totalFees) / 100;

                amount = amount - fees;

                _transfer(sender, address(this), fees);
            }
        }

        _transfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');
        require(sender != DEAD, 'BEP20: transfer from the Dead address');
        require(recipient != DEAD, 'BEP20: transfer to the Dead address');

        _balances[sender] = _balances[sender].sub(
            amount,
            'BEP20: transfer amount exceeds balance'
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(
            amount,
            'BEP20: burn amount exceeds balance'
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function claimTokens(address token) external onlyOwner {
        if (token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IBEP20 BEP20token = IBEP20(token);
        uint256 balance = BEP20token.balanceOf(address(this));
        BEP20token.transfer(owner(), balance);
    }

    function claimStuckBNB(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = payable(owner()).call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    function blacklistAccount(address[] memory blacklist) external onlyOwner {
        for (uint256 i = 0; i < blacklist.length; i++) {
            if (!_isBlacklisted[blacklist[i]]) {
                _isBlacklisted[blacklist[i]] = true;
            } else {
                continue;
            }
        }
    }

    function removeBlacklist(address[] memory blacklist) external onlyOwner {
        for (uint256 i = 0; i < blacklist.length; i++) {
            if (_isBlacklisted[blacklist[i]]) {
                _isBlacklisted[blacklist[i]] = false;
            } else {
                continue;
            }
        }
    }

    function isBlacklisted(address account) external view returns (bool) {
        return _isBlacklisted[account];
    }

    function setBlacklistDisable() external onlyOwner {
        require(!blacklistDisable, 'Blacklist fuction already disabled');
        blacklistDisable = true;
    }

    //=======FeeManagement=======//
    function excludeFromFees(address account) external onlyOwner {
        require(!_isExcludedFromFees[account], 'Account is already excluded');
        _isExcludedFromFees[account] = true;

        emit ExcludeFromFees(account, true);
    }

    function includeInFees(address account) external onlyOwner {
        require(_isExcludedFromFees[account], 'Account is already included');
        _isExcludedFromFees[account] = false;

        emit ExcludeFromFees(account, false);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function updateBuyFees(uint256 totalFeesOnBuy) external onlyOwner {
        require(totalFeesOnBuy <= 25, 'Fees must be less than 25%');

        _totalFeesOnBuy = totalFeesOnBuy;
        emit BuyFeesUpdate(totalFeesOnBuy);
    }

    function updateSellFees(uint256 totalFeesOnSell) external onlyOwner {
        require(totalFeesOnSell <= 25, 'Fees must be less than 25%');

        _totalFeesOnSell = totalFeesOnSell;
        emit SellFeesUpdate(totalFeesOnSell);
    }

    function excludeFromTaxedPairs(address pair) external onlyOwner {
        require(taxedPairs[pair], 'Pair is already the value of excluded');
        taxedPairs[pair] = false;
    }

    function includeInTaxedPairs(address pair) external onlyOwner {
        require(!taxedPairs[pair], 'Pair is already the value of included');
        taxedPairs[pair] = true;
    }

    function isIncludedInTaxedPairs(address pair) public view returns (bool) {
        return taxedPairs[pair];
    }

    function setTaxDisable(bool taxDisableval) external onlyOwner {
        taxDisable = taxDisableval;
    }

    function getTaxDisable() external view returns (bool) {
        return taxDisable;
    }

    function getFeesOnBuy() external view returns (uint256) {
        return _totalFeesOnBuy;
    }

    function getFeesOnSell() external view returns (uint256) {
        return _totalFeesOnSell;
    }

    function setAntisnipeDisable() external onlyOwner {
        require(!antisnipeDisable);
        antisnipeDisable = true;
    }

    function setAntisnipeAddress(address addr) external onlyOwner {
        antisnipe = IAntisnipe(addr);
    }
}