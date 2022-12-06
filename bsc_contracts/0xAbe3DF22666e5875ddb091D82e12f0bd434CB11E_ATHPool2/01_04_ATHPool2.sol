// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStake {
    function userLevel( address _user) external view returns (uint level);
}
interface IATHPool {
    function userWL(address _user) external view returns(bool isWL, uint maxAmount);
    function availableClaimFirstAmount(uint _pid, address _user) external view returns(uint available);
    function availableClaimAmount(uint _pid, address _user) external view returns(uint available);
    function claimed(address _user, address idoToken) external view returns(uint totalClaimed);
    function isBuyer(address _user, address idoToken) external view returns(uint totalBuy);
}
contract ATHPool2 is Ownable {
    uint public cycleDays = 30 days;
    uint public firstTimeWait = 10 hours;
    IATHPool athPool;
    IATHPool athPool1;
    mapping(address => IStake) public stakes; // idoToken => stake contract
    struct PoolInfo {
        IERC20 idoToken;
        IERC20 idoToken2Buy;
        uint tokenBuy2IDOtoken;
        uint totalAmount;
        uint remainAmount;
        uint startTime;
        uint endTime;
        uint tgePercent;
        uint vestingPercent;
        uint level;
        uint status; // 0 => Upcoming; 1 => in progress; 2 => completed; 3 => refund; 4 => release
        address owner;
    }
    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => mapping(address => uint)) public isBuyer; // user => idoToken => amount
    mapping(address => mapping(address => uint)) public claimed; // user => idoToken => amount
    struct MinMax {
        uint min;
        uint max;
        uint startTime;
        uint endTime;
        uint lockTime;
    }
    mapping(address => mapping(uint => MinMax)) public minmax; // idoToken => rank => amount

    uint public investorsLength;
    mapping(address => uint) public totalFundRaised; // idoToken => amount
    struct WL {
        bool isWL;
        uint maxAmount;
    }
    mapping(address => WL) public userWL;
    mapping(address => bool) public isATHpool1;
    event Buy(address _user, uint _pid, uint _tokenAmount);
    event Refund(address _user, uint _pid, uint _tokenAmount);
    constructor(IATHPool _athPool, IATHPool _athPool1) {
        athPool = _athPool;
        athPool1 = _athPool1;
        poolInfo.push(PoolInfo(IERC20(0x525B6dC1A1965200754054D4BF548E31E26e9503), IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56),
            2500000000000000, 10000000000000000000000000,
            0, 1667534400, 1667620800, 20, 20, 1, 4, 0x09a4Fb0a232D60362fe70F8fE21ed6eef02D9eA3));
    }

    function setWL(address[] memory users, uint[] memory maxAmounts, bool enable) external onlyOwner {
        for(uint i = 0; i < maxAmounts.length; i++) {
            userWL[users[i]] = WL(enable, maxAmounts[i]);
        }
    }
    function setMinMax(uint _pid, uint[] memory startTimes, uint[] memory endTimes, uint[] memory mins, uint[] memory maxs, IStake _stake, uint[] memory _lockTimes) external onlyOwner {
        require(mins.length == maxs.length, "Presale::setMinMax: Invalid length");
        address idoToken = address(poolInfo[_pid].idoToken);
        for(uint i = 0; i < mins.length; i++) {
            minmax[idoToken][i] = MinMax(mins[i], maxs[i], startTimes[i], endTimes[i], _lockTimes[i]);
            stakes[idoToken] = _stake;
        }
    }

    function setCycleDay(uint _cycleDay) external onlyOwner {
        cycleDays = _cycleDay;
    }
    function setFirstTimeWait(uint _firstTimeWait) external onlyOwner {
        firstTimeWait = _firstTimeWait;
    }
    function refund(uint _pid) external {
        PoolInfo storage _pool = poolInfo[_pid];
        address idoToken = address(_pool.idoToken);
        require(isBuyer[_msgSender()][idoToken] > 0, 'IDO: user is not buyer');
        require(block.timestamp - _pool.endTime <= 1 days || _pool.status == 3, 'IDO: refund time over');
        uint buyAmount = isBuyer[_msgSender()][idoToken] * _pool.tokenBuy2IDOtoken / 1 ether;
        _pool.idoToken2Buy.transfer(_msgSender(), buyAmount);

        _pool.remainAmount += isBuyer[_msgSender()][idoToken];

        totalFundRaised[idoToken] -= buyAmount;
        emit Refund(_msgSender(), _pid, isBuyer[_msgSender()][idoToken]);
        isBuyer[_msgSender()][idoToken] = 0;
    }
    function withdraw(uint _pid) external {
        PoolInfo storage _pool = poolInfo[_pid];
        uint totalRaise = totalFundRaised[address(_pool.idoToken)];
        require(block.timestamp - _pool.endTime > 1 days, 'IDO: not meet withdraw time');
        require(_msgSender() == _pool.owner, 'IDO: not pool owner');
        require(totalRaise > 0, 'IDO: raised values');
        _pool.idoToken2Buy.transfer(_msgSender(), totalRaise);
        _pool.status = 4;
    }
    function availableClaimFirstAmount(uint _pid, address _user) public view returns(uint available) {
        available = athPool1.availableClaimFirstAmount(_pid, _user);
    }
    function availableClaimAmount(uint _pid, address _user) public view returns(uint available) {
        PoolInfo memory p = poolInfo[_pid];
        address idoToken = address(p.idoToken);

        uint timespend = block.timestamp + cycleDays - p.endTime - minmax[idoToken][0].lockTime;
        uint round = timespend / cycleDays;
        uint buyAmount = athPool.isBuyer(_user, idoToken) + athPool1.isBuyer(_user, idoToken);
        uint firstClaim = buyAmount * p.tgePercent / 100;
        available = buyAmount * p.vestingPercent / 100 * round + firstClaim - claimed[_user][idoToken];
        uint remain = buyAmount - claimed[_user][idoToken];
        if(available > remain) available = remain;
        if(!isATHpool1[_user]) available -= athPool.claimed(_user, address(p.idoToken));
    }
    function claim(uint _pid) external {
        bool isWL;
        (isWL, ) = athPool.userWL(_msgSender());
        require(!isWL, 'IDO::claim: not userWL');
        PoolInfo storage _pool = poolInfo[_pid];
        require(_pool.status == 4, 'IDO: pool not release');
        uint available = availableClaimAmount(_pid, _msgSender()) + availableClaimFirstAmount(_pid, _msgSender());
        require(available > 0, 'Presale::claim: claim not available');
        _pool.idoToken.transfer(_msgSender(), available);
        claimed[_msgSender()][address(_pool.idoToken)] += available;
        if(!isATHpool1[_msgSender()]) {
            isATHpool1[_msgSender()] = true;
            claimed[_msgSender()][address(_pool.idoToken)] += athPool.claimed(_msgSender(), address(_pool.idoToken));
            isBuyer[_msgSender()][address(_pool.idoToken)] = athPool.isBuyer(_msgSender(), address(_pool.idoToken));
        }
    }
    function _buy(uint _pid, uint _amount) internal {
        PoolInfo storage _pool = poolInfo[_pid];
        require(_pool.status == 1, 'IDO: pool not active');
        require(_pool.startTime <= block.timestamp && _pool.endTime > block.timestamp, 'IDO: pool not on time');
        require(_pool.remainAmount >= _amount, 'IDO: over remain amount');

        address idoToken = address(_pool.idoToken);
        uint level = stakes[idoToken].userLevel(_msgSender());
        MinMax memory mm = minmax[idoToken][level];
        require(mm.startTime <= block.timestamp && mm.endTime > block.timestamp, 'IDO: rank not on time');
        require(level >= _pool.level, 'Presale::buy: User not meet level');
        require(_amount + isBuyer[_msgSender()][idoToken] <= minmax[idoToken][level].max, 'Presale::buy: over limit buy');

        uint buyAmount = _amount * _pool.tokenBuy2IDOtoken / 1 ether;
        _pool.idoToken2Buy.transferFrom(_msgSender(), address(this), buyAmount);
        isBuyer[_msgSender()][idoToken] += _amount;
        _pool.remainAmount -= _amount;

        totalFundRaised[idoToken] += buyAmount;
        emit Buy(_msgSender(), _pid, _amount);
    }
    function _buyWL(uint _pid, uint _amount) internal {
        PoolInfo storage _pool = poolInfo[_pid];
        require(_pool.status == 1, 'IDO: pool not active');
        require(_pool.startTime <= block.timestamp && _pool.endTime > block.timestamp, 'IDO: pool not on time');
        require(_pool.remainAmount >= _amount, 'IDO: over remain amount');

        address idoToken = address(_pool.idoToken);
        require(_amount + isBuyer[_msgSender()][idoToken] <= userWL[_msgSender()].maxAmount, 'Presale::buy: over limit buy');

        uint buyAmount = _amount * _pool.tokenBuy2IDOtoken / 1 ether;
        _pool.idoToken2Buy.transferFrom(_msgSender(), address(this), buyAmount);
        isBuyer[_msgSender()][idoToken] += _amount;
        _pool.remainAmount -= _amount;

        totalFundRaised[idoToken] += buyAmount;
        emit Buy(_msgSender(), _pid, _amount);
    }
    function buy(uint _pid, uint _amount) external {
        if(userWL[_msgSender()].isWL) _buyWL(_pid, _amount);
        else _buy(_pid, _amount);
    }

    function setIDOSatus(uint _pid, uint _status) external onlyOwner {
        require(_status < 5 && _status > poolInfo[_pid].status, 'IDO: invalid status');
        poolInfo[_pid].status = _status;
    }

    function setPrice(uint _pid, uint _price) external onlyOwner {
        require(_price > 0, 'IDO: invalid price');
        poolInfo[_pid].tokenBuy2IDOtoken = _price;
    }

    function addPool(IERC20 _idoToken, IERC20 _idoToken2buy, uint _tokenBuy2IDOtoken,
        uint _totalAmount, uint _startTime, uint _endTime, uint tgePercent,
        uint vestingPercent, uint _level, uint _status) external onlyOwner{
//        _idoToken.transferFrom(_msgSender(), address(this), _totalAmount);
        poolInfo.push(PoolInfo(_idoToken, _idoToken2buy, _tokenBuy2IDOtoken, _totalAmount,
            _totalAmount, _startTime, _endTime, tgePercent, vestingPercent, _level, _status, _msgSender()));
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPool(uint _pid) external view returns(IERC20 idoToken, IERC20 idoToken2Buy,
        uint vestingPercent,
        uint totalAmount, uint status) {
        PoolInfo memory pool = poolInfo[_pid];
        idoToken = pool.idoToken;
        idoToken2Buy = pool.idoToken2Buy;
        totalAmount = pool.totalAmount;
        vestingPercent = pool.vestingPercent;
        status = pool.status;
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint _amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, _amount);
    }
}