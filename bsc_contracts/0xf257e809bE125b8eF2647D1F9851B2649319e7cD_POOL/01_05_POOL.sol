// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPancakeRouter {
    function getAmountsOut(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract POOL is Ownable, ReentrancyGuard {
    IPancakeRouter public pancakeRouter;
    uint public interestDecimal = 1000_000;
    uint public interestPeriod = 1 days;
    address public immutable WBNB;
    address public immutable BUSD;
    address public immutable tokenStake;
    struct Pool {
        uint timeLock;
        uint minLock;
        uint currentInterest; // daily
        uint totalLock;
        uint totalLockAsset;
        bool enable;
    }
    struct User {
        uint totalLock;
        uint totalLockAsset;
        uint startTime;
        uint totalReward;
    }
    struct Claim {
        uint date;
        uint amount;
        uint totalLock;
        uint interrest;
    }
    Pool[] public pools;
    mapping(address => mapping(uint => User)) public users; // user => pId => detail
    mapping(address => uint) public totalRewards;

    constructor(IPancakeRouter _pancakeRouteAddress, address _WBNBAddress, address _BUSDAddress, address _tokenStake) {
        pancakeRouter = _pancakeRouteAddress;
        WBNB = _WBNBAddress;
        BUSD = _BUSDAddress;
        tokenStake = _tokenStake;
    }
    function setInterestPeriod(uint _interestPeriod) external onlyOwner {
        interestPeriod = _interestPeriod;
    }

    function setRoute(IPancakeRouter _pancakeRouteAddress) external onlyOwner {
        pancakeRouter = _pancakeRouteAddress;
    }

    function bnbPrice() public view returns (uint[] memory amounts){
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = WBNB;
        amounts = IPancakeRouter(pancakeRouter).getAmountsIn(1 ether, path);
    }
    function tokenPrice(address token) public view returns (uint[] memory amounts){
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = BUSD;
        amounts = IPancakeRouter(pancakeRouter).getAmountsIn(1 ether, path);
    }
    function busd2Token(address token, uint busd) public view returns (uint amount){
        uint[] memory amounts = tokenPrice(token);
        amount = amounts[0] * busd / 1 ether;
    }
    function token2Busd(address token, uint tokenAmount) public view returns (uint amount){
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = BUSD;
        amount = IPancakeRouter(pancakeRouter).getAmountsOut(tokenAmount, path)[1];
    }
    function bnb2USD(uint amount) public view returns (uint usd) {
        usd = bnbPrice()[0] * amount / 1 ether;
    }
    function getPools(uint[] memory _pids) external view returns(Pool[] memory _pools) {
        _pools = new Pool[](_pids.length);
        for(uint i = 0; i < _pids.length; i++) _pools[i] = pools[_pids[i]];
    }

    function getDays() public view returns(uint) {
        return block.timestamp / interestPeriod;
    }

    function getUser(uint pid, address user) public view returns(uint _currentReward, User memory _user) {
        _currentReward = currentReward(pid, user);
        _user = users[user][pid];
    }

    function currentReward(uint pid, address user) public view returns(uint) {
        User memory u = users[user][pid];
        if(u.totalLock == 0) return 0;
        Pool memory p = pools[pid];
        uint spendDays = getDays() - u.startTime / interestPeriod;

        uint spendTime = block.timestamp - u.startTime;
        if(spendTime > p.timeLock) spendDays = p.timeLock / interestPeriod;

        return p.currentInterest * u.totalLockAsset * spendDays / interestDecimal;
    }
    function withdraw(uint pid) public nonReentrant {
        Pool storage p = pools[pid];
        User storage u = users[_msgSender()][pid];
        require(u.totalLock > 0, 'Pools::withdraw: not lock asset');
        require(block.timestamp > p.timeLock + u.startTime , 'Pools::withdraw: not meet time lock');
        _claimReward(pid);
        uint wdAmount = u.totalLockAsset;
        IERC20(tokenStake).transfer(_msgSender(), wdAmount);

        p.totalLock -= u.totalLock;
        p.totalLockAsset -= u.totalLockAsset;
        u.totalLock = 0;
        u.totalLockAsset = 0;
        u.startTime = 0;
    }
    function _claimReward(uint pid) internal {
        uint reward = currentReward(pid, _msgSender());
        if(reward > 0) {
            IERC20(tokenStake).transfer(_msgSender(), reward);
            users[_msgSender()][pid].totalReward += reward;

            totalRewards[_msgSender()] += reward;
        }
    }

    function deposit(uint pid, uint amount) external nonReentrant {

        Pool storage p = pools[pid];
        User storage u = users[_msgSender()][pid];
        uint _min;
        (_min) = busd2Token(tokenStake, p.minLock);
        require(p.enable, 'Pools::deposit: pool disabled');
        require(amount >= _min, 'Pools::deposit: Invalid amount');

        _claimReward(pid);
        uint _token2Busd = token2Busd(tokenStake, amount);
        u.totalLock += _token2Busd;
        u.totalLockAsset += amount;
        u.startTime = block.timestamp;
        p.totalLock += _token2Busd;
        p.totalLockAsset += amount;
        IERC20(tokenStake).transferFrom(_msgSender(), address(this), amount);
    }

    function togglePool(uint pid, bool enable) external onlyOwner {
        pools[pid].enable = enable;
    }
    function updateMinPool(uint pid, uint minLock) external onlyOwner {
        pools[pid].minLock = minLock;
    }
    function updateInterestPool(uint pid, uint currentInterest) external onlyOwner {
        pools[pid].currentInterest = currentInterest;
    }
    function updatePool(uint pid, uint timeLock, uint minLock, uint currentInterest, bool enable) external onlyOwner {
        pools[pid].timeLock = timeLock;
        pools[pid].minLock = minLock;
        pools[pid].currentInterest = currentInterest;
        pools[pid].enable = enable;
    }
    function addPool(uint timeLock, uint minLock, uint currentInterest) external onlyOwner {
        pools.push(Pool(timeLock, minLock * 1 ether, currentInterest, 0, 0, true));
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {
        uint _amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, _amount);
    }
    function getStuck(address payable user, uint amount) external onlyOwner {
        user.transfer(amount);
    }
}