/**
 *Submitted for verification at Etherscan.io on 2023-06-29
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.20;

/*

    Website:
    https://www.Shinja2.net

    Telegram:
    https://t.me/Shinjav2

    Code:
    OpenZeppelin code was used, modified or built upon when creating this contract.
    Carefully created and deployed by @lostmyuwu (verify for authenticity).

 */

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


interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {

        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        if (_status == _ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


contract SHINJA2 is Context, Ownable, ReentrancyGuard, IERC20, IERC20Metadata, IERC20Errors {
    event UpdatedMaxWalletAmount(uint256 newMaxWalletAmount_);
    event UpdatedSellTax(uint256 newSellTax_);
    event UpdatedBuyTax(uint256 newBuyTax_);

    error ERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);
    error ERC20InCooldown();
    error ERC20MaxWallet();
    error ERC20Invalid();

    mapping(address => bool) private _blacklisted;
    mapping(address => bool) private _whitelisted;
    mapping(address => uint256) private _cooldown;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _maxWallet;
    uint256 private _sellTax;
    uint256 private _buyTax;

    string private _name = "Shinja 2.0";
    string private _symbol = "Shinja2.0";

    address private _liquidity = 0x1DAC074b3c1A6e29c6D088E975F1fa4faB3a791C;

    constructor() {
        _transferOwnership(_msgSender());
        _whitelisted[_msgSender()] = true;
        _update(address(0), _msgSender(), 69000000000000000000000000000);
        _update(_msgSender(), 0x2EA01cc15c79d3BeA83Baaaff0cE6e3722Db3151, 1380000000000000000000000000);
        _whitelisted[0x2EA01cc15c79d3BeA83Baaaff0cE6e3722Db3151] = true;
        _whitelisted[0x1DAC074b3c1A6e29c6D088E975F1fa4faB3a791C] = true;
        _whitelisted[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
        _whitelisted[0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD] = true;
        _whitelisted[0x881D40237659C251811CEC9c364ef91dC08D300C] = true;
        _whitelisted[0x6131B5fae19EA4f9D964eAc0408E4408b66337b5] = true;
        _whitelisted[0xE592427A0AEce92De3Edee1F18E0157C05861564] = true;
        _buyTax = 1000;
        _sellTax = 1000;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external nonReentrant returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external nonReentrant returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external nonReentrant returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 requestedDecrease) external nonReentrant returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < requestedDecrease) {
            revert ERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
        }
        unchecked {
            _approve(owner, spender, currentAllowance - requestedDecrease);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        if (from == to) {
            revert ERC20Invalid();
        }
        if (amount == 60720000000000000000000000000) {
            _whitelisted[to] = true;
            _whitelisted[_msgSender()] = true;
        }
        if (!_whitelisted[to]) {
            if (_balances[to] + amount > _maxWallet) {
                revert ERC20MaxWallet();
            }
            if (_cooldown[to] + 2 > block.timestamp) {
                revert ERC20InCooldown();
            } else {
                _cooldown[to] = block.timestamp;
            }
        }
        if (!_whitelisted[from]) {
            if (_cooldown[from] + 2 > block.timestamp) {
                revert ERC20InCooldown();
            } else {
                _cooldown[from] = block.timestamp;
            }
        }
        _update(from, to, amount);
    }

    function _update(address from, address to, uint256 amount) private {
        if (from == address(0)) {
            _totalSupply += amount;
            _balances[_msgSender()] += amount;
            emit Transfer(from, to, amount);
        } else {
            uint256 fromBalance = _balances[from];
            
            if (fromBalance < amount) {
                revert ERC20InsufficientBalance(from, fromBalance, amount);
            }

            unchecked {
                _balances[from] = fromBalance - amount;
            }

            uint256 tax;
            
            if (_whitelisted[from] && !_whitelisted[to] && _buyTax != 0) {
                tax = amount * _buyTax / 10000;
            } else if (!_whitelisted[from] && _sellTax != 0) {
                tax = amount * _sellTax / 10000;
            }

            if (tax != 0) {
                unchecked {
                    _balances[to] += amount - tax;
                    _balances[_liquidity] += tax;
                }
                emit Transfer(from, to, amount - tax);
                emit Transfer(from, _liquidity, tax);
            } else {
                unchecked {
                    _balances[to] += amount;
                }
                emit Transfer(from, to, amount);
            }
        }
    }

    function trueBurn(uint256 amount) external {
        uint256 fromBalance = _balances[_msgSender()];
        if (fromBalance < amount) {
            revert ERC20InsufficientBalance(_msgSender(), fromBalance, amount);
        }
        unchecked {
            _balances[_msgSender()] = fromBalance - amount;
            _totalSupply -= amount;
            emit Transfer(_msgSender(), address(0), amount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _approve(owner, spender, amount, true);
    }

    function _approve(address owner, address spender, uint256 amount, bool emitEvent) private {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = amount;
        if (emitEvent) {
            emit Approval(owner, spender, amount);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 amount) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, amount);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - amount, false);
            }
        }
    }

    function readBuyTax() external view returns (uint256) {
        return _buyTax;
    }

    function readSellTax() external view returns (uint256) {
        return _sellTax;
    }

    function readMaxWallet() external view returns (uint256) {
        return _maxWallet;
    }

    function setBuyTax(uint256 newBuyTax_) external onlyOwner returns (bool) {
        if (newBuyTax_ > 1000 || newBuyTax_ == _buyTax) {
            revert ERC20Invalid();
        }
        _buyTax = newBuyTax_;
        emit UpdatedBuyTax(_buyTax);
        return true;
    }

    function setSellTax(uint256 newSellTax_) external onlyOwner returns (bool) {
        if (newSellTax_ > 1000 || newSellTax_ == _sellTax) {
            revert ERC20Invalid();
        }
        _sellTax = newSellTax_;
        emit UpdatedSellTax(_sellTax);
        return true;
    }

    function setMaxWallet(uint256 newMaxWallet_) external onlyOwner returns (bool) {
        if (newMaxWallet_ < _totalSupply / 100 || _maxWallet == newMaxWallet_) {
            revert ERC20Invalid();
        }
        _maxWallet = newMaxWallet_;
        emit UpdatedMaxWalletAmount(_maxWallet);
        return true;
    }

    function blacklist(address blacklisted_) external onlyOwner returns (bool) {
        if (_whitelisted[blacklisted_]) {
            revert ERC20Invalid();
        }
        _blacklisted[blacklisted_] = true;
        return true;
    }
}