pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../common/Constants.sol";
import "./LockLib.sol";
import "./ISafetyLocker.sol";

interface ILocker {
    function syncLiquiditySupply(address pool) external;

    /**
     * @dev Fails if transaction is not allowed. Otherwise returns the penalty.
     * Returns a bool and a uint16, bool clarifying the penalty applied, and uint16 the penaltyOver1000
     */
    function lockOrGetPenalty(address source, address dest)
    external
    returns (bool, uint256);
}

interface ILockerUser {
    function locker() external view returns (ILocker);
}

/**
 * Owner can lock unlock temporarily, or make them permanent.
 * It can also add penalty to certain activities.
 * Addresses can be whitelisted or have different penalties.
 * This must be inherited by the token itself.
 */
contract Locker is ILocker, Ownable {
    // Putting all conditions in one mapping to prevent unnecessary lookup and save gas
    mapping (address=>LockLib.TargetPolicy) locked;
    mapping (address=>uint256) liquiditySupply;
    address public mustUpdate;
    address public safetyLocker;

    function allowPool(address token1, address token2)
    external onlyOwner() {
        address pool = Constants.uniV2Factory.getPair(token1, token2);
        if (pool == address(0)) {
            pool = Constants.uniV2Factory.createPair(token1, token2);
        }
        // Pool will not be opened to public yet.
        locked[pool].lockType = LockLib.LockType.NoTransaction;
        liquiditySupply[pool] = IERC20(pool).totalSupply();
    }

    function getLockType(address target) external view returns(LockLib.LockType, uint16, bool) {
        LockLib.TargetPolicy memory res = locked[target];
        return (res.lockType, res.penaltyRateOver1000, res.isPermanent);
    }

    function setSafetyLocker(address _safetyLocker) external onlyOwner() {
        safetyLocker = _safetyLocker;
        if (safetyLocker != address(0)) {
            require(ISafetyLocker(_safetyLocker).IsSafetyLocker(), "Bad safetyLocker");
        }
    }

    /**
     */
    function lockAddress(address target, LockLib.LockType lockType, uint16 penaltyRateOver1000, bool permanent)
    external
    onlyOwner()
    returns(bool) {
        require(target != address(0), "Locker: invalid target address");
        require(!locked[target].isPermanent, "Locker: address lock is permanent");

        locked[target].lockType = lockType;
        locked[target].penaltyRateOver1000 = penaltyRateOver1000;
        locked[target].isPermanent = permanent;
        return true;
    }

    function multiBlackList(address[] calldata addresses) external onlyOwner() {
        for(uint i=0; i < addresses.length; i++) {
            locked[addresses[i]].lockType = LockLib.LockType.NoTransaction;
        }
    }

    /**
     * @dev Fails if transaction is not allowed. Otherwise returns the penalty.
     * Returns a bool and a uint16, bool clarifying the penalty applied, and uint16 the penaltyOver1000
     */
    function lockOrGetPenalty(address source, address dest) external override
    returns (bool, uint256) {
        LockLib.TargetPolicy memory sourcePolicy = locked[source];
        LockLib.TargetPolicy memory destPolicy = locked[dest];
        address mustUpdateAddress = mustUpdate;
        bool overridePenalty = false;
        if (mustUpdateAddress != address(0)) {
            mustUpdate = address(0);
            uint256 newSupply = IERC20(mustUpdateAddress).totalSupply();
            if (newSupply > liquiditySupply[mustUpdateAddress]) {
                liquiditySupply[mustUpdateAddress] = newSupply;
            }
        }

        if (sourcePolicy.lockType == LockLib.LockType.Master || destPolicy.lockType == LockLib.LockType.Master) {
            // if one side is a pool, update the mustUpdateAddress
            if (destPolicy.lockType == LockLib.LockType.NoBurnPool) {
                mustUpdate = dest;
            }
            return (true, 0);
        }
        require(sourcePolicy.lockType != LockLib.LockType.NoOut &&
            sourcePolicy.lockType != LockLib.LockType.NoTransaction, "Locker: not allowed source");
        require(destPolicy.lockType != LockLib.LockType.NoIn &&
            destPolicy.lockType != LockLib.LockType.NoTransaction, "Locker: not allowed destination");
        if (destPolicy.lockType == LockLib.LockType.NoBurnPool) {
            mustUpdate = dest;
        }
        if (sourcePolicy.lockType == LockLib.LockType.NoBurnPool) {
            require (IERC20(source).totalSupply() >= liquiditySupply[source], "Cannot remove liquidity");            
        }
        uint256 sourcePenalty = 0;
        if (sourcePolicy.lockType == LockLib.LockType.PenaltyOut ||
            sourcePolicy.lockType == LockLib.LockType.PenaltyInOrOut) {
            sourcePenalty = sourcePolicy.penaltyRateOver1000;
            overridePenalty = true;
        }
        uint256 destPenalty = 0;
        if (destPolicy.lockType == LockLib.LockType.PenaltyIn ||
            destPolicy.lockType == LockLib.LockType.PenaltyInOrOut) {
            destPenalty = destPolicy.penaltyRateOver1000;
            overridePenalty = true;
        }
        if (safetyLocker != address(0)) {
            ISafetyLocker(safetyLocker).verifyTransfer(source, dest);
        }
        return (overridePenalty, Math.max(sourcePenalty, destPenalty));
    }

    function syncLiquiditySupply(address pool) override
    external {
        LockLib.LockType state = locked[pool].lockType;
        require(state != LockLib.LockType.None, "Locker: pool not defined");
        LockLib.LockType senderState = locked[msg.sender].lockType;
        require(senderState == LockLib.LockType.LiquidityAdder, "Locker: Only call from liquidity adder");
        _syncLiquiditySupply(pool);
    }

    function _syncLiquiditySupply(address pool) internal {
        liquiditySupply[pool] = IERC20(pool).totalSupply();
        if (mustUpdate == pool) {
            mustUpdate = address(0);
        }
    }
}