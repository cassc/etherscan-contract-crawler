// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "IERC20Metadata.sol";
import "ICurveProxy.sol";
import "IVault.sol";
import "ILiquidityGauge.sol";
import "PrismaOwnable.sol";

/**
    @title Prisma Curve Deposit Wrapper
    @notice Standard ERC20 interface around a deposit of a Curve LP token into it's
            associated gauge. Tokens are minted by depositing Curve LP tokens, and
            burned to receive the LP tokens back. Holders may claim PRISMA emissions
            on top of the earned CRV.
 */
contract CurveDepositToken {
    IERC20 public immutable PRISMA;
    IERC20 public immutable CRV;
    ICurveProxy public immutable curveProxy;
    IPrismaVault public immutable vault;

    ILiquidityGauge public gauge;
    IERC20 public lpToken;

    uint256 public emissionId;

    string public symbol;
    string public name;
    uint256 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // each array relates to [PRISMA, CRV]
    uint256[2] public rewardIntegral;
    uint128[2] public rewardRate;
    uint32 public lastUpdate;
    uint32 public periodFinish;

    mapping(address => uint256[2]) public rewardIntegralFor;
    mapping(address => uint128[2]) private storedPendingReward;

    uint256 constant REWARD_DURATION = 1 weeks;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LPTokenDeposited(address indexed lpToken, address indexed receiver, uint256 amount);
    event LPTokenWithdrawn(address indexed lpToken, address indexed receiver, uint256 amount);
    event RewardClaimed(address indexed receiver, uint256 prismaAmount, uint256 crvAmount);

    constructor(IERC20 _prisma, IERC20 _CRV, ICurveProxy _curveProxy, IPrismaVault _vault) {
        PRISMA = _prisma;
        CRV = _CRV;
        curveProxy = _curveProxy;
        vault = _vault;
    }

    function initialize(ILiquidityGauge _gauge) external {
        require(address(gauge) == address(0), "Already intialized");
        gauge = _gauge;

        address _token = _gauge.lp_token();
        lpToken = IERC20(_token);
        IERC20(_token).approve(address(gauge), type(uint256).max);

        string memory _symbol = IERC20Metadata(_token).symbol();
        name = string.concat("Prisma ", _symbol, " Curve Deposit");
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
        gauge.deposit(amount, address(curveProxy));
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
        curveProxy.withdrawFromGauge(address(gauge), address(lpToken), amount, receiver);

        _updateIntegrals(msg.sender, balance, supply);
        if (block.timestamp / 1 weeks >= periodFinish / 1 weeks) _fetchRewards();

        emit Transfer(msg.sender, address(0), amount);
        emit LPTokenWithdrawn(address(lpToken), receiver, amount);

        return true;
    }

    function _claimReward(address claimant, address receiver) internal returns (uint128[2] memory amounts) {
        _updateIntegrals(claimant, balanceOf[claimant], totalSupply);
        amounts = storedPendingReward[claimant];
        delete storedPendingReward[claimant];

        CRV.transfer(receiver, amounts[1]);
        return amounts;
    }

    function claimReward(address receiver) external returns (uint256 prismaAmount, uint256 crvAmount) {
        uint128[2] memory amounts = _claimReward(msg.sender, receiver);
        vault.transferAllocatedTokens(msg.sender, receiver, amounts[0]);

        emit RewardClaimed(receiver, amounts[0], amounts[1]);
        return (amounts[0], amounts[1]);
    }

    function vaultClaimReward(address claimant, address receiver) external returns (uint256) {
        require(msg.sender == address(vault));
        uint128[2] memory amounts = _claimReward(claimant, receiver);

        emit RewardClaimed(receiver, 0, amounts[1]);
        return amounts[0];
    }

    function claimableReward(address account) external view returns (uint256 prismaAmount, uint256 crvAmount) {
        uint256 updated = periodFinish;
        if (updated > block.timestamp) updated = block.timestamp;
        uint256 duration = updated - lastUpdate;
        uint256 balance = balanceOf[account];
        uint256 supply = totalSupply;
        uint256[2] memory amounts;

        for (uint256 i = 0; i < 2; i++) {
            uint256 integral = rewardIntegral[i];
            if (supply > 0) {
                integral += (duration * rewardRate[i] * 1e18) / supply;
            }
            uint256 integralFor = rewardIntegralFor[account][i];
            amounts[i] = storedPendingReward[account][i] + ((balance * (integral - integralFor)) / 1e18);
        }
        return (amounts[0], amounts[1]);
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

        for (uint256 i = 0; i < 2; i++) {
            uint256 integral = rewardIntegral[i];
            if (duration > 0 && supply > 0) {
                integral += (duration * rewardRate[i] * 1e18) / supply;
                rewardIntegral[i] = integral;
            }
            if (account != address(0)) {
                uint256 integralFor = rewardIntegralFor[account][i];
                if (integral > integralFor) {
                    storedPendingReward[account][i] += uint128((balance * (integral - integralFor)) / 1e18);
                    rewardIntegralFor[account][i] = integral;
                }
            }
        }
    }

    function fetchRewards() external {
        require(block.timestamp / 1 weeks >= periodFinish / 1 weeks, "Can only fetch once per week");
        _updateIntegrals(address(0), 0, totalSupply);
        _fetchRewards();
    }

    function _fetchRewards() internal {
        uint256 prismaAmount;
        uint256 id = emissionId;
        if (id > 0) prismaAmount = vault.allocateNewEmissions(id);

        // try/catch to allow active receiver before Curve gauge is voted in
        uint256 crvAmount;
        try curveProxy.mintCRV(address(gauge), address(this)) returns (uint256 minted) {
            crvAmount = minted;
        } catch {}

        uint256 _periodFinish = periodFinish;
        if (block.timestamp < _periodFinish) {
            uint256 remaining = _periodFinish - block.timestamp;
            prismaAmount += remaining * rewardRate[0];
            crvAmount += remaining * rewardRate[1];
        }
        rewardRate[0] = uint128(prismaAmount / REWARD_DURATION);
        rewardRate[1] = uint128(crvAmount / REWARD_DURATION);

        lastUpdate = uint32(block.timestamp);
        periodFinish = uint32(block.timestamp + REWARD_DURATION);
    }
}