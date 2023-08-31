// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "IERC20Metadata.sol";
import "ICurveProxy.sol";
import "IVault.sol";
import "PrismaOwnable.sol";

interface IBooster {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);

    function poolInfo(
        uint256 _pid
    )
        external
        view
        returns (address lpToken, address token, address gauge, address crvRewards, address stash, bool shutdown);
}

interface IBaseRewardPool {
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function getReward() external;
}

interface IConvexStash {
    function tokenInfo(address _token) external view returns (address token, address rewards);
}

/**
    @title Prisma Convex Deposit Wrapper
    @notice Standard ERC20 interface around a deposit of a Curve LP token into Convex.
            Tokens are minted by depositing Curve LP tokens, and burned to receive the LP
            tokens back. Holders may claim PRISMA emissions on top of the earned CRV and CVX.
 */
contract ConvexDepositToken {
    IERC20 public immutable PRISMA;
    IERC20 public immutable CRV;
    IERC20 public immutable CVX;

    IBooster public immutable booster;
    ICurveProxy public immutable curveProxy;
    IPrismaVault public immutable vault;

    IERC20 public lpToken;
    uint256 public depositPid;
    IBaseRewardPool public crvRewards;
    IBaseRewardPool public cvxRewards;

    uint256 public emissionId;

    string public symbol;
    string public name;
    uint256 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // each array relates to [PRISMA, CRV, CVX]
    uint256[3] public rewardIntegral;
    uint128[3] public rewardRate;

    // last known balances for CRV, CVX
    // must track because anyone can trigger a claim for any address
    uint128 public lastCrvBalance;
    uint128 public lastCvxBalance;

    uint32 public lastUpdate;
    uint32 public periodFinish;

    mapping(address => uint256[3]) public rewardIntegralFor;
    mapping(address => uint128[3]) private storedPendingReward;

    uint256 constant REWARD_DURATION = 1 weeks;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LPTokenDeposited(address indexed lpToken, address indexed receiver, uint256 amount);
    event LPTokenWithdrawn(address indexed lpToken, address indexed receiver, uint256 amount);
    event RewardClaimed(address indexed receiver, uint256 prismaAmount, uint256 crvAmount, uint256 cvxAmount);

    constructor(IERC20 _prisma, IERC20 _CRV, IERC20 _CVX, IBooster _booster, ICurveProxy _proxy, IPrismaVault _vault) {
        PRISMA = _prisma;
        CRV = _CRV;
        CVX = _CVX;
        booster = _booster;
        curveProxy = _proxy;
        vault = _vault;
    }

    function initialize(uint256 pid) external {
        require(address(lpToken) == address(0), "Already initialized");
        (address _lpToken, , , address _crvRewards, address _stash, ) = booster.poolInfo(pid);

        depositPid = pid;
        lpToken = IERC20(_lpToken);
        crvRewards = IBaseRewardPool(_crvRewards);

        (, address _rewards) = IConvexStash(_stash).tokenInfo(address(CVX));
        require(_rewards != address(0), "Pool has no CVX rewards");
        cvxRewards = IBaseRewardPool(_rewards);

        IERC20(_lpToken).approve(address(booster), type(uint256).max);

        string memory _symbol = IERC20Metadata(_lpToken).symbol();
        name = string.concat("Prisma ", _symbol, " Convex Deposit");
        symbol = string.concat("prisma-", _symbol);

        periodFinish = uint32(block.timestamp - 1);
    }

    function notifyRegisteredId(uint256[] memory assignedIds) external returns (bool) {
        require(msg.sender == address(vault));
        require(emissionId == 0, "Already registered");
        require(assignedIds.length == 1, "Incorrect ID count");
        emissionId = assignedIds[0];

        return true;
    }

    function deposit(address receiver, uint256 amount) external returns (bool) {
        require(amount > 0, "Cannot deposit zero");
        lpToken.transferFrom(msg.sender, address(this), amount);
        booster.deposit(depositPid, amount, true);
        uint256 balance = balanceOf[receiver];
        uint256 supply = totalSupply;
        balanceOf[receiver] = balance + amount;
        totalSupply = supply + amount;

        _updateIntegrals(receiver, balance, supply);
        if (block.timestamp / 1 weeks >= periodFinish / 1 weeks) _fetchRewards();

        emit Transfer(address(0), receiver, amount);
        emit LPTokenDeposited(address(lpToken), receiver, amount);

        return true;
    }

    function withdraw(address receiver, uint256 amount) external returns (bool) {
        require(amount > 0, "Cannot withdraw zero");
        uint256 balance = balanceOf[msg.sender];
        uint256 supply = totalSupply;
        balanceOf[msg.sender] = balance - amount;
        totalSupply = supply - amount;

        crvRewards.withdrawAndUnwrap(amount, false);
        lpToken.transfer(receiver, amount);

        _updateIntegrals(msg.sender, balance, supply);
        if (block.timestamp / 1 weeks >= periodFinish / 1 weeks) _fetchRewards();

        emit Transfer(msg.sender, address(0), amount);
        emit LPTokenWithdrawn(address(lpToken), receiver, amount);

        return true;
    }

    function _claimReward(address claimant, address receiver) internal returns (uint128[3] memory amounts) {
        _updateIntegrals(claimant, balanceOf[claimant], totalSupply);
        amounts = storedPendingReward[claimant];
        delete storedPendingReward[claimant];
        lastCrvBalance -= amounts[1];
        lastCvxBalance -= amounts[2];

        CRV.transfer(receiver, amounts[1]);
        CVX.transfer(receiver, amounts[2]);

        return amounts;
    }

    function claimReward(
        address receiver
    ) external returns (uint256 prismaAmount, uint256 crvAmount, uint256 cvxAmount) {
        uint128[3] memory amounts = _claimReward(msg.sender, receiver);
        vault.transferAllocatedTokens(msg.sender, receiver, amounts[0]);

        emit RewardClaimed(receiver, amounts[0], amounts[1], amounts[2]);
        return (amounts[0], amounts[1], amounts[2]);
    }

    function vaultClaimReward(address claimant, address receiver) external returns (uint256) {
        require(msg.sender == address(vault));
        uint128[3] memory amounts = _claimReward(claimant, receiver);

        emit RewardClaimed(claimant, 0, amounts[1], amounts[2]);
        return amounts[0];
    }

    function claimableReward(
        address account
    ) external view returns (uint256 prismaAmount, uint256 crvAmount, uint256 cvxAmount) {
        uint256 updated = periodFinish;
        if (updated > block.timestamp) updated = block.timestamp;
        uint256 duration = updated - lastUpdate;
        uint256 balance = balanceOf[account];
        uint256 supply = totalSupply;
        uint256[3] memory amounts;

        for (uint256 i = 0; i < 3; i++) {
            uint256 integral = rewardIntegral[i];
            if (supply > 0) {
                integral += (duration * rewardRate[i] * 1e18) / supply;
            }
            uint256 integralFor = rewardIntegralFor[account][i];
            amounts[i] = storedPendingReward[account][i] + ((balance * (integral - integralFor)) / 1e18);
        }
        return (amounts[0], amounts[1], amounts[2]);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        uint256 supply = totalSupply;

        uint256 balance = balanceOf[_from];
        balanceOf[_from] = balance - _value;
        _updateIntegrals(_from, balance, supply);

        balance = balanceOf[_to];
        balanceOf[_to] = balance + _value;
        _updateIntegrals(_to, balance, supply);

        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 allowed = allowance[_from][msg.sender];
        if (allowed != type(uint256).max) {
            allowance[_from][msg.sender] = allowed - _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function _updateIntegrals(address account, uint256 balance, uint256 supply) internal {
        uint256 updated = periodFinish;
        if (updated > block.timestamp) updated = block.timestamp;
        uint256 duration = updated - lastUpdate;
        if (duration > 0) lastUpdate = uint32(updated);

        for (uint256 i = 0; i < 3; i++) {
            uint256 integral = rewardIntegral[i];
            if (duration > 0 && supply > 0) {
                integral += (duration * rewardRate[i] * 1e18) / supply;
                rewardIntegral[i] = integral;
            }
            uint256 integralFor = rewardIntegralFor[account][i];
            if (integral > integralFor) {
                storedPendingReward[account][i] += uint128((balance * (integral - integralFor)) / 1e18);
                rewardIntegralFor[account][i] = integral;
            }
        }
    }

    function fetchRewards() external {
        require(block.timestamp / 1 weeks >= periodFinish / 1 weeks, "Can only fetch once per week");
        _fetchRewards();
    }

    function _fetchRewards() internal {
        uint256 prismaAmount;
        uint256 id = emissionId;
        if (id > 0) prismaAmount = vault.allocateNewEmissions(id);
        crvRewards.getReward(address(this), false);
        cvxRewards.getReward();

        uint256 last = lastCrvBalance;
        uint256 crvAmount = CRV.balanceOf(address(this)) - last;
        // apply CRV fee and send fee tokens to curveProxy
        uint256 fee = (crvAmount * curveProxy.crvFeePct()) / 10000;
        if (fee > 0) {
            crvAmount -= fee;
            CRV.transfer(address(curveProxy), fee);
        }
        lastCrvBalance = uint128(last + crvAmount);

        last = lastCvxBalance;
        uint256 cvxAmount = CVX.balanceOf(address(this)) - last;
        lastCvxBalance = uint128(cvxAmount + last);

        uint256 _periodFinish = periodFinish;
        if (block.timestamp < _periodFinish) {
            uint256 remaining = _periodFinish - block.timestamp;
            prismaAmount += remaining * rewardRate[0];
            crvAmount += remaining * rewardRate[1];
            cvxAmount += remaining * rewardRate[2];
        }

        rewardRate[0] = uint128(prismaAmount / REWARD_DURATION);
        rewardRate[1] = uint128(crvAmount / REWARD_DURATION);
        rewardRate[2] = uint128(cvxAmount / REWARD_DURATION);

        lastUpdate = uint32(block.timestamp);
        periodFinish = uint32(block.timestamp + REWARD_DURATION);
    }
}