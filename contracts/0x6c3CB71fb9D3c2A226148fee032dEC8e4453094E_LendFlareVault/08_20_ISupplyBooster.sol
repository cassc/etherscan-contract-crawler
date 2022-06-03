// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface ISupplyBooster {
    struct PoolInfo {
        address underlyToken;
        address rewardInterestPool;
        address supplyTreasuryFund;
        address virtualBalance;
        bool isErc20;
        bool shutdown;
    }

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function getLendingUnderlyToken(bytes32 _lendingId)
        external
        view
        returns (address);
}