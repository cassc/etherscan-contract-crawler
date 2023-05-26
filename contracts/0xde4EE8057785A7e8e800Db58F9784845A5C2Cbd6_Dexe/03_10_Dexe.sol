// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './Ownable.sol';
import './SafeMath.sol';
import './ERC20Burnable.sol';

import './IPriceFeed.sol';
import './IDexe.sol';

library ExtraMath {
    using SafeMath for uint;

    function divCeil(uint _a, uint _b) internal pure returns(uint) {
        if (_a.mod(_b) > 0) {
            return (_a / _b).add(1);
        }
        return _a / _b;
    }

    function toUInt8(uint _a) internal pure returns(uint8) {
        require(_a <= uint8(-1), 'uint8 overflow');
        return uint8(_a);
    }

    function toUInt32(uint _a) internal pure returns(uint32) {
        require(_a <= uint32(-1), 'uint32 overflow');
        return uint32(_a);
    }

    function toUInt120(uint _a) internal pure returns(uint120) {
        require(_a <= uint120(-1), 'uint120 overflow');
        return uint120(_a);
    }

    function toUInt128(uint _a) internal pure returns(uint128) {
        require(_a <= uint128(-1), 'uint128 overflow');
        return uint128(_a);
    }
}

contract Dexe is Ownable, ERC20Burnable, IDexe {
    using ExtraMath for *;
    using SafeMath for *;

    uint private constant DEXE = 10**18;
    uint private constant USDC = 10**6;
    uint private constant USDT = 10**6;
    uint private constant MONTH = 30 days;
    uint public constant ROUND_SIZE_BASE = 190_476;
    uint public constant ROUND_SIZE = ROUND_SIZE_BASE * DEXE;
    uint public constant FIRST_ROUND_SIZE_BASE = 1_000_000;


    IERC20 public usdcToken;
    IERC20 public usdtToken;
    IPriceFeed public usdtPriceFeed; // Provides USDC per 1 * USDT
    IPriceFeed public dexePriceFeed; // Provides USDC per 1 * DEXE
    IPriceFeed public ethPriceFeed; // Provides USDC per 1 * ETH

    // Deposits are immediately transferred here.
    address payable public treasury;

    enum LockType {
        Staking,
        Foundation,
        Team,
        Partnership,
        School,
        Marketing
    }

    enum ForceReleaseType {
        X7,
        X10,
        X15,
        X20
    }

    struct LockConfig {
        uint32 releaseStart;
        uint32 vesting;
    }

    struct Lock {
        uint128 balance; // Total locked.
        uint128 released; // Released so far.
    }

    uint public averagePrice; // 2-10 rounds average.
    uint public override launchedAfter; // How many seconds passed between sale end and product launch.

    mapping(uint => mapping(address => HolderRound)) internal _holderRounds;
    mapping(address => UserInfo) internal _usersInfo;
    mapping(address => BalanceInfo) internal _balanceInfo;

    mapping(LockType => LockConfig) public lockConfigs;
    mapping(LockType => mapping(address => Lock)) public locks;

    mapping(address => mapping(ForceReleaseType => bool)) public forceReleased;

    uint constant ROUND_DURATION_SEC = 86400;
    uint constant TOTAL_ROUNDS = 22;

    struct Round {
        uint120 totalDeposited; // USDC
        uint128 roundPrice; // USDC per 1 * DEXE
    }

    mapping(uint => Round) public rounds; // Indexes are 1-22.

    // Sunday, September 28, 2020 12:00:00 PM GMT
    uint public constant tokensaleStartDate = 1601294400;
    uint public override constant tokensaleEndDate = tokensaleStartDate + ROUND_DURATION_SEC * TOTAL_ROUNDS;

    event NoteDeposit(address sender, uint value, bytes data);
    event Note(address sender, bytes data);

    modifier noteDeposit() {
        emit NoteDeposit(_msgSender(), msg.value, msg.data);
        _;
    }

    modifier note() {
        emit Note(_msgSender(), msg.data);
        _;
    }

    constructor(address _distributor) ERC20('Dexe', 'DEXE') {
        _mint(address(this), 99_000_000 * DEXE);

        // Market Liquidity Fund.
        _mint(_distributor, 1_000_000 * DEXE);

        // Staking rewards are locked on the Dexe itself.
        locks[LockType.Staking][address(this)].balance = 10_000_000.mul(DEXE).toUInt128();

        locks[LockType.Foundation][_distributor].balance = 33_000_000.mul(DEXE).toUInt128();
        locks[LockType.Team][_distributor].balance = 20_000_000.mul(DEXE).toUInt128();
        locks[LockType.Partnership][_distributor].balance = 16_000_000.mul(DEXE).toUInt128();
        locks[LockType.School][_distributor].balance = 10_000_000.mul(DEXE).toUInt128();
        locks[LockType.Marketing][_distributor].balance = 5_000_000.mul(DEXE).toUInt128();

        lockConfigs[LockType.Staking].releaseStart = (tokensaleEndDate).toUInt32();
        lockConfigs[LockType.Staking].vesting = (365 days).toUInt32();

        lockConfigs[LockType.Foundation].releaseStart = (tokensaleEndDate + 365 days).toUInt32();
        lockConfigs[LockType.Foundation].vesting = (1460 days).toUInt32();

        lockConfigs[LockType.Team].releaseStart = (tokensaleEndDate + 180 days).toUInt32();
        lockConfigs[LockType.Team].vesting = (730 days).toUInt32();

        lockConfigs[LockType.Partnership].releaseStart = (tokensaleEndDate + 90 days).toUInt32();
        lockConfigs[LockType.Partnership].vesting = (365 days).toUInt32();

        lockConfigs[LockType.School].releaseStart = (tokensaleEndDate + 60 days).toUInt32();
        lockConfigs[LockType.School].vesting = (365 days).toUInt32();

        lockConfigs[LockType.Marketing].releaseStart = (tokensaleEndDate + 30 days).toUInt32();
        lockConfigs[LockType.Marketing].vesting = (365 days).toUInt32();

        treasury = payable(_distributor);
    }

    function setUSDTTokenAddress(IERC20 _address) external onlyOwner() note() {
        usdtToken = _address;
    }

    function setUSDCTokenAddress(IERC20 _address) external onlyOwner() note() {
        usdcToken = _address;
    }

    function setUSDTFeed(IPriceFeed _address) external onlyOwner() note() {
        usdtPriceFeed = _address;
    }

    function setDEXEFeed(IPriceFeed _address) external onlyOwner() note() {
        dexePriceFeed = _address;
    }

    function setETHFeed(IPriceFeed _address) external onlyOwner() note() {
        ethPriceFeed = _address;
    }

    function setTreasury(address payable _address) external onlyOwner() note() {
        require(_address != address(0), 'Not zero address required');

        treasury = _address;
    }

    function addToWhitelist(address _address, uint _limit) external onlyOwner() note() {
        _updateWhitelist(_address, _limit);
    }

    function removeFromWhitelist(address _address) external onlyOwner() note() {
        _updateWhitelist(_address, 0);
    }

    function _updateWhitelist(address _address, uint _limit) private {
        _usersInfo[_address].firstRoundLimit = _limit.toUInt120();
    }

    // For UI purposes.
    function getAllRounds() external view returns(Round[22] memory) {
        Round[22] memory _result;
        for (uint i = 1; i <= 22; i++) {
            _result[i-1] = rounds[i];
        }
        return _result;
    }

    // For UI purposes.
    function getFullHolderInfo(address _holder) external view
    returns(
        UserInfo memory _info,
        HolderRound[22] memory _rounds,
        Lock[6] memory _locks,
        bool _isWhitelisted,
        bool[4] memory _forceReleases,
        uint _balance
    ) {
        _info = _usersInfo[_holder];
        for (uint i = 1; i <= 22; i++) {
            _rounds[i-1] = _holderRounds[i][_holder];
        }
        for (uint i = 0; i < 6; i++) {
            _locks[i] = locks[LockType(i)][_holder];
        }
        _isWhitelisted = _usersInfo[_holder].firstRoundLimit > 0;
        for (uint i = 0; i < 4; i++) {
            _forceReleases[i] = forceReleased[_holder][ForceReleaseType(i)];
        }
        _balance = balanceOf(_holder);
        return (_info, _rounds, _locks, _isWhitelisted, _forceReleases, _balance);
    }

    // Excludes possibility of unexpected price change.
    function prepareDistributionPrecise(uint _round, uint _botPriceLimit, uint _topPriceLimit)
    external onlyOwner() note() {
        uint _currentPrice = updateAndGetCurrentPrice();
        require(_botPriceLimit <= _currentPrice && _currentPrice <= _topPriceLimit,
           'Price is out of range');

        _prepareDistribution(_round);
    }

    // Should be performed in the last hour of every round.
    function prepareDistribution(uint _round) external onlyOwner() note() {
        _prepareDistribution(_round);
    }

    function _prepareDistribution(uint _round) private {
        require(isRoundDepositsEnded(_round),
            'Deposit round not ended');

        Round memory _localRound = rounds[_round];
        require(_localRound.roundPrice == 0, 'Round already prepared');
        require(_round > 0 && _round < 23, 'Round is not valid');

        if (_round == 1) {
            _localRound.roundPrice = _localRound.totalDeposited.divCeil(FIRST_ROUND_SIZE_BASE).toUInt128();

            // If nobody deposited.
            if (_localRound.roundPrice == 0) {
                _localRound.roundPrice = 1;
            }
            rounds[_round].roundPrice = _localRound.roundPrice;
            return;
        }

        require(isRoundPrepared(_round.sub(1)), 'Previous round not prepared');

        uint _localRoundPrice = updateAndGetCurrentPrice();
        uint _totalTokensSold = _localRound.totalDeposited.mul(DEXE) / _localRoundPrice;

        if (_totalTokensSold < ROUND_SIZE) {
            // Apply 0-10% discount based on how much tokens left. Empty round applies 10% discount.
            _localRound.roundPrice =
                (uint(9).mul(ROUND_SIZE_BASE).mul(_localRoundPrice).add(_localRound.totalDeposited)).divCeil(
                uint(10).mul(ROUND_SIZE_BASE)).toUInt128();
            uint _discountedTokensSold = _localRound.totalDeposited.mul(DEXE) / _localRound.roundPrice;

            rounds[_round].roundPrice = _localRound.roundPrice;
            _burn(address(this), ROUND_SIZE.sub(_discountedTokensSold));
        } else {
            // Round overflown, calculate price based on even spread of available tokens.
            rounds[_round].roundPrice = _localRound.totalDeposited.divCeil(ROUND_SIZE_BASE).toUInt128();
        }

        if (_round == 10) {
            uint _averagePrice;
            for (uint i = 2; i <= 10; i++) {
                _averagePrice = _averagePrice.add(rounds[i].roundPrice);
            }

            averagePrice = _averagePrice / 9;
        }
    }

    // Receive tokens/rewards for all processed rounds.
    function receiveAll() public {
        _receiveAll(_msgSender());
    }

    function _receiveAll(address _holder) private {
        // Holder received everything.
        if (_holderRounds[TOTAL_ROUNDS][_holder].status == HolderRoundStatus.Received) {
            return;
        }

        // Holder didn't participate in the sale.
        if (_usersInfo[_holder].firstRoundDeposited == 0) {
            return;
        }

        if (_notPassed(tokensaleStartDate)) {
            return;
        }

        uint _currentRound = currentRound();

        for (uint i = _usersInfo[_holder].firstRoundDeposited; i < _currentRound; i++) {
            // Skip received rounds.
            if (_holderRounds[i][_holder].status == HolderRoundStatus.Received) {
                continue;
            }

            Round memory _localRound = rounds[i];
            require(_localRound.roundPrice > 0, 'Round is not prepared');

            _holderRounds[i][_holder].status = HolderRoundStatus.Received;
            _receiveDistribution(i, _holder, _localRound);
            _receiveRewards(i, _holder, _localRound);
        }
    }

    // Receive tokens based on the deposit.
    function _receiveDistribution(uint _round, address _holder, Round memory _localRound) private {
        HolderRound memory _holderRound = _holderRounds[_round][_holder];
        uint _balance = _holderRound.deposited.mul(DEXE) / _localRound.roundPrice;

        uint _endBalance = _holderRound.endBalance.add(_balance);
        _holderRounds[_round][_holder].endBalance = _endBalance.toUInt128();
        if (_round < TOTAL_ROUNDS) {
            _holderRounds[_round.add(1)][_holder].endBalance =
                _holderRounds[_round.add(1)][_holder].endBalance.add(_endBalance).toUInt128();
        }
        _transfer(address(this), _holder, _balance);
    }

    // Receive rewards based on the last round balance, participation in 1st round and this round fill.
    function _receiveRewards(uint _round, address _holder, Round memory _localRound) private {
        if (_round > 21) {
            return;
        }
        HolderRound memory _holderRound = _holderRounds[_round][_holder];

        uint _reward;
        if (_round == 1) {
            // First round is always 5%.
            _reward = (_holderRound.endBalance).mul(5) / 100;
        } else {
            uint _x2 = 1;
            uint _previousRoundBalance = _holderRounds[_round.sub(1)][_holder].endBalance;

            // Double reward if increased balance since last round by 1%+.
            if (_previousRoundBalance > 0 &&
                (_previousRoundBalance.mul(101) / 100) < _holderRound.endBalance)
            {
                _x2 = 2;
            }

            uint _roundPrice = _localRound.roundPrice;
            uint _totalDeposited = _localRound.totalDeposited;
            uint _holderBalance = _holderRound.endBalance;
            uint _minPercent = 2;
            uint _maxBonusPercent = 6;
            if (_holderRounds[1][_holder].endBalance > 0) {
                _minPercent = 5;
                _maxBonusPercent = 15;
            }
            // Apply reward modifiers in the following way:
            // 1. If participated in round 1, then the base is 5%, otherwise 2%.
            // 2. Depending on the round fill 0-100% get extra 15-0% (round 1 participants) or 6-0%.
            // 3. Double reward if increased balance since last round by 1%+.
            _reward = _minPercent.add(_maxBonusPercent).mul(_roundPrice).mul(ROUND_SIZE_BASE)
                .sub(_maxBonusPercent.mul(_totalDeposited)).mul(_holderBalance).mul(_x2) /
                100.mul(_roundPrice).mul(ROUND_SIZE_BASE);
        }

        uint _rewardsLeft = locks[LockType.Staking][address(this)].balance;
        // If not enough left, give everything.
        if (_rewardsLeft < _reward) {
            _reward = _rewardsLeft;
        }

        locks[LockType.Staking][_holder].balance =
            locks[LockType.Staking][_holder].balance.add(_reward).toUInt128();
        locks[LockType.Staking][address(this)].balance = _rewardsLeft.sub(_reward).toUInt128();
    }

    function depositUSDT(uint _amount) external note() {
        usdtToken.transferFrom(_msgSender(), treasury, _amount);
        uint _usdcAmount = _amount.mul(usdtPriceFeed.updateAndConsult()) / USDT;
        _deposit(_usdcAmount);
    }

    function depositETH() payable external noteDeposit() {
        _depositETH();
    }

    receive() payable external noteDeposit() {
        _depositETH();
    }

    function _depositETH() private {
        treasury.transfer(msg.value);
        uint _usdcAmount = msg.value.mul(ethPriceFeed.updateAndConsult()) / 1 ether;
        _deposit(_usdcAmount);
    }

    function depositUSDC(uint _amount) external note() {
        usdcToken.transferFrom(_msgSender(), treasury, _amount);
        _deposit(_amount);
    }

    function _deposit(uint _amount) private {
        uint _depositRound = depositRound();
        uint _newDeposited = _holderRounds[_depositRound][_msgSender()].deposited.add(_amount);
        uint _limit = _usersInfo[_msgSender()].firstRoundLimit;
        if (_depositRound == 1) {
            require(_limit > 0, 'Not whitelisted');
            require(_newDeposited <= _limit, 'Deposit limit is reached');
        }
        require(_amount >= 1 * USDC, 'Less than minimum amount 1 usdc');

        _holderRounds[_depositRound][_msgSender()].deposited = _newDeposited.toUInt120();

        rounds[_depositRound].totalDeposited = rounds[_depositRound].totalDeposited.add(_amount).toUInt120();

        if (_usersInfo[_msgSender()].firstRoundDeposited == 0) {
            _usersInfo[_msgSender()].firstRoundDeposited = _depositRound.toUInt8();
        }
    }

    // In case someone will send USDC/USDT/SomeToken directly.
    function withdrawLocked(IERC20 _token, address _receiver, uint _amount) external onlyOwner() note() {
        require(address(_token) != address(this), 'Cannot withdraw this');
        _token.transfer(_receiver, _amount);
    }

    function currentRound() public view returns(uint) {
        require(_passed(tokensaleStartDate), 'Tokensale not started yet');
        if (_passed(tokensaleEndDate)) {
            return 23;
        }

        return _since(tokensaleStartDate).divCeil(ROUND_DURATION_SEC);
    }

    // Deposit round ends 1 hour before the end of each round.
    function depositRound() public view returns(uint) {
        require(_passed(tokensaleStartDate), 'Tokensale not started yet');
        require(_notPassed(tokensaleEndDate.sub(1 hours)), 'Deposits ended');

        return _since(tokensaleStartDate).add(1 hours).divCeil(ROUND_DURATION_SEC);
    }

    function isRoundDepositsEnded(uint _round) public view returns(bool) {
        return _passed(ROUND_DURATION_SEC.mul(_round).add(tokensaleStartDate).sub(1 hours));
    }

    function isRoundPrepared(uint _round) public view returns(bool) {
        return rounds[_round].roundPrice > 0;
    }

    function currentPrice() public view returns(uint) {
        return dexePriceFeed.consult();
    }

    function updateAndGetCurrentPrice() public returns(uint) {
        return dexePriceFeed.updateAndConsult();
    }

    function _passed(uint _time) private view returns(bool) {
        return block.timestamp > _time;
    }

    function _notPassed(uint _time) private view returns(bool) {
        return _not(_passed(_time));
    }

    function _not(bool _condition) private pure returns(bool) {
        return !_condition;
    }

    // Get released tokens to the main balance.
    function releaseLock(LockType _lock) external note() {
        _release(_lock, _msgSender());
    }

    // Assign locked tokens to another holder.
    function transferLock(LockType _lockType, address _to, uint _amount) external note() {
        receiveAll();
        Lock memory _lock = locks[_lockType][_msgSender()];
        require(_lock.released == 0, 'Cannot transfer after release');
        require(_lock.balance >= _amount, 'Insuffisient locked funds');

        locks[_lockType][_msgSender()].balance = _lock.balance.sub(_amount).toUInt128();
        locks[_lockType][_to].balance = locks[_lockType][_to].balance.add(_amount).toUInt128();
    }

    function _release(LockType _lockType, address _holder) private {
        LockConfig memory _lockConfig = lockConfigs[_lockType];
        require(_passed(_lockConfig.releaseStart),
            'Releasing has no started yet');

        Lock memory _lock = locks[_lockType][_holder];
        uint _balance = _lock.balance;
        uint _released = _lock.released;

        uint _balanceToRelease =
            _balance.mul(_since(_lockConfig.releaseStart)) / _lockConfig.vesting;

        // If more than enough time already passed, release what is left.
        if (_balanceToRelease > _balance) {
            _balanceToRelease = _balance;
        }

        require(_balanceToRelease > _released, 'Insufficient unlocked');

        // Underflow cannot happen here, SafeMath usage left for code style.
        uint _amount = _balanceToRelease.sub(_released);

        locks[_lockType][_holder].released = _balanceToRelease.toUInt128();
        _transfer(address(this), _holder, _amount);
    }


    // Wrap call to updateAndGetCurrentPrice() function before froceReleaseStaking on UI to get
    // most up-to-date price.
    // In case price increased enough since average, allow holders to release Staking rewards with a fee.
    function forceReleaseStaking(ForceReleaseType _forceReleaseType) external note() {
        uint _currentRound = currentRound();
        require(_currentRound > 10, 'Only after 10 round');
        receiveAll();
        Lock memory _lock = locks[LockType.Staking][_msgSender()];
        require(_lock.balance > 0, 'Nothing to force unlock');

        uint _priceMul;
        uint _unlockedPart;
        uint _receivedPart;

        if (_forceReleaseType == ForceReleaseType.X7) {
            _priceMul = 7;
            _unlockedPart = 10;
            _receivedPart = 86;
        } else if (_forceReleaseType == ForceReleaseType.X10) {
            _priceMul = 10;
            _unlockedPart = 15;
            _receivedPart = 80;
        } else if (_forceReleaseType == ForceReleaseType.X15) {
            _priceMul = 15;
            _unlockedPart = 20;
            _receivedPart = 70;
        } else {
            _priceMul = 20;
            _unlockedPart = 30;
            _receivedPart = 60;
        }

        require(_not(forceReleased[_msgSender()][_forceReleaseType]), 'Already force released');

        forceReleased[_msgSender()][_forceReleaseType] = true;

        require(updateAndGetCurrentPrice() >= averagePrice.mul(_priceMul), 'Current price is too small');

        uint _balance = _lock.balance.sub(_lock.released);

        uint _released = _balance.mul(_unlockedPart) / 100;
        uint _receiveAmount = _released.mul(_receivedPart) / 100;
        uint _burned = _released.sub(_receiveAmount);

        locks[LockType.Staking][_msgSender()].released = _lock.released.add(_released).toUInt128();

        if (_currentRound <= TOTAL_ROUNDS) {
            _holderRounds[_currentRound][_msgSender()].endBalance =
                _holderRounds[_currentRound][_msgSender()].endBalance.add(_receiveAmount).toUInt128();
        }
        _burn(address(this), _burned);
        _transfer(address(this), _msgSender(), _receiveAmount);
    }

    function launchProduct() external onlyOwner() note() {
        require(_passed(tokensaleEndDate), 'Tokensale is not ended yet');
        require(launchedAfter == 0, 'Product already launched');
        require(isTokensaleProcessed(), 'Tokensale is not processed');

        launchedAfter = _since(tokensaleEndDate);
    }

    function isTokensaleProcessed() private view returns(bool) {
        return rounds[TOTAL_ROUNDS].roundPrice > 0;
    }

    // Zero address and Dexe itself are not considered as valid holders.
    function _isHolder(address _addr) private view returns(bool) {
        if (_addr == address(this) || _addr == address(0)) {
            return false;
        }
        return true;
    }

    // Happen before every transfer to update all the metrics.
    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal override {
        if (_isHolder(_from)) {
            // Automatically receive tokens/rewards for previous rounds.
            _receiveAll(_from);
        }

        if (_notPassed(tokensaleEndDate)) {
            uint _round = 1;
            if (_passed(tokensaleStartDate)) {
                _round = currentRound();
            }

            if (_isHolder(_from)) {
                _holderRounds[_round][_from].endBalance =
                    _holderRounds[_round][_from].endBalance.sub(_amount).toUInt128();
            }
            if (_isHolder(_to)) {
                UserInfo memory _userToInfo = _usersInfo[_to];
                if (_userToInfo.firstRoundDeposited == 0) {
                    _usersInfo[_to].firstRoundDeposited = _round.toUInt8();
                }
                if (_from != address(this)) {
                    _holderRounds[_round][_to].endBalance =
                        _holderRounds[_round][_to].endBalance.add(_amount).toUInt128();
                }
            }
        }

        if (launchedAfter == 0) {
            if (_isHolder(_from)) {
                _usersInfo[_from].balanceBeforeLaunch = _usersInfo[_from].balanceBeforeLaunch.sub(_amount).toUInt128();
            }
            if (_isHolder(_to)) {
                _usersInfo[_to].balanceBeforeLaunch = _usersInfo[_to].balanceBeforeLaunch.add(_amount).toUInt128();
                if (_balanceInfo[_to].firstBalanceChange == 0) {
                    _balanceInfo[_to].firstBalanceChange = block.timestamp.toUInt32();
                    _balanceInfo[_to].lastBalanceChange = block.timestamp.toUInt32();
                }
            }
        }
        _updateBalanceAverage(_from);
        _updateBalanceAverage(_to);
    }

    function _since(uint _timestamp) private view returns(uint) {
        return block.timestamp.sub(_timestamp);
    }

    function launchDate() public override view returns(uint) {
        uint _launchedAfter = launchedAfter;
        if (_launchedAfter == 0) {
            return 0;
        }
        return tokensaleEndDate.add(_launchedAfter);
    }

    function _calculateBalanceAverage(address _holder) private view returns(BalanceInfo memory) {
        BalanceInfo memory _user = _balanceInfo[_holder];
        if (!_isHolder(_holder)) {
            return _user;
        }

        uint _lastBalanceChange = _user.lastBalanceChange;
        uint _balance = balanceOf(_holder);
        uint _launchDate = launchDate();
        bool _notLaunched = _launchDate == 0;
        uint _accumulatorTillNow = _user.balanceAccumulator
            .add(_balance.mul(_since(_lastBalanceChange)));

        if (_notLaunched) {
            // Last update happened in the current before launch period.
            _user.balanceAccumulator = _accumulatorTillNow;
            _user.balanceAverage = (_accumulatorTillNow /
                _since(_user.firstBalanceChange)).toUInt128();
            _user.lastBalanceChange = block.timestamp.toUInt32();
            return _user;
        }

        // Calculating the end of the last average period.
        uint _timeEndpoint = _since(_launchDate).div(MONTH).mul(MONTH).add(_launchDate);
        if (_lastBalanceChange >= _timeEndpoint) {
            // Last update happened in the current average period.
            _user.balanceAccumulator = _accumulatorTillNow;
        } else {
            // Last update happened before the current average period.
            uint _sinceLastBalanceChangeToEndpoint = _timeEndpoint.sub(_lastBalanceChange);
            uint _accumulatorAtTheEndpoint = _user.balanceAccumulator
                .add(_balance.mul(_sinceLastBalanceChangeToEndpoint));

            if (_timeEndpoint == _launchDate) {
                // Last update happened before the launch period.
                _user.balanceAverage = (_accumulatorAtTheEndpoint /
                    _timeEndpoint.sub(_user.firstBalanceChange)).toUInt128();
            } else if (_sinceLastBalanceChangeToEndpoint <= MONTH) {
                // Last update happened in the previous average period.
                _user.balanceAverage = (_accumulatorAtTheEndpoint / MONTH).toUInt128();
            } else {
                // Last update happened before the previous average period.
                _user.balanceAverage = _balance.toUInt128();
            }

            _user.balanceAccumulator = _balance.mul(_since(_timeEndpoint));
        }

        _user.lastBalanceChange = block.timestamp.toUInt32();
        return _user;
    }

    function _updateBalanceAverage(address _holder) private {
        if (_balanceInfo[_holder].lastBalanceChange == block.timestamp) {
            return;
        }
        _balanceInfo[_holder] = _calculateBalanceAverage(_holder);
    }

    function getAverageBalance(address _holder) external override view returns(uint) {
        return _calculateBalanceAverage(_holder).balanceAverage;
    }

    function firstBalanceChange(address _holder) external override view returns(uint) {
        return _balanceInfo[_holder].firstBalanceChange;
    }

    function holderRounds(uint _round, address _holder) external override view returns(
        HolderRound memory
    ) {
        return _holderRounds[_round][_holder];
    }

    function usersInfo(address _holder) external override view returns(
        UserInfo memory
    ) {
        return _usersInfo[_holder];
    }
}