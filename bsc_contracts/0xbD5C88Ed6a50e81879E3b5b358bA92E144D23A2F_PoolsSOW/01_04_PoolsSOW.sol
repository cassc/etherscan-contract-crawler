// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

interface IRefferal {
    function userInfos(address _user) external view returns(address user,
        address refferBy,
        uint dateTime,
        uint totalRefer,
        uint totalRefer7,
        bool top10Refer);
    function isReferrer(address _user) external view returns(bool);
}
interface ICOMM {
    function handleComm(address _fromUser, uint _amount, IERC20 tokenBuy) external;
}
contract PoolsSOW is Ownable {
    IPancakeRouter public pancakeRouter;
    IRefferal refer;
    ICOMM public commTreasury;
    uint public interestDecimal = 1000_000;
    uint public panaltyFee = 100000; // 10%
    uint public comm2refer = 50000; // 5%
    uint public interestPeriod = 1 days;
    address public immutable WBNB;
    address public immutable BUSD;
    address public immutable tokenStake;
    struct Pool {
        uint timeLock;
        uint minLock;
        uint currentInterest; // daily
        uint earlyWDInterest; // daily
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
    mapping(address => mapping(uint => Claim[])) public userClaimed;
    mapping(address => uint) public remainComm;
    mapping(address => uint) public volumeOntree;
    mapping(address => uint) public totalComms;
    mapping(address => uint) public totalRewards;
    address public ceo;

    modifier onlyCeo() {
        require(owner() == _msgSender(), "Pools: caller is not the ceo");
        _;
    }
    constructor(IRefferal _refer, address _ceo, IPancakeRouter _pancakeRouteAddress, address _WBNBAddress, address _BUSDAddress, address _tokenStake) {
        refer = _refer;
        ceo = _ceo;
        pancakeRouter = _pancakeRouteAddress;
        WBNB = _WBNBAddress;
        BUSD = _BUSDAddress;
        tokenStake = _tokenStake;
    }
    function setTreasury(ICOMM _commTreasury) external onlyOwner {
        commTreasury = _commTreasury;
    }
    function setPanaltyFee(uint _panaltyFee) external onlyOwner {
        panaltyFee = _panaltyFee;
    }
    function setComm2refer(uint _comm2refer) external onlyOwner {
        comm2refer = _comm2refer;
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
    function setRefer(IRefferal _refer) external onlyOwner {
        refer = _refer;
    }
    function setCeo(address _ceo) external onlyCeo {
        ceo = _ceo;
    }
    function getPools(uint[] memory _pids) external view returns(Pool[] memory _pools) {
        _pools = new Pool[](_pids.length);
        for(uint i = 0; i < _pids.length; i++) _pools[i] = pools[_pids[i]];
    }

    function getDays() public view returns(uint) {
        return block.timestamp / interestPeriod;
    }
    function getUsersClaimedLength(uint pid, address user) external view returns(uint length) {
        return userClaimed[user][pid].length;
    }
    function getUsersClaimed(uint pid, address user, uint _limit, uint _skip) external view returns(Claim[] memory list, uint totalItem) {
        totalItem = userClaimed[user][pid].length;
        uint limit = _limit <= totalItem - _skip ? _limit + _skip : totalItem;
        uint lengthReturn = _limit <= totalItem - _skip ? _limit : totalItem - _skip;
        list = new Claim[](lengthReturn);
        for(uint i = _skip; i < limit; i++) {
            list[i-_skip] = userClaimed[user][pid][i];
        }
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
        uint currentInterest = p.currentInterest;
        if(spendTime < p.timeLock) currentInterest = p.earlyWDInterest;
        else spendDays = p.timeLock / interestPeriod;
        return currentInterest * u.totalLock * spendDays / interestDecimal;
    }
    function withdraw(uint pid) public {
        Pool storage p = pools[pid];
        User storage u = users[_msgSender()][pid];
        require(u.totalLock > 0, 'Pools::withdraw: not lock asset');
        claimReward(pid);
        uint wdAmount = u.totalLockAsset;
        uint spendTime = block.timestamp - u.startTime;
        if(spendTime < p.timeLock) wdAmount = wdAmount * (interestDecimal - panaltyFee) / interestDecimal;
        IERC20(tokenStake).transfer(_msgSender(), wdAmount);

        p.totalLock -= u.totalLock;
        p.totalLockAsset -= u.totalLockAsset;
        u.totalLock = 0;
        u.totalLockAsset = 0;
        u.startTime = 0;
    }
    function claimReward(uint pid) internal {
        uint reward = currentReward(pid, _msgSender());
        if(reward > 0) {
            IERC20(BUSD).transfer(_msgSender(), reward);
            userClaimed[_msgSender()][pid].push(Claim(getDays(), reward, users[_msgSender()][pid].totalLock, pools[pid].currentInterest));
            users[_msgSender()][pid].totalReward += reward;
            totalRewards[_msgSender()] += reward;
        }
    }
    function logVolume(uint amount) internal {
        uint usd = bnb2USD(amount);
        address from = _msgSender();
        address _refferBy;
        for(uint i = 0; i < 7; i++) {
            (, _refferBy,,,,) = refer.userInfos(from);
            if(_refferBy == from) break;
            volumeOntree[_refferBy] += usd;
            from = _refferBy;
        }

    }
    function deposit(uint pid, uint amount) external {

        Pool storage p = pools[pid];
        User storage u = users[_msgSender()][pid];
        uint _min;
        (_min) = busd2Token(tokenStake, p.minLock);
        require(p.enable, 'Pools::deposit: pool disabled');
        require(amount >= _min, 'Pools::deposit: Invalid amount');

        uint comm = amount * comm2refer / interestDecimal;

        claimReward(pid);
        uint _token2Busd = token2Busd(tokenStake, amount);
        u.totalLock += _token2Busd;
        u.totalLockAsset += amount;
        u.startTime = block.timestamp;
        p.totalLock += _token2Busd;
        p.totalLockAsset += amount;
        logVolume(_token2Busd);
        if(refer.isReferrer(_msgSender())) {
            IERC20(tokenStake).transferFrom(_msgSender(), address(this), amount - comm);
            IERC20(tokenStake).transferFrom(_msgSender(), address(commTreasury), comm);

            commTreasury.handleComm(_msgSender(), comm, IERC20(tokenStake));
        } else {
            IERC20(tokenStake).transferFrom(_msgSender(), address(this), amount);
        }
    }
    function claimComm() external {
        require(remainComm[_msgSender()] > 0, 'Pools::claimComm: not comm');
        IERC20(tokenStake).transfer(_msgSender(), remainComm[_msgSender()]);
        totalComms[_msgSender()] += remainComm[_msgSender()];
        remainComm[_msgSender()] = 0;
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
    function updatePool(uint pid, uint timeLock, uint minLock, uint currentInterest, uint earlyWDInterest, bool enable) external onlyOwner {
        pools[pid].timeLock = timeLock;
        pools[pid].minLock = minLock;
        pools[pid].currentInterest = currentInterest;
        pools[pid].earlyWDInterest = earlyWDInterest;
        pools[pid].enable = enable;
    }
    function addPool(uint timeLock, uint minLock, uint currentInterest, uint earlyWDInterest) external onlyOwner {
        pools.push(Pool(timeLock, minLock * 1 ether, currentInterest, earlyWDInterest, 0, 0, true));
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {
        uint _amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, _amount);
    }
    function getStuck(address payable user, uint amount) external onlyOwner {
        user.transfer(amount);
    }
}