//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMasterMultiTokenManual.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/AlpacaPancakeFarm/IStrategyToken.sol";
import "../interfaces/IFeeRewards.sol";

contract TrancheMasterMultiTokenManual is ITrancheMasterMultiTokenManual, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TrancheParams {
        uint256 apy;
        uint256 fee;
        uint256 target;
    }

    struct Tranche {
        uint256 target;
        uint256 principal;
        uint256 apy;
        uint256 fee;
    }

    struct Token {
        address addr;
        address strategy;
        uint256 percent;
    }

    struct TrancheSnapshot {
        uint256 target;
        uint256 principal;
        uint256 rate;
        uint256 apy;
        uint256 fee;
        uint256 startAt;
        uint256 stopAt;
    }

    struct TokenSettle {
        uint256 capital;
        uint256 reward;
        uint256 profit;
        uint256 left;
        bool gain;
    }

    uint256 public constant PercentageParamScale = 1e5;
    uint256 public constant PercentageScale = 1e18;
    uint256 private constant MaxAPY = 100000;
    uint256 private constant MaxFee = 10000;

    mapping(address => uint256) public override producedFee;
    uint256 public override duration = 7 days;
    uint256 public override cycle;
    uint256 public override actualStartAt;
    bool public override active;
    Tranche[] public override tranches;
    address public override staker;

    address public override devAddress;
    Token[] public tokens;
    uint256 public tokenCount;

    // user => token => balance
    mapping(address => mapping(address => uint256)) public userBalances;

    // user => cycle
    mapping(address => uint256) public userCycle;

    // user => trancheID => token => amount
    mapping(address => mapping(uint256 => mapping(address => uint256))) public override userInvest;

    // cycle => trancheID => token => amount
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public override trancheInvest;

    // cycle => trancheID => snapshot
    mapping(uint256 => mapping(uint256 => TrancheSnapshot)) public override trancheSnapshots;

    // cycle => token => TokenSettle
    mapping(uint256 => mapping(address => TokenSettle)) public tokenSettles;

    event Deposit(address account, address token, uint256 amount);

    event Invest(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Redeem(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Withdraw(address account, address token, uint256 amount);

    event WithdrawFee(address account, address token, uint256 amount);

    event Harvest(address account, uint256 tid, uint256 cycle, uint256 principal, uint256 capital);

    event TrancheAdd(uint256 tid, uint256 target, uint256 apy, uint256 fee);

    event TrancheUpdated(uint256 tid, uint256 target, uint256 apy, uint256 fee);

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

    modifier updateInvest() {
        _updateInvest(_msgSender());
        _;
    }

    constructor(
        address _core,
        address _staker,
        address _devAddress,
        uint256 _duration,
        TrancheParams[] memory _params,
        Token[] memory _tokens
    ) public CoreRef(_core) {
        staker = _staker;
        devAddress = _devAddress;
        duration = _duration;

        for (uint256 i = 0; i < _params.length; i++) {
            _add(_params[i].target, _params[i].apy, _params[i].fee);
        }

        tokenCount = _tokens.length;
        uint256 total = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            total = total.add(_tokens[i].percent);
            tokens.push(Token({addr: _tokens[i].addr, strategy: _tokens[i].strategy, percent: _tokens[i].percent}));
        }
        require(total == PercentageParamScale, "invalid token percent");

        approveToken();
    }

    function approveToken() public {
        for (uint256 i = 0; i < tokenCount; i++) {
            IERC20(tokens[i].addr).safeApprove(tokens[i].strategy, uint256(-1));
        }
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
        uint256 fee
    ) internal {
        require(target > 0, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches.push(
            Tranche({target: target, apy: apy.mul(PercentageScale).div(PercentageParamScale), fee: fee, principal: 0})
        );
        emit TrancheAdd(tranches.length - 1, target, apy, fee);
    }

    function add(
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyGovernor {
        _add(target, apy, fee);
    }

    function set(
        uint256 tid,
        uint256 target,
        uint256 apy,
        uint256 fee
    ) public override onlyTimelock checkTrancheID(tid) {
        require(target >= tranches[tid].principal, "invalid target");
        require(apy <= MaxAPY, "invalid APY");
        require(fee <= MaxFee, "invalid fee");
        tranches[tid].target = target;
        tranches[tid].apy = apy.mul(PercentageScale).div(PercentageParamScale);
        tranches[tid].fee = fee;
        emit TrancheUpdated(tid, target, apy, fee);
    }

    struct UpdateInvestVals {
        uint256 sum;
        uint256 capital;
        uint256 principal;
        uint256 total;
        uint256 left;
        uint256 amt;
        uint256 aj;
        uint256[] amounts;
        TokenSettle settle1;
        TokenSettle settle2;
        TrancheSnapshot snapshot;
    }

    function _updateInvest(address account) internal {
        uint256 _cycle = userCycle[account];
        if (_cycle == cycle) {
            return;
        }

        UpdateInvestVals memory v;
        v.sum = 0;
        v.amounts = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            v.settle1 = tokenSettles[_cycle][tokens[i].addr];
            if (v.settle1.gain) {
                v.sum = v.sum.add(v.settle1.profit);
            }
        }

        for (uint256 i = 0; i < tranches.length; i++) {
            v.snapshot = trancheSnapshots[_cycle][i];
            v.capital = 0;
            v.principal = 0;
            for (uint256 j = 0; j < tokenCount; j++) {
                v.amt = userInvest[account][i][tokens[j].addr];
                if (v.amt == 0) {
                    continue;
                }

                v.principal = v.principal.add(v.amt);

                v.settle1 = tokenSettles[_cycle][tokens[j].addr];
                v.total = v.amt.mul(v.snapshot.rate).div(PercentageScale);
                v.left = v.total >= v.amt ? v.total.sub(v.amt) : 0;

                v.capital = v.capital.add(v.total);
                if (v.settle1.gain || 0 == v.left) {
                    v.amounts[j] = v.amounts[j].add(v.total);
                } else {
                    v.amounts[j] = v.amounts[j].add(v.amt);

                    v.aj = v.left.mul(v.settle1.reward).div(v.settle1.reward.add(v.settle1.profit));
                    v.amounts[j] = v.amounts[j].add(v.aj);
                    v.aj = v.left.mul(v.settle1.profit).div(v.settle1.reward.add(v.settle1.profit));
                    for (uint256 k = 0; k < tokenCount; k++) {
                        if (j == k) {
                            continue;
                        }
                        v.settle2 = tokenSettles[_cycle][tokens[k].addr];
                        if (v.settle2.gain) {
                            v.amounts[k] = v.amounts[k].add(v.aj.mul(v.settle2.profit).div(v.sum));
                        }
                    }
                }

                userInvest[account][i][tokens[j].addr] = 0;
            }

            if (v.principal > 0) {
                IMasterWTF(staker).updateStake(i, account, 0);
                emit Harvest(account, i, _cycle, v.principal, v.capital);
            }
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            if (v.amounts[i] > 0) {
                userBalances[account][tokens[i].addr] = v.amounts[i].add(userBalances[account][tokens[i].addr]);
            }
        }

        userCycle[account] = cycle;
    }

    function balanceOf(address account) public view override returns (uint256[] memory, uint256[] memory) {
        uint256[] memory balances = new uint256[](tokenCount);
        uint256[] memory invests = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            balances[i] = balances[i].add(userBalances[account][tokens[i].addr]);
        }

        UpdateInvestVals memory v;
        uint256 _cycle = userCycle[account];
        if (_cycle == cycle) {
            for (uint256 i = 0; i < tokenCount; i++) {
                v.principal = 0;
                for (uint256 j = 0; j < tranches.length; j++) {
                    uint256 amt = userInvest[account][j][tokens[i].addr];
                    if (amt > 0) {
                        v.principal = v.principal.add(amt);
                    }
                }
                if (v.principal > 0) {
                    invests[i] = invests[i].add(v.principal);
                }
            }
            return (balances, invests);
        }

        v.sum = 0;
        v.amounts = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            v.settle1 = tokenSettles[_cycle][tokens[i].addr];
            if (v.settle1.gain) {
                v.sum = v.sum.add(v.settle1.profit);
            }
        }

        for (uint256 i = 0; i < tranches.length; i++) {
            v.snapshot = trancheSnapshots[_cycle][i];
            v.capital = 0;
            v.principal = 0;
            for (uint256 j = 0; j < tokenCount; j++) {
                v.amt = userInvest[account][i][tokens[j].addr];
                if (v.amt == 0) {
                    continue;
                }

                v.principal = v.principal.add(v.amt);

                v.settle1 = tokenSettles[_cycle][tokens[j].addr];
                v.total = v.amt.mul(v.snapshot.rate).div(PercentageScale);
                v.left = v.total >= v.amt ? v.total.sub(v.amt) : 0;

                v.capital = v.capital.add(v.total);
                if (v.settle1.gain || 0 == v.left) {
                    v.amounts[j] = v.amounts[j].add(v.total);
                } else {
                    v.amounts[j] = v.amounts[j].add(v.amt);

                    v.aj = v.left.mul(v.settle1.reward).div(v.settle1.reward.add(v.settle1.profit));
                    v.amounts[j] = v.amounts[j].add(v.aj);
                    v.aj = v.left.mul(v.settle1.profit).div(v.settle1.reward.add(v.settle1.profit));
                    for (uint256 k = 0; k < tokenCount; k++) {
                        if (j == k) {
                            continue;
                        }
                        v.settle2 = tokenSettles[_cycle][tokens[k].addr];
                        if (v.settle2.gain) {
                            v.amounts[k] = v.amounts[k].add(v.aj.mul(v.settle2.profit).div(v.sum));
                        }
                    }
                }
            }
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            if (v.amounts[i] > 0) {
                balances[i] = v.amounts[i].add(balances[i]);
            }
        }

        return (balances, invests);
    }

    function start(uint256[][] memory minLPAmounts) external override onlyGovernor returns (bool) {
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            if (t.principal < t.target) {
                return false;
            }
        }
        _startCycle(minLPAmounts);
        return true;
    }

    function _sumBalance(address account) private returns (uint256 ret) {
        for (uint256 i = 0; i < tokenCount; i++) {
            ret = ret.add(userBalances[account][tokens[i].addr]);
        }
    }

    function investDirect(
        uint256 tid,
        uint256[] calldata amountsIn,
        uint256[] calldata amountsInvest
    ) external override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amountsIn.length == tokenCount, "invalid amountsIn");
        require(amountsInvest.length == tokenCount, "invalid amountsInvest");

        for (uint256 i = 0; i < tokenCount; i++) {
            IERC20(tokens[i].addr).safeTransferFrom(msg.sender, address(this), amountsIn[i]);
            userBalances[msg.sender][tokens[i].addr] = amountsIn[i].add(userBalances[msg.sender][tokens[i].addr]);
            emit Deposit(msg.sender, tokens[i].addr, amountsIn[i]);
        }

        _invest(tid, amountsInvest, false);
    }

    function deposit(uint256[] calldata amountsIn) external override updateInvest nonReentrant {
        require(amountsIn.length == tokenCount, "invalid amountsIn");
        for (uint256 i = 0; i < tokenCount; i++) {
            IERC20(tokens[i].addr).safeTransferFrom(msg.sender, address(this), amountsIn[i]);
            userBalances[msg.sender][tokens[i].addr] = amountsIn[i].add(userBalances[msg.sender][tokens[i].addr]);
            emit Deposit(msg.sender, tokens[i].addr, amountsIn[i]);
        }
    }

    function invest(
        uint256 tid,
        uint256[] calldata amountsIn,
        bool returnLeft
    ) external override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        require(amountsIn.length == tokenCount, "invalid amountsIn");
        _invest(tid, amountsIn, returnLeft);
    }

    function _invest(
        uint256 tid,
        uint256[] calldata amountsIn,
        bool returnLeft
    ) internal {
        Tranche storage t = tranches[tid];

        uint256 total = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            total = amountsIn[i].add(total);
        }

        require(t.target >= t.principal.add(total), "not enough quota");

        uint256 totalTarget = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            totalTarget = totalTarget.add(tranches[i].target);
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 target = totalTarget.mul(tokens[i].percent).div(PercentageParamScale);
            uint256 amt = amountsIn[i];
            if (amt == 0) {
                continue;
            }
            uint256 already = 0;
            for (uint256 j = 0; j < tranches.length; j++) {
                already = already.add(trancheInvest[cycle][j][tokens[i].addr]);
            }
            require(amt.add(already) <= target);
            userBalances[msg.sender][tokens[i].addr] = userBalances[msg.sender][tokens[i].addr].sub(amt);
            trancheInvest[cycle][tid][tokens[i].addr] = trancheInvest[cycle][tid][tokens[i].addr].add(amt);
            userInvest[msg.sender][tid][tokens[i].addr] = userInvest[msg.sender][tid][tokens[i].addr].add(amt);
        }

        emit Invest(msg.sender, tid, cycle, total);

        t.principal = t.principal.add(total);

        uint256 principal = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            principal = principal.add(userInvest[msg.sender][tid][tokens[i].addr]);
        }
        IMasterWTF(staker).updateStake(tid, msg.sender, principal);

        if (returnLeft) {
            for (uint256 i = 0; i < tokenCount; i++) {
                uint256 b = userBalances[msg.sender][tokens[i].addr];
                if (b > 0) {
                    IERC20(tokens[i].addr).safeTransfer(msg.sender, b);
                    userBalances[msg.sender][tokens[i].addr] = 0;
                    emit Withdraw(msg.sender, tokens[i].addr, b);
                }
            }
        }
    }

    function redeem(uint256 tid) public override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        _redeem(tid);
    }

    function _redeem(uint256 tid) private returns (uint256[] memory) {
        uint256 total = 0;
        uint256[] memory amountOuts = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 amt = userInvest[msg.sender][tid][tokens[i].addr];
            if (amt == 0) {
                continue;
            }

            userBalances[msg.sender][tokens[i].addr] = userBalances[msg.sender][tokens[i].addr].add(amt);
            trancheInvest[cycle][tid][tokens[i].addr] = trancheInvest[cycle][tid][tokens[i].addr].sub(amt);
            userInvest[msg.sender][tid][tokens[i].addr] = 0;

            total = total.add(amt);
            amountOuts[i] = amt;
        }

        emit Redeem(msg.sender, tid, cycle, total);

        Tranche storage t = tranches[tid];
        t.principal = t.principal.sub(total);

        IMasterWTF(staker).updateStake(tid, msg.sender, 0);

        return amountOuts;
    }

    function redeemDirect(uint256 tid) external override checkTrancheID(tid) checkNotActive updateInvest nonReentrant {
        uint256[] memory amountOuts = _redeem(tid);
        _withdraw(amountOuts);
    }

    function _withdraw(uint256[] memory amountOuts) internal {
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 amt = amountOuts[i];
            if (amt > 0) {
                userBalances[msg.sender][tokens[i].addr] = userBalances[msg.sender][tokens[i].addr].sub(amt);
                IERC20(tokens[i].addr).safeTransfer(msg.sender, amt);
                emit Withdraw(msg.sender, tokens[i].addr, amt);
            }
        }
    }

    function withdraw(uint256[] memory amountOuts) public override updateInvest nonReentrant {
        _withdraw(amountOuts);
    }

    function _startCycle(uint256[][] memory minLPAmounts) internal checkNotActive {
        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            total = total.add(t.principal);
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amt = total.mul(tokens[i].percent).div(PercentageParamScale);
            IStrategyToken(tokens[i].strategy).deposit(amt, minLPAmounts[i]);
        }

        actualStartAt = block.timestamp;
        active = true;
        for (uint256 i = 0; i < tranches.length; i++) {
            emit TrancheStart(i, cycle, tranches[i].principal);
        }
        IMasterWTF(staker).start(block.number.add(duration.div(3)));
    }

    function _stopCycle(uint256[][] memory minBaseAmounts) internal {
        require(block.timestamp >= actualStartAt + duration, "cycle not expired");
        _processExit(minBaseAmounts);
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

    function _getTotalTarget() internal returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            total = total.add(tranches[i].target);
        }
        return total;
    }

    function _redeemAll(uint256[][] memory minBaseAmounts) internal returns (uint256[] memory, uint256) {
        uint256 total = 0;
        uint256 before;
        uint256[] memory capitals = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            Token memory token = tokens[i];
            before = IERC20(token.addr).balanceOf(address(this));
            IStrategyToken(token.strategy).withdraw(minBaseAmounts[i]);
            capitals[i] = IERC20(token.addr).balanceOf(address(this)).sub(before);
            total = total.add(capitals[i]);
        }
        return (capitals, total);
    }

    struct ExitVals {
        uint256 totalTarget;
        uint256[] capitals;
        uint256 restCapital;
        uint256 interest;
        uint256 rate;
        uint256 capital;
        uint256 principal;
        uint256 now;
        uint256 totalFee;
        uint256 all;
        bool satisfied;
        Token token;
    }

    function _processExit(uint256[][] memory minBaseAmounts) internal {
        ExitVals memory v;

        v.now = block.timestamp;
        v.totalTarget = _getTotalTarget();
        (v.capitals, v.restCapital) = _redeemAll(minBaseAmounts);

        for (uint256 i = 0; i < tranches.length - 1; i++) {
            Tranche storage senior = tranches[i];
            v.principal = senior.principal;
            v.capital = 0;
            v.interest = senior.principal.mul(senior.apy).mul(v.now - actualStartAt).div(365).div(86400).div(
                PercentageScale
            );

            v.all = v.principal.add(v.interest);
            v.satisfied = v.restCapital >= v.all;
            if (!v.satisfied) {
                v.capital = v.restCapital;
                v.restCapital = 0;
            } else {
                v.capital = v.all;
                v.restCapital = v.restCapital.sub(v.all);
            }

            if (v.satisfied) {
                uint256 fee = v.capital.mul(senior.fee).div(PercentageParamScale);
                v.totalFee = v.totalFee.add(fee);
                v.capital = v.capital.sub(fee);
            }

            v.rate = _calculateExchangeRate(v.capital, v.principal);
            trancheSnapshots[cycle][i] = TrancheSnapshot({
                target: senior.target,
                principal: v.principal,
                rate: v.rate,
                apy: senior.apy,
                fee: senior.fee,
                startAt: actualStartAt,
                stopAt: v.now
            });

            senior.principal = 0;

            emit TrancheSettle(i, cycle, v.principal, v.capital, v.rate);
        }

        {
            uint256 juniorIndex = tranches.length - 1;
            Tranche storage junior = tranches[juniorIndex];
            v.principal = junior.principal;
            v.capital = v.restCapital;
            uint256 fee = v.capital.mul(junior.fee).div(PercentageParamScale);
            v.totalFee = v.totalFee.add(fee);
            v.capital = v.capital.sub(fee);
            v.rate = _calculateExchangeRate(v.capital, v.principal);
            trancheSnapshots[cycle][juniorIndex] = TrancheSnapshot({
                target: junior.target,
                principal: v.principal,
                rate: v.rate,
                apy: junior.apy,
                fee: junior.fee,
                startAt: actualStartAt,
                stopAt: v.now
            });

            junior.principal = 0;

            emit TrancheSettle(juniorIndex, cycle, v.principal, v.capital, v.rate);
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            v.token = tokens[i];
            uint256 target = v.totalTarget.mul(v.token.percent).div(PercentageParamScale);
            uint256 fee = v.totalFee.mul(v.token.percent).div(PercentageParamScale);
            v.capital = v.capitals[i];
            if (v.capital >= fee) {
                v.capital = v.capital.sub(fee);
                producedFee[v.token.addr] = producedFee[v.token.addr].add(fee);
            }

            uint256 reward = v.capital > target ? v.capital.sub(target) : 0;
            uint256 pay = 0;
            v.principal = 0;
            for (uint256 j = 0; j < tranches.length; j++) {
                uint256 p = trancheInvest[cycle][j][v.token.addr];
                pay = pay.add(p.mul(trancheSnapshots[cycle][j].rate).div(PercentageScale));
            }

            tokenSettles[cycle][v.token.addr] = TokenSettle({
                capital: v.capital,
                reward: reward,
                profit: v.capital >= pay ? v.capital.sub(pay) : pay.sub(v.capital),
                left: v.capital,
                gain: v.capital >= pay
            });
        }
    }

    function stop(uint256[][] memory minBaseAmounts) public override checkActive nonReentrant onlyGovernor {
        _stopCycle(minBaseAmounts);
    }

    function withdrawFee() public override {
        require(devAddress != address(0), "devAddress not set");
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = producedFee[tokens[i].addr];
            IERC20(tokens[i].addr).safeTransfer(devAddress, amount);
            producedFee[tokens[i].addr] = 0;
            emit WithdrawFee(devAddress, tokens[i].addr, amount);
        }
    }
}