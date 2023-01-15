// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Constants.sol";
import "./PoolSetters.sol";
import "./Liquidity.sol";

contract Pool is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PoolSetters,
    Liquidity
{
    using SafeMath for uint256;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    function initialize(address dollar) public initializer {
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNOR_ROLE, msg.sender);

        dollarAddress = dollar;
    }

    event Stake(
        address indexed account,
        uint256 start,
        uint256 value,
        uint256 poolID
    );
    event UnStake(
        address indexed account,
        uint256 start,
        uint256 value,
        uint256 poolID
    );
    event Claim(address indexed account, uint256 value, uint256 poolID);
    event Provide(
        address indexed account,
        uint256 value,
        uint256 lessUsdc,
        uint256 newUniv2,
        uint256 poolID
    );

    function distributeReward(uint256 value) external{
        require(msg.sender == daoAddress, "invalid caller!");
        uint256 totalRatio = 0;
        for (uint256 i = 0; i < poolCount; ++i) {
            totalRatio = totalRatio.add(_state[i].ratio);
        }
        for (uint256 i = 0; i < poolCount; ++i) {
            incrementBalanceOfReward(value.mul(_state[i].ratio).div(totalRatio), i);
        }
    }

    /*
        internal functions
    */
    function deposit(uint256 value, uint256 poolID) internal notPaused(poolID) {
        lpToken(poolID).transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(msg.sender, value, poolID);

        balanceCheck(poolID);
    }

    function withdraw(uint256 value, uint256 poolID) internal {
        lpToken(poolID).transfer(msg.sender, value);
        decrementBalanceOfStaged(
            msg.sender,
            value,
            "Pool: insufficient staged balance",
            poolID
        );

        balanceCheck(poolID);
    }

    function bond(uint256 value, uint256 poolID) internal notPaused(poolID) {
        unfreeze(msg.sender, poolID);

        uint256 totalRewardedWithPhantom = totalRewarded(poolID).add(
            totalPhantom(poolID)
        );
        uint256 newPhantom = totalBonded(poolID) == 0
            ? totalRewarded(poolID) == 0
                ? Constants.getInitialStakeMultiple().mul(value)
                : 0
            : totalRewardedWithPhantom.mul(value).div(totalBonded(poolID));

        incrementBalanceOfBonded(msg.sender, value, poolID);
        incrementBalanceOfPhantom(msg.sender, newPhantom, poolID);
        decrementBalanceOfStaged(
            msg.sender,
            value,
            "Pool: insufficient staged balance",
            poolID
        );

        balanceCheck(poolID);
    }

    function unbond(uint256 value, uint256 poolID) internal {
        unfreeze(msg.sender, poolID);

        uint256 balanceOfBonded = balanceOfBonded(msg.sender, poolID);
        require(balanceOfBonded > 0, "insufficient bonded balance");

        uint256 newClaimable = balanceOfRewarded(msg.sender, poolID)
            .mul(value)
            .div(balanceOfBonded);
        uint256 lessPhantom = balanceOfPhantom(msg.sender, poolID)
            .mul(value)
            .div(balanceOfBonded);

        incrementBalanceOfStaged(msg.sender, value, poolID);
        incrementBalanceOfClaimable(msg.sender, newClaimable, poolID);
        decrementBalanceOfBonded(
            msg.sender,
            value,
            "Pool: insufficient bonded balance",
            poolID
        );
        decrementBalanceOfPhantom(
            msg.sender,
            lessPhantom,
            "Pool: insufficient phantom balance",
            poolID
        );

        balanceCheck(poolID);
    }

    /*
        core functions
    */
    function stake(uint256 value, uint256 poolID) external notPaused(poolID) {
        deposit(value, poolID);
        bond(value, poolID);
        emit Stake(msg.sender, epoch(), value, poolID);
    }

    function unstake(uint256 value, uint256 poolID) external {
        unbond(value, poolID);
        withdraw(value, poolID);
        emit UnStake(msg.sender, epoch(), value, poolID);
    }

    function claim(uint256 value, uint256 poolID) external {
        decrementBalanceOfClaimable(
            msg.sender,
            value,
            "Pool: insufficient claimable balance",
            poolID
        );

        balanceCheck(poolID);
        dollar().transfer(msg.sender, value);

        emit Claim(msg.sender, value, poolID);
    }

    function provide(uint256 value, uint256 poolID) external notPaused(poolID) {
        require(totalBonded(poolID) > 0, "insufficient total bonded");
        require(totalRewarded(poolID) > 0, "insufficient total rewarded");
        require(
            balanceOfRewarded(msg.sender, poolID) >= value,
            "insufficient rewarded balance"
        );

        (uint256 lessUsdc, uint256 newUniv2) = addLiquidity(value, poolID);

        decrementBalanceOfReward(value, poolID, "insufficient rewarded balance");

        uint256 totalRewardedWithPhantom = totalRewarded(poolID)
            .add(totalPhantom(poolID))
            .add(value);
        uint256 newPhantomFromBonded = totalRewardedWithPhantom
            .mul(newUniv2)
            .div(totalBonded(poolID));

        incrementBalanceOfBonded(msg.sender, newUniv2, poolID);
        incrementBalanceOfPhantom(
            msg.sender,
            value.add(newPhantomFromBonded),
            poolID
        );

        balanceCheck(poolID);

        emit Provide(msg.sender, value, lessUsdc, newUniv2, poolID);
    }

    /*
        govenor methods
    */

    function setDao(address dao) external onlyRole(GOVERNOR_ROLE) {
        daoAddress = dao;
    }

    function setDollar(address dollar) external onlyRole(GOVERNOR_ROLE) {
        dollarAddress = dollar;
    }

    function setLPToken(
        uint256 poolID,
        address lp,
        PoolStorage.LPType t
    ) external onlyRole(GOVERNOR_ROLE) {
        _state[poolID].provider.lpToken = IERC20(lp);
        _state[poolID].lpType = t;
    }

    function setLPRatio(uint256 poolID, uint256 ratio)
        external
        onlyRole(GOVERNOR_ROLE)
    {
        _state[poolID].ratio = ratio;
    }

    function setPoolCount(uint256 count) external onlyRole(GOVERNOR_ROLE) {
        poolCount = count;
    }

    function emergencyWithdraw(address token, uint256 value)
        external
        onlyRole(GOVERNOR_ROLE)
    {
        IERC20(token).transfer(address(dao()), value);
    }

    function emergencyPause(uint256 poolID) external onlyRole(GOVERNOR_ROLE) {
        pause(poolID);
    }

    function resumePool(uint256 poolID) external onlyRole(GOVERNOR_ROLE) {
        resume(poolID);
    }

    /*
        help methods
    */
    function balanceCheck(uint256 poolID) private view {
        require(
            lpToken(poolID).balanceOf(address(this)) >=
                totalStaged(poolID).add(totalBonded(poolID)),
            "Inconsistent UNI-V2 balances"
        );
    }

    modifier onlyFrozen(address account, uint256 poolID) {
        require(
            statusOf(account, poolID) == PoolAccount.Status.Frozen,
            "Not frozen"
        );
        _;
    }

    modifier notPaused(uint256 poolID) {
        require(!paused(poolID), "Paused");
        _;
    }
}