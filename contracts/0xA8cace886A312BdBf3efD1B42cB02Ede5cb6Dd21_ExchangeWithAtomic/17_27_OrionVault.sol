// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";
import "./ExchangeStorage.sol";

abstract contract OrionVault is ExchangeStorage, OwnableUpgradeSafe {

    enum StakePhase{ NOTSTAKED, LOCKED, RELEASING, READYTORELEASE, FROZEN }

    struct Stake {
        uint64 amount; // 100m ORN in circulation fits uint64
        StakePhase phase;
        uint64 lastActionTimestamp;
    }

    uint64 constant releasingDuration = 3600*24;
    mapping(address => Stake) private stakingData;

    /**
     * @dev Returns locked or frozen stake balance only
     * @param user address
     */
    function getLockedStakeBalance(address user) public view returns (uint256) {
        return stakingData[user].amount;
    }

    /**
     * @dev Request stake unlock for msg.sender
     * @dev If stake phase is LOCKED, that changes phase to RELEASING
     * @dev If stake phase is READYTORELEASE, that withdraws stake to balance
     * @dev Note, both unlock and withdraw is impossible if user has liabilities
     */
    function requestReleaseStake() public {
        address user = _msgSender();
        Stake storage stake = stakingData[user];
        assetBalances[user][address(_orionToken)] += stake.amount;
        stake.amount = 0;
        stake.phase = StakePhase.NOTSTAKED;
    }

    /**
     * @dev Lock some orions from exchange balance sheet
     * @param amount orions in 1e-8 units to stake
     */
    function lockStake(uint64 amount) public {
        address user = _msgSender();
        require(assetBalances[user][address(_orionToken)]>amount, "E1S");
        Stake storage stake = stakingData[user];

        assetBalances[user][address(_orionToken)] -= amount;
        stake.amount += amount;
    }

}