pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IMasterChef2.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./SafeUniswapV2Router.sol";
import "../../RDN/RDNOwnable.sol";

contract SpotV0 is RDNOwnable, IERC20 {
    using SafeERC20 for IERC20;
    using SafeUniswapV2Router for IUniswapV2Router;

    // todo
    // RDN user as owner
    // any lowlevel call by admin
    // is ERC20, only for RDN owner. Deposit / withdraw based on strategy tokens (minting/burning)
    // return remained
    // swap token0 to token0
    // swap fees support
    // safeERC20
    // BNB support
    // withdraw any
    // call any
    // restake rules
    // transfers logs to userId
    // informative name and symbol
    // owner should be active
    // deposit / withdraw without restake ??
    // APR / APY
    // StableSwap support
    // separated ERC20 implementation
    // What if NOT initRDNOwnable / basic init for implementation

    // ERC20 implementation
    mapping(uint => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _totalSupply;
    string private _name;
    string private _symbol;

    struct Swap {
        address[] path;
        uint outMin;
    }

    address public pool;
    address public router;
    address public stakingToken;
    address public rewardToken;
    uint public poolIndex;

    address public factory;

    constructor() {

    }

    function init(
        address _pool,
        address _router,
        address _stakingToken,
        address _rewardToken,
        uint _poolIndex,
        uint _ownerId,
        address _registry,
        address _factory
    ) external {
        pool = _pool;
        router = _router;
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        poolIndex = _poolIndex;

        initRDNOwnable(_registry, _ownerId);
        factory = _factory;

        _symbol = 'SPOT0';
        _name = "SPOTv0 Share Token";
    }

    function deposit(
        uint amount,
        Swap memory swap0,
        Swap memory swap1,
        Swap memory swapReward0,
        Swap memory swapReward1,
        uint deadline
    ) public {
        address _stakingToken = stakingToken; // gas savings
        address _pool = pool; // gas savings
        uint _poolIndex = poolIndex; //gas savings

        if (IMasterChef2(pool).pendingCake(poolIndex, address(this)) > 0) {
            _restake(deadline, swapReward0, swapReward1);
        }

        // prepare to mint
        uint beforeDepositSupply = _totalSupply;
        IMasterChef2.UserInfo memory userInfo = IMasterChef2(_pool).userInfo(_poolIndex, address(this));
        uint beforeDepositBalance = userInfo.amount;

        // buy liquidity and stake
        IERC20(swap0.path[0]).safeTransferFrom(msg.sender, address(this), amount);
        _buyLiquidity(amount, swap0, swap1, deadline);
        _stake(IERC20(_stakingToken).balanceOf(address(this)));

        // mint
        userInfo = IMasterChef2(_pool).userInfo(_poolIndex, address(this));
        uint afterDepositBalance = userInfo.amount;
        uint amountToMint;
        if (beforeDepositBalance == 0) {
            amountToMint = afterDepositBalance;
        } else {
            amountToMint = ((afterDepositBalance - beforeDepositBalance) * beforeDepositSupply) / beforeDepositBalance;
        }

        _mint(ownerId, amountToMint);
    }

    function withdraw(
        uint amountToBurn,
        Swap memory swap0,
        Swap memory swap1,
        Swap memory swapReward0,
        Swap memory swapReward1,
        uint deadline
    ) public onlyRDNOwner(msg.sender) {
        address _pool = pool; // gas savings
        uint _poolIndex = poolIndex; //gas savings
        address tokenToWithdraw = swap0.path[swap0.path.length - 1];

        if (IMasterChef2(pool).pendingCake(poolIndex, address(this)) > 0) {
            _restake(deadline, swapReward0, swapReward1);
        }

        // prepare to burn
        uint beforeWithdrawSupply = _totalSupply;
        IMasterChef2.UserInfo memory userInfo = IMasterChef2(_pool).userInfo(_poolIndex, address(this));
        uint beforeWithdrawBalance = userInfo.amount;

        // sell liquidity
        // refactor to strategy tokens base calculation
        uint amountToWithdraw = ((amountToBurn * beforeWithdrawBalance)) / beforeWithdrawSupply;
        _unStake(amountToWithdraw);

        _sellLiquidity(amountToWithdraw, swap0, swap1, deadline);

        // withdraw tokens swap[0].path[swap.path.length - 1]
        IERC20(tokenToWithdraw).transfer(msg.sender, IERC20(tokenToWithdraw).balanceOf(address(this)));

        //burn
        _burn(ownerId, amountToBurn);
    }

    function callAny(address payable _addr, bytes memory _data) public payable onlyRDNOwner(msg.sender) returns(bool success, bytes memory data){
        (success, data) = _addr.call{value: msg.value}(_data);
    }
    
    function restake(
        Swap memory swapReward0,
        Swap memory swapReward1,
        uint deadline
    ) public {
        _restake(deadline, swapReward0, swapReward1);
    }

    function info() public view returns (uint, address, uint, uint) {
        address _pool = pool; // gas savings
        uint _poolIndex = poolIndex; //gas savings

        uint reward = IMasterChef2(_pool).pendingCake(_poolIndex, address(this));
        IMasterChef2.UserInfo memory userInfo = IMasterChef2(_pool).userInfo(_poolIndex, address(this));
        uint staking = userInfo.amount;

        return (poolIndex, stakingToken, reward, staking);
    }

    function _restake(
        uint deadline,
        Swap memory swap0,
        Swap memory swap1
    ) internal {
        IMasterChef2 _pool = IMasterChef2(pool); // gas savings
        IERC20 _rewardToken = IERC20(rewardToken); // gas savings

        require(_pool.pendingCake(poolIndex, address(this)) > 0, "nothing to claim");

        _pool.deposit(poolIndex, 0); // get all reward
        uint amount = _rewardToken.balanceOf(address(this));
        _buyLiquidity(amount, swap0, swap1, deadline);
        _stake(IERC20(stakingToken).balanceOf(address(this)));
    }

    function _buyLiquidity(
        uint amount,
        Swap memory swap0,
        Swap memory swap1,
        uint deadline
    ) internal returns(address token0, address token1) {
        require(swap0.path[0] == swap1.path[0], "start tokens should be equal");
        
        IUniswapV2Pair to = IUniswapV2Pair(stakingToken);

        // prepare tokens
        token0 = to.token0();
        token1 = to.token1();
        require(swap0.path[swap0.path.length - 1] == token0, "token0 is invalid");
        require(swap1.path[swap1.path.length - 1] == token1, "token1 is invalid");

        // swap input tokens
        _approve(IERC20(swap0.path[0]), address(router), amount);
        uint amount0In = amount / 2;
        _swap(amount0In, swap0.outMin, swap0.path, deadline);
        uint amount1In = amount - amount0In;
        _swap(amount1In, swap1.outMin, swap1.path, deadline);

        _addLiquidity(token0, token1, deadline);

        // todo: return remained

    }

    function _sellLiquidity(
        uint amount,
        Swap memory swap0,
        Swap memory swap1,
        uint deadline
    ) internal returns(address token0, address token1) {
        require(swap0.path[swap0.path.length-1] == swap1.path[swap1.path.length-1], "end tokens should be equal");
        
        IUniswapV2Pair from = IUniswapV2Pair(stakingToken);

        // prepare tokens / remove liquidity
        token0 = from.token0();
        token1 = from.token1();
        _removeLiquidity(amount, token0, token1, deadline);
        require(swap0.path[0] == token0, "token0 is invalid");
        require(swap1.path[0] == token1, "token1 is invalid");
        uint amount0 = IERC20(token0).balanceOf(address(this));
        uint amount1 = IERC20(token1).balanceOf(address(this));

        // swap from tokens
        _approve(IERC20(token0), address(router), amount0);
        _approve(IERC20(token1), address(router), amount1);
        _swap(amount0, swap0.outMin, swap0.path, deadline);
        _swap(amount1, swap1.outMin, swap1.path, deadline);

        // todo: return remained

    }

    function _addLiquidity(
        address token0,
        address token1,
        uint deadline
    ) internal {
        address _router = router; // gas savings
        uint amountIn0 = IERC20(token0).balanceOf(address(this));
        uint amountIn1 = IERC20(token1).balanceOf(address(this));
        _approve(IERC20(token0), _router, amountIn0);
        _approve(IERC20(token1), _router, amountIn1);
        IUniswapV2Router(_router).addLiquidity(
            token0,
            token1,
            amountIn0,
            amountIn1,
            0,
            0,
            address(this),
            deadline
        );
    }

    function _removeLiquidity(
        uint amount,
        address token0,
        address token1,
        uint deadline
    ) internal {
        address _router = router; // gas savings
        address _stakingToken = stakingToken; // gas savings

        require(amount <= IERC20(_stakingToken).balanceOf(address(this)), "not enough liquidity to remove");

        _approve(IERC20(_stakingToken), _router, amount);
        IUniswapV2Router(_router).removeLiquidity(
            token0,
            token1,
            amount,
            0,
            0,
            address(this),
            deadline
        );
    }

    function _approve(
        IERC20 token,
        address spender,
        uint amount
    ) internal {
        if (token.allowance(address(this), spender) != 0) {
            token.safeApprove(spender, 0);
        }
        token.safeApprove(spender, amount);
    }

    function _swap(
        uint amount,
        uint outMin,
        address[] memory path,
        uint deadline
    ) internal {
        if (path[0] == path[path.length - 1]) return;

        // IUniswapV2Router(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
        IUniswapV2Router(router).swapExactTokensForTokens(
            amount,
            outMin,
            path,
            address(this),
            deadline
        );
    }

    function _stake(uint amount) internal {
        _approve(IERC20(stakingToken), pool, amount);
        IMasterChef2(pool).deposit(poolIndex, amount);
    }

    function _unStake(uint amount) internal {
        IMasterChef2(pool).withdraw(poolIndex, amount);
    }


    // ERC20 implementation

    function balanceOf(address _account) public view returns (uint) {
        uint userId = IRDNRegistry(registry).getUserIdByAddress(_account);
        return _balances[userId];
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function transfer(address to, uint amount) external returns (bool) {
        return false;
    }

    function approve(address spender, uint amount) external returns (bool) {
        return false;
    }

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool) {
        return false;
    }

    function _mint(uint userId, uint amount) internal {
        address account = IRDNRegistry(registry).getUserAddress(userId);
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[userId] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(uint userId, uint amount) internal {
        address account = IRDNRegistry(registry).getUserAddress(userId);
        require(account != address(0), "ERC20: burn from zero address");

        uint accountBalance = _balances[userId];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[userId] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }


}