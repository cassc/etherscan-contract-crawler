/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

/**
* SPDX-License-Identifier: Unlicensed
*
* ██████╗░░█████╗░███████╗██╗░░░░░███████╗██╗███╗░░██╗██╗  ░█████╗░░█████╗░██╗███╗░░██╗
* ██╔══██╗██╔══██╗██╔════╝██║░░░░░██╔════╝██║████╗░██║██║  ██╔══██╗██╔══██╗██║████╗░██║
* ██║░░██║██║░░██║█████╗░░██║░░░░░█████╗░░██║██╔██╗██║██║  ██║░░╚═╝██║░░██║██║██╔██╗██║
* ██║░░██║██║░░██║██╔══╝░░██║░░░░░██╔══╝░░██║██║╚████║██║  ██║░░██╗██║░░██║██║██║╚████║
* ██████╔╝╚█████╔╝██║░░░░░███████╗███████╗██║██║░╚███║██║  ╚█████╔╝╚█████╔╝██║██║░╚███║
* ╚═════╝░░╚════╝░╚═╝░░░░░╚══════╝╚══════╝╚═╝╚═╝░░╚══╝╚═╝  ░╚════╝░░╚════╝░╚═╝╚═╝░░╚══╝
*
* Dofleini is a groundbreaking new digital currency with unique features that set it apart from the rest. Join us as we change the game.
*
* Website: https://DofleiniCoin.com
* Twitter: https://twitter.com/DofleiniCoin
* Telegram: https://t.me/DofleiniSafeguardBot
*
* COPYRIGHT © 2023 Dofleini Coin, All Rights Reserved.
**/

pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Dofleini is Context, IERC20, IERC20Metadata {

    using SafeMath for uint256;

    struct Holder {
        address holderAddress;
        uint256 balance;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromRewards;
    mapping(uint256 => Holder) private _holders;

    uint8 private _decimals;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address private _owner;
    uint256 private _fee;
    address private _feeProcessor;
    uint256 private _numHolders;

    constructor(uint8 decimals_, uint256 totalSupply_, string memory name_, string memory symbol_, address owner_, uint256 fee_, address feeProcessor_) {
        _decimals = decimals_;
        _totalSupply = totalSupply_.mul(10**uint256(decimals()));
        _name = name_;
        _symbol = symbol_;
        _owner = owner_;
        _fee = fee_;
        _feeProcessor = feeProcessor_;
        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner, "Only owner can call this function.");
        _;
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

    function getFee() public view virtual returns (uint256) {
        return _fee;
    }

    function getFeeProcessor() public view virtual returns (address) {
        return _feeProcessor;
    }

    function getOwner() public view virtual returns (address) {
        return _owner;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromRewards(address account) public view returns (bool) {
        return _isExcludedFromRewards[account];
    }

    function excludeFromFees(address account) external onlyOwner {
        _isExcludedFromFees[account] = true;
    }

    function excludeFromRewards(address account) external onlyOwner {
        _isExcludedFromRewards[account] = true;
    }

    function includeInFees(address account) external onlyOwner {
        _isExcludedFromFees[account] = false;
    }

    function includeInRewards(address account) external onlyOwner {
        _isExcludedFromRewards[account] = false;
    }

    function setFeeProcessor(address newFeeProcessor) external onlyOwner {
        _feeProcessor = newFeeProcessor;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();

        if (_isExcludedFromFees[owner] || _isExcludedFromFees[to]) {
            _excludedTransfer(owner, to, amount);
        } else {
            _standardTransfer(owner, to, amount);
        }

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

        if (_isExcludedFromFees[from]) {
            _excludedTransfer(from, to, amount);
        } else {
            _standardTransfer(from, to, amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender).add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "Dofleini: decreased allowance below zero");
        _approve(owner, spender, currentAllowance.sub(subtractedValue));
        return true;
    }

    function _excludedTransfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "Dofleini: transfer from the zero address");
        require(to != address(0), "Dofleini: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Dofleini: transfer amount exceeds balance");

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);

        _updateHolder(from);
        _updateHolder(to);
    }

    function _standardTransfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "Dofleini: transfer from the zero address");
        require(to != address(0), "Dofleini: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Dofleini: transfer amount exceeds balance");

        uint256 fee = amount.mul(_fee).div(10000);
        uint256 transferAmount = amount.sub(fee);

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(transferAmount);
        _balances[_feeProcessor] = _balances[_feeProcessor].add(fee);

        emit Transfer(from, to, transferAmount);
        emit Transfer(from, _feeProcessor, fee);

        _updateHolder(from);
        _updateHolder(to);
    }

    function getTopHolders(uint256 numHolders) external view returns (address[] memory) {
        Holder[] memory holdersArray = new Holder[](_numHolders);
        uint256 count = 0;

        for (uint256 i = 0; i < _numHolders; i++) {
            address holderAddress = _holders[i].holderAddress;
            if (_isExcludedFromRewards[holderAddress] || holderAddress == address(0)) {
                continue;
            }
            uint256 balance = _holders[i].balance;
            holdersArray[count] = Holder(holderAddress, balance);
            count++;
        }

        for (uint256 i = 0; i < count - 1; i++) {
            for (uint256 j = i + 1; j < count; j++) {
                if (holdersArray[j].balance > holdersArray[i].balance) {
                    Holder memory tmp = holdersArray[j];
                    holdersArray[j] = holdersArray[i];
                    holdersArray[i] = tmp;
                }
            }
        }

        uint256 numTopHolders = numHolders < count ? numHolders : count;
        address[] memory topHolders = new address[](numTopHolders);
        for (uint256 i = 0; i < numTopHolders; i++) {
            topHolders[i] = holdersArray[i].holderAddress;
        }
        return topHolders;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Dofleini: approve from the zero address");
        require(spender != address(0), "Dofleini: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Dofleini: insufficient allowance");
                _approve(owner, spender, currentAllowance.sub(amount));
        }
    }

    function _updateHolder(address holderAddress) internal {
        if (_balances[holderAddress] == 0) {
            _removeHolder(holderAddress);
        } else if (_isHolder(holderAddress)) {
            _updateBalance(holderAddress, _balances[holderAddress]);
        } else if (!_isHolder(holderAddress)) {
            _addHolder(holderAddress);
        }
    }

    function _addHolder(address holderAddress) internal {
        Holder storage newHolder = _holders[_numHolders];
        newHolder.holderAddress = holderAddress;
        newHolder.balance = _balances[holderAddress];
        _numHolders++;
    }

    function _removeHolder(address holderAddress) internal {
        uint256 indexToRemove = _findHolderIndex(holderAddress);
        _holders[indexToRemove] = _holders[_numHolders - 1];
        _numHolders--;
    }

    function _updateBalance(address holderAddress, uint256 newBalance) internal {

        uint256 indexToUpdate = _findHolderIndex(holderAddress);
        _holders[indexToUpdate].balance = newBalance;
    }

    function _findHolderIndex(address holderAddress) internal view returns (uint256) {
        for (uint256 i = 0; i < _numHolders; i++) {
            if (_holders[i].holderAddress == holderAddress) {
                return i;
            }
        }
        revert("Holder not found");
    }

    function _isHolder(address holderAddress) internal view returns (bool) {
        for (uint256 i = 0; i < _numHolders; i++) {
            if (_holders[i].holderAddress == holderAddress) {
                return true;
            }
        }
        return false;
    }
}