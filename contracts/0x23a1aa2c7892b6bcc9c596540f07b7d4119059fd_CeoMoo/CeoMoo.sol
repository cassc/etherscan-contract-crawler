/**
 *Submitted for verification at Etherscan.io on 2023-05-20
*/

// SPDX-License-Identifier: MIT

/* A Deflationary MEME token. target supply is 100,000,000 (100 Million) */

pragma solidity 0.8.16;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract CeoMoo is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    bool public antiSnipeDisabled = false;
    //Used only on launch day
    uint256 maxBuyOrSell = 1_000_000_000_000 * (10 ** 18);

    uint256 private _totalSupply;
    string private _name;
    uint8 private _decimals;
    string private _symbol;
    uint256 private _TARGET_TOTAL_SUPPLY;

    uint256 private _totalFeesOnBuy = 1;
    uint256 private _totalFeesOnSell = 6;

    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) public taxedPairs;

    mapping(address => bool) private _isExcludedFromFees;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor() {
        _name = "CeoMoo";
        _symbol = "CEOMOO";
        _decimals = 18;
        _totalSupply = 100_000_000_000_000 * (10 ** 18);
        _TARGET_TOTAL_SUPPLY = 100_000_000 * (10 ** 18);
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

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {

        _processTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
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
                "BEP20: transfer amount exceeds allowance"
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
                "BEP20: decreased allowance below zero"
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

        if (!antiSnipeDisabled) {
            if (taxedPairs[sender] || taxedPairs[recipient]) {
                require(amount <= maxBuyOrSell, "CEOMOO: transaction amount not allowed");
            }
        }

        bool takeFee = true;
        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if (!taxedPairs[sender] && !taxedPairs[recipient]) {
            takeFee = false;
        }

        if (_totalSupply <= _TARGET_TOTAL_SUPPLY) {
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

                if (_totalSupply.sub(fees) < _TARGET_TOTAL_SUPPLY) {
                    fees = _totalSupply.sub(_TARGET_TOTAL_SUPPLY);
                }

                amount = amount - fees;

                _totalSupply = _totalSupply.sub(fees);
                _transfer(sender, address(0), fees);
            }
        }
        
        _transfer(sender, recipient, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //=======FeeManagement=======//
    function excludeFromFees(address account) external onlyOwner {
        require(!_isExcludedFromFees[account], "Account is already excluded");
        _isExcludedFromFees[account] = true;

        emit ExcludeFromFees(account, true);
    }

    function includeInFees(address account) external onlyOwner {
        require(_isExcludedFromFees[account], "Account is already included");
        _isExcludedFromFees[account] = false;

        emit ExcludeFromFees(account, false);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function excludeFromTaxedPairs(address pair)
        external
        onlyOwner
    {
        require(taxedPairs[pair], "Pair is already the value of excluded");
        taxedPairs[pair] = false;
    }

    function includeInTaxedPairs(address pair)
        external
        onlyOwner
    {
        require(!taxedPairs[pair], "Pair is already the value of included");
        taxedPairs[pair] = true;
    }

    function isIncludedInTaxedPairs(address pair) public view returns (bool) {
        return taxedPairs[pair];
    }

    function getFeesOnBuy() external view returns (uint256) {
        return _totalFeesOnBuy;
    }

    function getFeesOnSell() external view returns (uint256) {
        return _totalFeesOnSell;
    }

    function setAntisnipeDisable() external onlyOwner {
        require(!antiSnipeDisabled, "Antisnipe already disabled");
        antiSnipeDisabled = true;
    }

    function setMaxBuyOrSell(uint256 maxBuyOrSellVal) external onlyOwner {
        require(!antiSnipeDisabled, "Not used when antisnipe is disabled");
        maxBuyOrSell = maxBuyOrSellVal;
    }

    function getMaxBuyOrSell() external view returns (uint256) {
        return maxBuyOrSell;
    }
}