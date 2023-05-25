pragma solidity 0.6.6;

interface ILiquiditySyncer {
    function syncLiquiditySupply(address pool) external;
}

interface ILocker {
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