pragma solidity ^0.8.6;

import "./utils/Governance.sol";
import "./utils/Context.sol";
import "./utils/SafeMath.sol";
import "./utils/IERC20.sol";
import "./utils/ERC20.sol";
import "./utils/SafeERC20.sol";
import "./utils/IPancakePair.sol";
import "./utils/IPancakeRouter01.sol";
import "./DAPP.sol";
import "./Pool.sol";

contract NewPool is Governance, Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => bool) public effects;
    mapping(address => bool) public nodes;
    mapping(address => bool) public isRenew;

    address public usdt;
    address public router;
    address public snto;
    address payable public dapp;
    address public pool;


    uint256 public nodeNumber;
    uint256 public effectAmount;

    struct UserInfo {
        uint256 amount;
        uint256 amountTotal;
        uint256 rewardDebt;
        uint256 rewardTotal;
    }

    struct PoolInfo {
        string name;
        bool isLp;
        IERC20 rewardToken;
        IERC20 lpToken;

        uint256 accRewardPerShare;
        uint256 lpSupply;
        uint256 reward;
        uint256 lastReward;
    }

    address private rootAddress;
    PoolInfo[] public pools;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(address _snto, address payable _dapp, address _pair, address _usdt, address _router, address _pool) {
        nodeNumber = 5;
        effectAmount = 100 * 10 ** 18;

        snto = _snto;
        usdt = _usdt;
        router = _router;
        dapp = _dapp;
        pool = _pool;

        for (uint i = 0; i < 3; i++) {
            (string memory name,
            bool isLp,
            IERC20 rewardToken,
            IERC20 lpToken,

            uint256 accRewardPerShare,
            uint256 lpSupply,
            uint256 reward,
            uint256 lastReward) = Pool(pool).pools(i);
            pools.push(PoolInfo(name, isLp, rewardToken, lpToken, accRewardPerShare, lpSupply, reward, lastReward));
        }
        setGovernance(dapp);
    }

    function renew(address _address) public {
        require(!isRenew[_address], "renew: already");
        isRenew[_address] = true;
        for (uint i = 0; i < 3; i++) {
            (
            uint256 amount,
            uint256 amountTotal,
            uint256 rewardDebt,
            uint256 rewardTotal
            ) = Pool(pool).userInfo(i, _address);
            UserInfo memory user = UserInfo(amount, amountTotal, rewardDebt, rewardTotal);
            userInfo[i][_address] = user;
        }
        effects[_address] = Pool(pool).effects(_address);
        nodes[_address] = Pool(pool).nodes(_address);
    }

    function getUserInfo(uint256 _pid, address _user) public view returns (UserInfo memory) {
        if (!isRenew[_user]) {
            (
            uint256 amount,
            uint256 amountTotal,
            uint256 rewardDebt,
            uint256 rewardTotal
            ) = Pool(pool).userInfo(_pid, _user);
            UserInfo memory user = UserInfo(amount, amountTotal, rewardDebt, rewardTotal);
            return user;
        }
        return userInfo[_pid][_user];
    }

    function setEffectAmount(uint256 _amount) public onlyGovernance {
        effectAmount = _amount;
    }

    function setNodeNumber(uint256 _number) public onlyGovernance {
        nodeNumber = _number;
    }

    function setAddresses(address payable _dapp) public onlyGovernance {
        dapp = _dapp;
    }

    function poolAddReward(uint256 _pid, uint256 _amount) external onlyGovernance {
        updatePool(_pid);
        PoolInfo storage pool = pools[_pid];
        pool.reward = pool.reward.add(_amount);
    }

    function InviteAddAmount(address _user, uint256 _amount) external onlyGovernance {
        if (!isRenew[_user]) {
            renew(_user);
        }
        UserInfo storage user = userInfo[2][_user];
        user.amount = user.amount.add(_amount);
        user.amountTotal = user.amountTotal.add(_amount);
    }

    function inviteWithdraw(uint256 _amount) public {
        if (!isRenew[_msgSender()]) {
            renew(_msgSender());
        }
        uint _pid = 2;
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        user.amount = user.amount.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }


    function getPool(uint256 _pid) public view returns (PoolInfo memory) {
        return pools[_pid];
    }

    function addPoolReward(uint256 _amount) external onlyGovernance {
        updatePool(0);
        PoolInfo storage pool = pools[0];
        pool.reward = pool.reward.add(_amount);
    }

    function addNodeReward(uint256 _amount) external onlyGovernance {
        updatePool(1);
        PoolInfo storage pool = pools[1];
        pool.reward = pool.reward.add(_amount);
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = pools[_pid];
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply == 0) {
            return;
        }
        if (pool.reward <= pool.lastReward) {
            return;
        }

        uint256 reward = pool.reward - pool.lastReward;
        pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(lpSupply));
        pool.lastReward = pool.reward;
    }


    function pendingReward(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo memory pool = pools[_pid];
        UserInfo memory user = getUserInfo(_pid, _user);
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (pool.reward > pool.lastReward && lpSupply != 0) {
            uint256 reward = pool.reward - pool.lastReward;
            accRewardPerShare = accRewardPerShare.add(
                reward.mul(1e12).div(lpSupply)
            );
        }
        return
        user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }


    function massUpdatePools() public {
        uint256 length = pools.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function withdraw(uint256 _amount) public {
        if (!isRenew[_msgSender()]) {
            renew(_msgSender());
        }
        uint _pid = 0;
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(pool.isLp, "not lp");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
            user.rewardDebt
        );
        user.rewardTotal = user.rewardTotal.add(pending);
        pool.rewardToken.safeTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        pool.lpSupply = pool.lpSupply.sub(_amount);
        emit Withdraw(msg.sender, _pid, _amount);
        checkEffect(msg.sender);
    }


    function claim(uint256 _pid, address _parent) public {
        if (!isRenew[_msgSender()]) {
            renew(_msgSender());
        }

        if (DAPP(dapp).parents(_msgSender()) == address(0) && _parent != address(0)) {
            DAPP(dapp).setParentByGovernance(_msgSender(), _parent);
        }

        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
            user.rewardDebt
        );
        user.rewardTotal = user.rewardTotal.add(pending);
        pool.rewardToken.safeTransfer(msg.sender, pending);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Claim(msg.sender, _pid, pending);
    }

    function nodeChangeEffect(address _user, uint256 _count) private {
        if (!isRenew[_user]) {
            renew(_user);
        }
        uint _pid = 1;
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
            .amount
            .mul(pool.accRewardPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
            user.rewardTotal = user.rewardTotal.add(pending);
            pool.rewardToken.safeTransfer(_user, pending);
        }
        if (user.amount > _count) {
            uint256 change = user.amount.sub(_count);
            user.amount = user.amount.sub(change);
            pool.lpSupply = pool.lpSupply.sub(change);
        } else {
            uint256 change = _count.sub(user.amount);
            user.amount = user.amount.add(change);
            pool.lpSupply = pool.lpSupply.add(change);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
    }

    function deposit(uint256 _amount, address _parent) public {
        if (!isRenew[_msgSender()]) {
            renew(_msgSender());
        }

        if (DAPP(dapp).parents(_msgSender()) == address(0) && _parent != address(0)) {
            DAPP(dapp).setParentByGovernance(_msgSender(), _parent);
        }

        uint _pid = 0;
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(pool.isLp, "not lp");
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
            .amount
            .mul(pool.accRewardPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
            user.rewardTotal = user.rewardTotal.add(pending);
            pool.rewardToken.safeTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        pool.lpSupply = pool.lpSupply.add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
        checkEffect(msg.sender);
    }

    function getLpUSDTPrice(address _lpToken) public view returns (uint256) {
        address token0 = IPancakePair(_lpToken).token0();
        address token1 = IPancakePair(_lpToken).token1();
        uint256 totalSupply = IPancakePair(_lpToken).totalSupply();
        uint256 reserve0 = IERC20(token0).balanceOf(_lpToken);
        uint256 reserve1 = IERC20(token1).balanceOf(_lpToken);
        uint256 price0;
        uint256 price1;
        if (token0 == address(usdt)) {
            price0 = 1e18;
        } else {
            price0 = getUSDTPrice(token0);
        }
        if (token1 == address(usdt)) {
            price1 = 1e18;
        } else {
            price1 = getUSDTPrice(token1);
        }
        uint256 lpPrice = price0.mul(reserve0).add(price1.mul(reserve1)).div(totalSupply);
        return lpPrice;
    }

    function getUSDTPrice(address _token) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = address(usdt);
        uint256[] memory amounts = IPancakeRouter01(router).getAmountsOut(1e18, path);
        return amounts[1];
    }

    function isNode(address _user) external view returns (bool) {
        return nodes[_user];
    }

    function isEffect(address _user) external view returns (bool) {
        return effects[_user];
    }

    function getEffectCount(address parent) public view returns (uint256) {
        address[] memory children = DAPP(payable(dapp)).getChildren(parent);
        uint count = 0;
        for (uint256 i = 0; i < children.length; i++) {
            if (effects[children[i]]) {
                count++;
            }
        }
        return count;
    }

    function checkNode(address parent) public {
        if (!isRenew[parent]) {
            renew(parent);
        }
        (uint256 amount, uint count) = getChildrenAmountAndEffectCount(parent);
        if (count >= nodeNumber) {
            nodes[parent] = true;
            nodeChangeEffect(parent, amount);
        } else {
            nodes[parent] = false;
            nodeChangeEffect(parent, 0);
        }
    }

    function getChildrenAmountAndEffectCount(address parent) public view returns (uint256, uint){
        uint256 _pid = 0;
        address[] memory children = DAPP(payable(dapp)).getChildren(parent);
        uint count = 0;
        uint256 amount;
        for (uint256 i = 0; i < children.length; i++) {
            UserInfo memory child = getUserInfo(_pid, children[i]);
            amount = amount.add(child.amount);
            if (effects[children[i]]) {
                count++;
            }
        }
        return (amount, count);
    }

    function checkEffect(address _user) public {
        if (!isRenew[_msgSender()]) {
            renew(_msgSender());
        }
        uint256 _pid = 0;
        PoolInfo storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 price = getLpUSDTPrice(address(pool.lpToken));
        if (price.mul(user.amount).div(1e18) >= effectAmount) {
            effects[_user] = true;
        } else {
            effects[_user] = false;
        }
        address parent = DAPP(payable(dapp)).parents(_user);
        if (parent != address(0)) {
            checkNode(parent);
        }
    }

    function rescueToken(address tokenAddress, uint256 tokens)
    public
    onlyGovernance
    returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function rescueBNB(address payable _recipient) public onlyGovernance {
        _recipient.transfer(address(this).balance);
    }

}