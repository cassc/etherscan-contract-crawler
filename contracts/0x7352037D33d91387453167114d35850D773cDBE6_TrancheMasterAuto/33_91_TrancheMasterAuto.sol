//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMasterAuto.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IStrategyToken.sol";
import "../interfaces/IFeeRewards.sol";
import "../interfaces/IWETH.sol";

contract TrancheMasterAuto is ITrancheMasterAuto, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TrancheParams {
        uint256 apy;
        uint256 fee;
        uint256 target;
        bool principalFee;
    }

    struct Tranche {
        uint256 target;
        uint256 principal;
        uint256 autoPrincipal;
        uint256 validPercent;
        uint256 apy;
        uint256 fee;
        uint256 autoValid;
        bool principalFee;
    }

    struct TrancheSnapshot {
        uint256 target;
        uint256 principal;
        uint256 capital;
        uint256 validPercent;
        uint256 rate;
        uint256 apy;
        uint256 fee;
        uint256 startAt;
        uint256 stopAt;
    }

    struct Investment {
        uint256 cycle;
        uint256 principal;
        bool rebalanced;
    }

    struct UserInfo {
        uint256 balance;
        bool isAuto;
    }

    uint256 public constant PercentageParamScale = 1e5;
    uint256 public constant PercentageScale = 1e18;
    uint256 private constant MaxAPY = 100000;
    uint256 private constant MaxFee = 50000;

    uint256 public override producedFee;
    uint256 public override duration = 7 days;
    uint256 public override cycle;
    uint256 public override actualStartAt;
    bool public override active;
    Tranche[] public override tranches;
    address public immutable wNative;
    address public override currency;
    address public override staker;
    address public override strategy;

    address public override devAddress;

    mapping(address => UserInfo) public override userInfo;
    mapping(address => mapping(uint256 => Investment)) public override userInvest;

    // cycle => trancheID => snapshot
    mapping(uint256 => mapping(uint256 => TrancheSnapshot)) public override trancheSnapshots;

    event Deposit(address account, uint256 amount);

    event Invest(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Redeem(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Withdraw(address account, uint256 amount);

    event WithdrawFee(address account, uint256 amount);

    event Harvest(address account, uint256 tid, uint256 cycle, uint256 principal, uint256 capital);

    event TrancheAdd(uint256 tid, uint256 target, uint256 apy, uint256 fee, bool principalFee);

    event TrancheUpdated(uint256 tid, uint256 target, uint256 apy, uint256 fee, bool principalFee);

    event TrancheStart(uint256 tid, uint256 cycle, uint256 principal);

    event TrancheSettle(uint256 tid, uint256 cycle, uint256 principal, uint256 capital, uint256 rate);

    event SetDevAddress(address dev);

    modifier checkTranches() {
        require(tranches.length > 1, "tranches is incomplete");
        require(tranches[tranches.length - 1].apy == 0, "the last tranche must carry zero apy");
        _;
    }

    modifier checkTrancheID(uint256 tid) {
        require(tid < tranches.length, "invalid tranche id");
        _;
    }

    modifier checkActive() {
        require(active, "not active");
        _;
    }

    modifier checkNotActive() {
        require(!active, "already active");
        _;
    }

    modifier checkNotAuto() {
        require(!userInfo[msg.sender].isAuto, "user autorolling");
        _;
    }

    modifier updateInvest() {
        _updateInvest(_msgSender());
        _;
    }

    modifier transferTokenToVault(uint256 value) {
        if (msg.value != 0) {
            require(currency == wNative, "currency is not wNative");
            require(value == msg.value, "value != msg.value");
            IWETH(currency).deposit{ value: msg.value }();
        } else {
            IERC20(currency).safeTransferFrom(msg.sender, address(this), value);
        }
        _;
    }

    constructor(
        address _core,
        address _wNative,
        address _currency,
        address _strategy,
        address _staker,
        address _devAddress,
        uint256 _duration,
        TrancheParams[] memory _params
    ) public CoreRef(_core) {
        wNative = _wNative;
        currency = _currency;
        strategy = _strategy;
        staker = _staker;
        devAddress = _devAddress;
        duration = _duration;

        approveToken();

        for (uint256 i = 0; i < _params.length; i++) {
            _add(_params[i].target, _params[i].apy, _params[i].fee, _params[i].principalFee);
        }
    }

    function approveToken() public {
        IERC20(currency).safeApprove(strategy, uint256(-1));
    }

    function setDuration(uint256 _duration) public override onlyGovernor {
        duration = _duration;
    }

    function setDevAddress(address _devAddress) public override onlyGovernor {
        devAddress = _devAddress;
        emit SetDevAddress(_devAddress);
    }

    function _add(
        uint256 target,
        uint256 apy,
        uint256 fee,
        bool principalFee
    ) internal {
        require(target > 0, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches.push(
            Tranche({
                target: target,
                apy: apy.mul(PercentageScale).div(PercentageParamScale),
                fee: fee,
                principal: 0,
                autoPrincipal: 0,
                validPercent: 0,
                autoValid: 0,
                principalFee: principalFee
            })
        );
        emit TrancheAdd(tranches.length - 1, target, apy, fee, principalFee);
    }

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee,
        bool principalFee
    ) public override onlyGovernor {
        _add(target, apy, fee, principalFee);
    }

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee,
        bool principalFee
    ) public override onlyTimelock checkTrancheID(tid) {
        require(target >= tranches[tid].principal, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches[tid].target = target;
        tranches[tid].apy = apy.mul(PercentageScale).div(PercentageParamScale);
        tranches[tid].fee = fee;
        tranches[tid].principalFee = principalFee;
        emit TrancheUpdated(tid, target, apy, fee, principalFee);
    }

    function _updateInvest(address account) internal {
        UserInfo storage u = userInfo[account];
        uint256 valid;
        uint256 principal;
        uint256 total;
        uint256 capital;
        uint256 left;
        for (uint i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            principal = inv.principal;
            if (principal == 0) {
                inv.cycle = cycle;
                continue;
            }
            if (u.isAuto) {
                for (uint j = inv.cycle; j < cycle; j++) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[j][i];
                    if (inv.rebalanced) {
                        valid = principal;
                        inv.rebalanced = false;
                        left = 0;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    total = left.add(capital);
                    emit Harvest(account, i, j, valid, capital);
                    principal = total;
                }
                if (active && !inv.rebalanced) {
                    valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                    left = principal
                        .mul(PercentageScale.sub(tranches[i].validPercent))
                        .div(PercentageScale);
                    if (left > 0) {
                        left -= 1;
                    }
                    inv.rebalanced = true;
                    inv.principal = valid;
                    u.balance = u.balance.add(left);
                    tranches[i].autoPrincipal = tranches[i].autoPrincipal.sub(left);
                } else {
                    inv.principal = principal;
                }
                IMasterWTF(staker).updateStake(i, account, inv.principal);
            } else {
                if (inv.cycle < cycle) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    if (inv.rebalanced) {
                        valid = principal;
                        left = 0;
                        inv.rebalanced = false;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    total = left.add(capital);
                    u.balance = u.balance.add(total);
                    inv.principal = 0;
                    IMasterWTF(staker).updateStake(i, account, 0);
                    emit Harvest(account, i, inv.cycle, valid, capital);
                } else if (active && !inv.rebalanced) {
                    valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                    left = principal
                        .mul(PercentageScale.sub(tranches[i].validPercent))
                        .div(PercentageScale);
                    if (left > 0) {
                        left -= 1;
                    }
                    inv.rebalanced = true;
                    inv.principal = valid;
                    u.balance = u.balance.add(left);
                    tranches[i].principal = tranches[i].principal.sub(left);
                    IMasterWTF(staker).updateStake(i, account, inv.principal);
                }
            }
            inv.cycle = cycle;
        }
    }

    function balanceOf(address account) public view override returns (uint256 balance, uint256 invested) {
        UserInfo memory u = userInfo[account];
        uint256 principal;
        uint256 valid;
        uint256 total;
        uint256 capital;
        uint256 left;
        bool rebalanced;

        balance = u.balance;
        for (uint i = 0; i < tranches.length; i++) {
            Investment memory inv = userInvest[account][i];
            rebalanced = inv.rebalanced;
            principal = inv.principal;
            if (principal == 0) {
                continue;
            }
            if (u.isAuto) {
                for (uint j = inv.cycle; j < cycle; j++) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[j][i];
                    if (rebalanced) {
                        valid = principal;
                        rebalanced = false;
                        left = 0;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    principal = left.add(capital);
                }
                if (active && !rebalanced) {
                    valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                    left = principal
                        .mul(PercentageScale.sub(tranches[i].validPercent))
                        .div(PercentageScale);
                    if (left > 0) {
                        left -= 1;
                    }
                    invested = invested.add(valid);
                    balance = balance.add(left);
                } else {
                    invested = invested.add(principal);
                }
            } else {
                if (inv.cycle < cycle) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    if (inv.rebalanced) {
                        valid = principal;
                        rebalanced = false;
                        left = 0;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    total = left.add(capital);
                    balance = balance.add(total);
                } else {
                    if (active && !rebalanced) {
                        valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(tranches[i].validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                        invested = invested.add(valid);
                        balance = balance.add(left);
                    } else {
                        invested = invested.add(principal);
                    }
                }
            }
        }
    }

    function switchAuto(bool _auto) public override updateInvest nonReentrant {
        if (_auto) {
            require(active == false, "cannot switch ON autoroll while the fall is active");
        }
        UserInfo storage u = userInfo[msg.sender];
        if (u.isAuto == _auto) {
            return;
        }

        for (uint i = 0; i < tranches.length; i++) {
            Investment memory inv = userInvest[msg.sender][i];
            if (inv.principal == 0) {
                continue;
            }

            Tranche storage t = tranches[i];
            if (_auto) {
                t.principal = t.principal.sub(inv.principal);
                t.autoPrincipal = t.autoPrincipal.add(inv.principal);
            } else {
                t.principal = t.principal.add(inv.principal);
                t.autoPrincipal = t.autoPrincipal.sub(inv.principal);
                if (active) {
                    t.autoValid = t.autoValid > inv.principal ? t.autoValid.sub(inv.principal) : 0;
                }
            }
        }

        u.isAuto = _auto;
    }

    function _tryStart() internal returns (bool) {
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            if (t.principal.add(t.autoPrincipal) < t.target) {
                return false;
            }
        }

        _startCycle();

        return true;
    }

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    )
        public
        override
        payable
        checkTrancheID(tid)
        checkNotActive
        updateInvest
        nonReentrant
        transferTokenToVault(amountIn)
    {
        require(amountIn > 0, "invalid amountIn");
        require(amountInvest > 0, "invalid amountInvest");

        UserInfo storage u = userInfo[msg.sender];
        require(u.balance.add(amountIn) >= amountInvest, "balance not enough");

        u.balance = u.balance.add(amountIn);
        emit Deposit(msg.sender, amountIn);

        _invest(tid, amountInvest, false);
    }

    function deposit(uint256 amount)
        public
        override
        payable
        updateInvest
        nonReentrant
        transferTokenToVault(amount)
    {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        u.balance = u.balance.add(amount);
        emit Deposit(msg.sender, amount);
    }

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        _invest(tid, amount, returnLeft);
    }

    function _invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) private {
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");

        Tranche storage t = tranches[tid];
        require(t.target >= t.principal.add(t.autoPrincipal).add(amount), "not enough quota");
        Investment storage inv = userInvest[msg.sender][tid];
        inv.principal = inv.principal.add(amount);
        u.balance = u.balance.sub(amount);
        if (u.isAuto) {
            t.autoPrincipal = t.autoPrincipal.add(amount);
        } else {
            t.principal = t.principal.add(amount);
        }

        IMasterWTF(staker).updateStake(tid, msg.sender, inv.principal);

        emit Invest(msg.sender, tid, cycle, amount);

        if (returnLeft && u.balance > 0) {
            _safeUnwrap(msg.sender, u.balance);
            emit Withdraw(msg.sender, u.balance);
            u.balance = 0;
        }

        _tryStart();
    }

    function redeem(uint256 tid)
        public
        override
        checkTrancheID(tid)
        checkNotActive
        checkNotAuto
        updateInvest
        nonReentrant
    {
        _redeem(tid);
    }

    function _redeem(uint256 tid) private returns (uint256) {
        UserInfo storage u = userInfo[msg.sender];
        Investment storage inv = userInvest[msg.sender][tid];
        uint256 principal = inv.principal;
        require(principal > 0, "not enough principal");

        Tranche storage t = tranches[tid];
        u.balance = u.balance.add(principal);
        t.principal = t.principal.sub(principal);

        IMasterWTF(staker).updateStake(tid, msg.sender, 0);
        inv.principal = 0;
        emit Redeem(msg.sender, tid, cycle, principal);
        return principal;
    }

    function redeemDirect(uint256 tid)
        public
        override
        checkTrancheID(tid)
        checkNotActive
        checkNotAuto
        updateInvest
        nonReentrant
    {
        uint256 amount = _redeem(tid);
        UserInfo storage u = userInfo[msg.sender];
        u.balance = u.balance.sub(amount);
        _safeUnwrap(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateInvest nonReentrant {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");
        u.balance = u.balance.sub(amount);
        _safeUnwrap(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function _startCycle() internal checkNotActive {
        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            total = total.add(t.target);
        }

        IStrategyToken(strategy).deposit(total);
        actualStartAt = block.timestamp;
        active = true;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche storage t = tranches[i];
            t.validPercent = t.target.mul(PercentageScale).div(t.principal.add(t.autoPrincipal));
            t.autoValid = t.principal == 0 ? t.target : t.autoPrincipal.mul(t.validPercent).div(PercentageScale);
            emit TrancheStart(i, cycle, t.target);
        }
        IMasterWTF(staker).start(block.number.add(duration.div(3)));
    }

    function _stopCycle() internal {
        require(block.timestamp >= actualStartAt + duration, "cycle not expired");
        _processExit();
        active = false;
        cycle++;
        IMasterWTF(staker).next(cycle);
    }

    function _calculateExchangeRate(uint256 current, uint256 base) internal pure returns (uint256) {
        if (current == base) {
            return PercentageScale;
        } else if (current > base) {
            return PercentageScale.add((current - base).mul(PercentageScale).div(base));
        } else {
            return PercentageScale.sub((base - current).mul(PercentageScale).div(base));
        }
    }

    function _processExit() internal {
        uint256 before = IERC20(currency).balanceOf(address(this));
        IStrategyToken(strategy).withdraw();

        uint256 total = IERC20(currency).balanceOf(address(this)).sub(before);
        uint256 restCapital = total;
        uint256 interestShouldBe;
        uint256 cycleExchangeRate;
        uint256 capital;
        uint256 principal;
        uint256 _now = block.timestamp;

        for (uint256 i = 0; i < tranches.length - 1; i++) {
            Tranche storage senior = tranches[i];
            principal = senior.target;
            capital = 0;
            interestShouldBe = principal
                .mul(senior.apy)
                .mul(_now - actualStartAt)
                .div(365)
                .div(86400)
                .div(PercentageScale);

            uint256 all = principal.add(interestShouldBe);
            bool satisfied = restCapital >= all;
            if (!satisfied) {
                capital = restCapital;
                restCapital = 0;
            } else {
                capital = all;
                restCapital = restCapital.sub(all);
            }

            uint256 fee;
            if (senior.principalFee) {
                fee = satisfied ? capital.mul(senior.fee).div(PercentageParamScale) : 0;
            } else if (capital > principal) {
                fee = capital.sub(principal).mul(senior.fee).div(PercentageParamScale);
            }
            if (fee > 0) {
                producedFee = producedFee.add(fee);
                capital = capital.sub(fee);
            }

            cycleExchangeRate = _calculateExchangeRate(capital, principal);
            trancheSnapshots[cycle][i] = TrancheSnapshot({
                target: senior.target,
                principal: principal,
                capital: capital,
                validPercent: senior.validPercent,
                rate: cycleExchangeRate,
                apy: senior.apy,
                fee: senior.fee,
                startAt: actualStartAt,
                stopAt: _now
            });

            senior.principal = 0;

            senior.autoPrincipal = senior.autoValid
                .mul(cycleExchangeRate)
                .div(PercentageScale)
                .add(senior.autoPrincipal > senior.autoValid ? senior.autoPrincipal.sub(senior.autoValid) : 0);

            emit TrancheSettle(i, cycle, principal, capital, cycleExchangeRate);
        }

        {
            uint256 juniorIndex = tranches.length - 1;
            Tranche storage junior = tranches[juniorIndex];
            principal = junior.target;
            capital = restCapital;
            uint256 fee;
            if (junior.principalFee) {
                fee = capital.mul(junior.fee).div(PercentageParamScale);
            } else if (capital > principal) {
                fee = capital.sub(principal).mul(junior.fee).div(PercentageParamScale);
            }
            if (fee > 0) {
                producedFee = producedFee.add(fee);
                capital = capital.sub(fee);
            }
            cycleExchangeRate = _calculateExchangeRate(capital, principal);
            trancheSnapshots[cycle][juniorIndex] = TrancheSnapshot({
                target: junior.target,
                principal: principal,
                capital: capital,
                validPercent: junior.validPercent,
                rate: cycleExchangeRate,
                apy: junior.apy,
                fee: junior.fee,
                startAt: actualStartAt,
                stopAt: now
            });

            junior.principal = 0;
            junior.autoPrincipal = junior.autoValid
                .mul(cycleExchangeRate)
                .div(PercentageScale)
                .add(junior.autoPrincipal > junior.autoValid ? junior.autoPrincipal.sub(junior.autoValid) : 0);

            emit TrancheSettle(juniorIndex, cycle, principal, capital, cycleExchangeRate);
        }
    }

    function stop() public override checkActive nonReentrant {
        _stopCycle();
        _tryStart();
    }

    function setStaker(address _staker) public override onlyGovernor {
        staker = _staker;
    }

    function setStrategy(address _strategy) public override onlyGovernor {
        strategy = _strategy;
    }

    function withdrawFee(uint256 amount) public override {
        require(amount <= producedFee, "not enough balance for fee");
        producedFee = producedFee.sub(amount);
        if (devAddress != address(0)) {
            _safeUnwrap(devAddress, amount);
            emit WithdrawFee(devAddress, amount);
        }
    }

    function transferFeeToStaking(uint256 _amount, address _pool) public override onlyGovernor {
        require(_amount > 0, "Zero amount");
        IERC20(currency).safeApprove(_pool, _amount);
        IFeeRewards(_pool).sendRewards(_amount);
    }

    function _safeUnwrap(address to, uint256 amount) internal {
        if (currency == wNative) {
            IWETH(currency).withdraw(amount);
            Address.sendValue(payable(to), amount);
        } else {
            IERC20(currency).safeTransfer(to, amount);
        }
    }

    receive() external payable {}
}