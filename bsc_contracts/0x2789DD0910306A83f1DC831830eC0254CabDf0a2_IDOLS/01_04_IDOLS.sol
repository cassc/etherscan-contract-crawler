// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStake {
    function userLevel( address _user) external view returns (uint level);
}
contract IDOLS is Ownable {
    uint public cycleDays = 30 days;
    struct PoolVesting {
        uint tgePercent;
        uint tgeTime;
        uint vestingPercent;
        uint cycleVestingDay;
        uint lockingTime;
        address stake;
    }
    struct PoolInfo {
        IERC20 idoToken;
        IERC20 idoToken2Buy;
        uint tokenBuy2IDOtoken;
        uint totalAmount;
        uint remainAmount;
        uint startTime;
        uint endTime;
        uint level;
        uint status; // 0 => Upcoming; 1 => in progress; 2 => completed; 3 => refund; 4 => release
        address owner;
        bool isWL;
    }
    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(uint => PoolVesting) public poolVesting;
    mapping(address => mapping(address => uint)) public isBuyer; // user => idoToken => amount
    mapping(address => mapping(address => uint)) public claimed; // user => idoToken => amount
    struct MinMax {
        uint min;
        uint max;
        uint startTime;
        uint endTime;
    }
    mapping(address => mapping(uint => MinMax)) public minmax; // idoToken => rank => amount

    mapping(address => bool) public investors;
    mapping(address => bool) public operators;
    mapping(address => bool) public isWL;
    mapping(address => uint) public levelWL;
    uint public investorsLength;
    mapping(address => uint) public totalFundRaised; // idoToken => amount
    address public stakeCT;

    event Buy(address _user, uint _pid, uint _tokenAmount);
    event Refund(address _user, uint _pid, uint _tokenAmount);

    modifier onlyOperator() {
        require(owner() == _msgSender() || operators[_msgSender()], "IDO: caller is not the operator");
        _;
    }

    constructor(address _stakeCT) {
        stakeCT = _stakeCT;
    }

    function setMinMax(uint _pid, uint[] memory startTimes, uint[] memory endTimes, uint[] memory mins, uint[] memory maxs) external onlyOperator {
        require(mins.length == maxs.length, "Presale::setMinMax: Invalid length");
        address idoToken = address(poolInfo[_pid].idoToken);
        for(uint i = 0; i < mins.length; i++) {
            minmax[idoToken][i] = MinMax(mins[i], maxs[i], startTimes[i], endTimes[i]);
        }
    }

    function setCycleDay(uint _cycleDay) external onlyOperator {
        cycleDays = _cycleDay;
    }
    function refund(uint _pid) external {
        PoolInfo storage _pool = poolInfo[_pid];
        PoolVesting memory pp = poolVesting[_pid];
        address idoToken = address(_pool.idoToken);
        require(isBuyer[_msgSender()][idoToken] > 0, 'IDO: user is not buyer');
        require(claimed[_msgSender()][idoToken] == 0, 'IDO: user claimed');
        uint timeAllowRefund = isWL[_msgSender()] ? 7 days: 1 days;
        require(block.timestamp - pp.tgeTime <= timeAllowRefund || _pool.status == 3, 'IDO: refund time over');
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

    function availableClaimAmount(uint _pid, address _user) public view returns(uint available) {
        PoolInfo memory p = poolInfo[_pid];
        PoolVesting memory pp = poolVesting[_pid];
        address idoToken = address(p.idoToken);
        if(block.timestamp < pp.tgeTime || isBuyer[_user][idoToken] == 0) return 0;

        uint timespend = block.timestamp - pp.tgeTime;
        uint round = timespend / cycleDays;
        uint buyAmount = isBuyer[_user][idoToken];
        uint userClaimed = claimed[_user][idoToken];
        uint firstClaim = buyAmount * pp.tgePercent / 100;
        available = buyAmount * pp.vestingPercent / 100 * round + firstClaim - userClaimed;
        uint remain = buyAmount - userClaimed;
        if(available > remain) available = remain;
    }
    function claim(uint _pid) external {
        PoolInfo storage _pool = poolInfo[_pid];
        require(_pool.status == 4, 'IDO: pool not release');
        uint available = availableClaimAmount(_pid, _msgSender());
        require(available > 0, 'Presale::claim: claim not available');
        _pool.idoToken.transfer(_msgSender(), available);
        claimed[_msgSender()][address(_pool.idoToken)] += available;
    }
    function _buy(uint _pid, uint _amount) public {
        PoolInfo storage _pool = poolInfo[_pid];
        PoolVesting memory pp = poolVesting[_pid];
        require(_pool.status == 1, 'IDO: pool not active');
        require(_pool.startTime <= block.timestamp && _pool.endTime > block.timestamp, 'IDO: pool not on time');
        require(_pool.remainAmount >= _amount, 'IDO: over remain amount');

        address idoToken = address(_pool.idoToken);
        uint level = isWL[_msgSender()] ? levelWL[_msgSender()] : IStake(pp.stake).userLevel(_msgSender());
        MinMax memory mm = minmax[idoToken][level];
        require(level >= _pool.level, 'Presale::buy: User not meet level');
        require(mm.startTime <= block.timestamp && mm.endTime > block.timestamp, 'IDO: rank not on time');
        require(_amount >= mm.min && _amount + isBuyer[_msgSender()][idoToken] <= mm.max, 'Presale::buy: over limit buy');

        uint buyAmount = _amount * _pool.tokenBuy2IDOtoken / 1 ether;
        _pool.idoToken2Buy.transferFrom(_msgSender(), address(this), buyAmount);
        isBuyer[_msgSender()][idoToken] += _amount;
        _pool.remainAmount -= _amount;
        if(!investors[_msgSender()]) {
            investors[_msgSender()] = true;
            investorsLength++;
        }
        totalFundRaised[idoToken] += buyAmount;
        emit Buy(_msgSender(), _pid, _amount);
    }
    function buyWL(uint _pid, uint _amount) external {
        require(isWL[_msgSender()], 'IDO::buyWL: user not on WL');
        _buy(_pid, _amount);
    }
    function buy(uint _pid, uint _amount) external {
        require(!poolInfo[_pid].isWL, 'IDO::buy: the pool require WL');
        _buy(_pid, _amount);
    }
    function setStakes(address _stake)  external onlyOperator {
        stakeCT = _stake;
    }

    function setOperators(address _operator, bool enable) external onlyOwner {
        operators[_operator] = enable;
    }

    function setIDOSatus(uint _pid, uint _status) external onlyOperator {
        require(_status < 5, 'IDO: invalid status');
        poolInfo[_pid].status = _status;
    }

    function setWL(address[] memory _users, uint[] memory levels, bool status) external onlyOperator {
        for(uint i = 0; i < _users.length; i++) {
            isWL[_users[i]] = status;
            levelWL[_users[i]] = levels[i];
        }
    }

    function setIDOTgeTime(uint _pid, uint tgeTime) external onlyOperator {
        poolVesting[_pid].tgeTime = tgeTime;
    }

    function addPool(IERC20 _idoToken, IERC20 _idoToken2buy, uint _tokenBuy2IDOtoken,
        uint _totalAmount, uint _startTime, uint _endTime, uint tgePercent, uint tgeTime, uint lockingTime,
        uint vestingPercent, uint _level, bool _isWL) external onlyOperator{
        poolInfo.push(PoolInfo(_idoToken, _idoToken2buy, _tokenBuy2IDOtoken, _totalAmount,
            _totalAmount, _startTime, _endTime, _level, 1, _msgSender(), _isWL));
        poolVesting[poolInfo.length-1] = PoolVesting(tgePercent, tgeTime, vestingPercent, cycleDays, lockingTime, stakeCT);
    }
    function updatePool(uint pid, uint _startTime, uint _endTime, uint tgePercent, uint tgeTime, uint lockingTime,
        uint vestingPercent, uint _level, bool _isWL, uint status) external onlyOperator{
        poolInfo[pid].startTime = _startTime;
        poolInfo[pid].endTime = _endTime;
        poolInfo[pid].isWL = _isWL;
        poolInfo[pid].level = _level;
        poolInfo[pid].status = status;

        poolVesting[pid].tgePercent = tgePercent;
        poolVesting[pid].tgeTime = tgeTime;
        poolVesting[pid].vestingPercent = vestingPercent;
        poolVesting[pid].lockingTime = lockingTime;
        poolVesting[pid].stake = stakeCT;
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPool(uint _pid) external view returns(IERC20 idoToken, IERC20 idoToken2Buy, uint vestingPercent, uint totalAmount, uint status, bool _isWL) {
        PoolInfo memory pool = poolInfo[_pid];
        PoolVesting memory pp = poolVesting[_pid];
        idoToken = pool.idoToken;
        idoToken2Buy = pool.idoToken2Buy;
        totalAmount = pool.totalAmount;
        vestingPercent = pp.vestingPercent;
        status = pool.status;
        _isWL = pool.isWL;
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint _amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, _amount);
    }
}