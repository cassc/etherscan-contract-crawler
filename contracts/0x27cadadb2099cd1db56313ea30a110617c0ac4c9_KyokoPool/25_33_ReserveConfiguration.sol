// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "../utils/Errors.sol";
import "../utils/DataTypes.sol";

/**
 * @title ReserveConfiguration library
 * @author Kyoko
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
    uint256 constant RESERVE_FACTOR_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 constant BORROW_RATIO_MASK =                         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 constant PERIOD_MASK =                               0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFF; // prettier-ignore
    uint256 constant MIN_BORROW_TIME_MASK =                      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000FFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant ACTIVE_MASK =                               0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant LIQUIDATION_THRESHOLD_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE0001FFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant BORROWING_MASK =                            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant STABLE_BORROWING_MASK =                     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant LIQUIDATION_TIME_MASK =                     0xFFFFFFFFFFFFFFFFFFFFFFFFF8000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant BID_TIME_MASK =                             0xFFFFFFFFFFFFFFFFFFF8000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant FROZEN_MASK =                               0xFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant LOCK_MASK =                                 0xFFFFFFFFFFF00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant TYPE_MASK =                                 0xFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the factor, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 constant BORROW_RATIO_START_BIT_POSITION = 16;
    uint256 constant PERIOD_START_BIT_POSITION = 32;
    uint256 constant MIN_BORROW_TIME_START_BIT_POSITION = 72;
    uint256 constant IS_ACTIVE_START_BIT_POSITION = 112;
    uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 113;
    uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 129;
    uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 130;
    uint256 constant LIQUIDATION_TIME_START_BIT_POSITION = 131;
    uint256 constant BID_TIME_START_BIT_POSITION = 155;
    uint256 constant IS_FROZEN_START_BIT_POSITION = 179;
    uint256 constant LOCK_START_BIT_POSITION = 180;
    uint256 constant TYPE_START_BIT_POSITION = 212;

    uint256 constant MAX_VALID_RESERVE_FACTOR = 10000;
    uint256 constant MAX_VALID_BORROW_RATIO = 10000;
    uint256 constant MAX_VALID_PERIOD = 30 days;
    uint256 constant MAX_VALID_MIN_BORROW_TIME = 15 days;
    uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 constant MAX_VALID_LIQUIDATION_TIME = 30 days;
    uint256 constant MAX_VALID_BID_TIME = 15 days;

    /**
     * @dev Sets the reserve factor of the reserve
     * @param self The reserve configuration
     * @param reserveFactor The reserve factor
     **/
    function setReserveFactor(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 reserveFactor
    ) internal pure {
        require(
            reserveFactor <= MAX_VALID_RESERVE_FACTOR,
            Errors.RC_INVALID_RESERVE_FACTOR
        );

        self.data = (self.data & RESERVE_FACTOR_MASK) | reserveFactor;
    }

    /**
     * @dev Gets the reserve factor of the reserve
     * @param self The reserve configuration
     * @return The reserve factor
     **/
    function getReserveFactor(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (uint256) {
        return self.data & ~RESERVE_FACTOR_MASK;
    }

    /**
     * @dev Sets the borrow ratio of the reserve
     * @param self The reserve configuration
     * @param ratio The new borrow ratio
     **/
    function setBorrowRatio(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 ratio
    ) internal pure {
        require(
            ratio <= MAX_VALID_BORROW_RATIO,
            Errors.RC_INVALID_BORROW_RATIO
        );

        self.data =
            (self.data & BORROW_RATIO_MASK) |
            (ratio << BORROW_RATIO_START_BIT_POSITION);
    }

    /**
     * @dev Gets the borrow ratio of the reserve
     * @param self The reserve configuration
     * @return The borrow ratio
     **/
    function getBorrowRatio(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (uint256) {
        return
            (self.data & ~BORROW_RATIO_MASK) >> BORROW_RATIO_START_BIT_POSITION;
    }

    /**
     * @dev Sets the fixed borrow period of the reserve
     * @param self The reserve configuration
     * @param period The new period
     **/
    function setPeriod(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 period
    ) internal pure {
        require(period <= MAX_VALID_PERIOD, Errors.RC_INVALID_PERIOD);

        self.data =
            (self.data & PERIOD_MASK) |
            (period << PERIOD_START_BIT_POSITION);
    }

    /**
     * @dev Gets the fixed borrow period of the reserve
     * @param self The reserve configuration
     * @return The fixed borrow period
     **/
    function getPeriod(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (uint256) {
        return (self.data & ~PERIOD_MASK) >> PERIOD_START_BIT_POSITION;
    }

    /**
     * @dev Sets the miniumn borrow time of the reserve
     * @param self The reserve configuration
     * @param time The new minimum borrow time
     **/
    function setMinBorrowTime(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 time
    ) internal pure {
        require(
            time <= MAX_VALID_MIN_BORROW_TIME,
            Errors.RC_INVALID_MIN_BORROW_TIME
        );

        self.data =
            (self.data & MIN_BORROW_TIME_MASK) |
            (time << MIN_BORROW_TIME_START_BIT_POSITION);
    }

    /**
     * @dev Gets the miniumn borrow time of the reserve
     * @param self The reserve configuration
     * @return The minimum borrow time
     **/
    function getMinBorrowTime(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (uint256) {
        return
            (self.data & ~MIN_BORROW_TIME_MASK) >>
            MIN_BORROW_TIME_START_BIT_POSITION;
    }

    /**
     * @dev Sets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     **/
    function setActive(
        DataTypes.ReserveConfigurationMap memory self,
        bool active
    ) internal pure {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the active state of the reserve
     * @param self The reserve configuration
     * @return The active state
     **/
    function getActive(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (bool) {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @dev Sets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @param threshold The new liquidation threshold
     **/
    function setLiquidationThreshold(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 threshold
    ) internal pure {
        require(
            threshold <= MAX_VALID_LIQUIDATION_THRESHOLD,
            Errors.RC_INVALID_LIQ_THRESHOLD
        );

        self.data =
            (self.data & LIQUIDATION_THRESHOLD_MASK) |
            (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @return The liquidation threshold
     **/
    function getLiquidationThreshold(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (uint256) {
        return
            (self.data & ~LIQUIDATION_THRESHOLD_MASK) >>
            LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }

    /**
     * @dev Enables or disables borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the borrowing needs to be enabled, false otherwise
     **/
    function setBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool enabled
    ) internal pure {
        self.data =
            (self.data & BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @dev Gets the borrowing state of the reserve
     * @param self The reserve configuration
     * @return The borrowing state
     **/
    function getBorrowingEnabled(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (bool) {
        return (self.data & ~BORROWING_MASK) != 0;
    }

    /**
     * @dev Enables or disables stable rate borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
     **/
    function setStableRateBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool enabled
    ) internal pure {
        self.data =
            (self.data & STABLE_BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) <<
                STABLE_BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @dev Gets the stable rate borrowing state of the reserve
     * @param self The reserve configuration
     * @return The stable rate borrowing state
     **/
    function getStableRateBorrowingEnabled(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (bool) {
        return (self.data & ~STABLE_BORROWING_MASK) != 0;
    }

    /**
     * @dev Sets the liquidation duration of the reserve
     * @param self The reserve configuration
     * @param time The new liquidation duration
     **/
    function setLiquidationTime(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 time
    ) internal pure {
        require(time <= MAX_VALID_LIQUIDATION_TIME, Errors.RC_INVALID_LIQ_TIME);

        self.data =
            (self.data & LIQUIDATION_TIME_MASK) |
            (time << LIQUIDATION_TIME_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation duration of the reserve
     * @param self The reserve configuration
     * @return The liquidation duration
     **/
    function getLiquidationTime(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (uint256) {
        return
            (self.data & ~LIQUIDATION_TIME_MASK) >>
            LIQUIDATION_TIME_START_BIT_POSITION;
    }

    /**
     * @dev Sets the effective time of auction
     * @param self The reserve configuration
     * @param time The new auction duration
     **/
    function setBidTime(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 time
    ) internal pure {
        require(time <= MAX_VALID_BID_TIME, Errors.RC_INVALID_BID_TIME);

        self.data =
            (self.data & BID_TIME_MASK) |
            (time << BID_TIME_START_BIT_POSITION);
    }

    /**
     * @dev Gets the effective time of auction
     * @param self The reserve configuration
     * @return The effective time of auction
     **/
    function getBidTime(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (uint256) {
        return (self.data & ~BID_TIME_MASK) >> BID_TIME_START_BIT_POSITION;
    }

    /**
     * @dev Sets the frozen state of the reserve
     * @param self The reserve configuration
     * @param frozen The frozen state
     **/
    function setFrozen(
        DataTypes.ReserveConfigurationMap memory self,
        bool frozen
    ) internal pure {
        self.data =
            (self.data & FROZEN_MASK) |
            (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

    /**
     * @dev Gets the frozen state of the reserve
     * @param self The reserve configuration
     * @return The frozen state
     **/
    function getFrozen(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (bool) {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @dev Sets the initial liquidity lock time of reserve
     * @param self The reserve configuration
     * @param lockTime The new lock
     **/
    function setLockTime(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 lockTime
    ) internal pure {
        self.data =
            (self.data & LOCK_MASK) |
            (lockTime << LOCK_START_BIT_POSITION);
    }

    /**
     * @dev Gets the lock time of initial liquidity
     * @param self The reserve configuration
     * @return The lock time of initial liquidity
     **/
    function getLockTime(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (uint256) {
        return (self.data & ~LOCK_MASK) >> LOCK_START_BIT_POSITION;
    }

    /**
     * @dev Sets the type of reserve, 0 for perimissionless poo, 1 for blue chip, others for middle pool
     * @param self The reserve configuration
     * @param reserveType The new type
     **/
    function setType(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 reserveType
    ) internal pure {
        self.data =
            (self.data & TYPE_MASK) |
            (reserveType << TYPE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the type of reserve, 0 for perimissionless poo, 1 for blue chip, others for middle pool
     * @param self The reserve configuration
     * @return The type of reserve
     **/
    function getType(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (uint256) {
        return (self.data & ~TYPE_MASK) >> TYPE_START_BIT_POSITION;
    }

    /**
     * @dev Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
     **/
    function getFlags(
        DataTypes.ReserveConfigurationMap storage self
    ) internal view returns (bool, bool, bool, bool) {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~ACTIVE_MASK) != 0,
            (dataLocal & ~FROZEN_MASK) != 0,
            (dataLocal & ~BORROWING_MASK) != 0,
            (dataLocal & ~STABLE_BORROWING_MASK) != 0
        );
    }

    /**
     * @dev Gets the configuration paramters of the reserve
     * @param self The reserve configuration
     * @return The state params representing factor, borrow ratio, minimum borrow time, liquidation threshold, liquidation duration, auction duration, lock time, reserve type
     **/
    function getParams(
        DataTypes.ReserveConfigurationMap storage self
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 dataLocal = self.data;

        return (
            dataLocal & ~RESERVE_FACTOR_MASK,
            (dataLocal & ~BORROW_RATIO_MASK) >> BORROW_RATIO_START_BIT_POSITION,
            (dataLocal & ~PERIOD_MASK) >> PERIOD_START_BIT_POSITION,
            (dataLocal & ~MIN_BORROW_TIME_MASK) >>
                MIN_BORROW_TIME_START_BIT_POSITION,
            (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >>
                LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (dataLocal & ~LIQUIDATION_TIME_MASK) >>
                LIQUIDATION_TIME_START_BIT_POSITION,
            (dataLocal & ~BID_TIME_MASK) >> BID_TIME_START_BIT_POSITION,
            (dataLocal & ~LOCK_MASK) >> LOCK_START_BIT_POSITION,
            (dataLocal & ~TYPE_MASK) >> TYPE_START_BIT_POSITION
        );
    }

    /**
     * @dev Gets the configuration paramters of the reserve from a memory object
     * @param self The reserve configuration
     * @return The state params representing factor, borrow ratio, minimum borrow time, liquidation threshold, liquidation duration, auction duration, lock time, reserve type
     **/
    function getParamsMemory(
        DataTypes.ReserveConfigurationMap memory self
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 localData = self.data;
        return (
            localData & ~RESERVE_FACTOR_MASK,
            (localData & ~BORROW_RATIO_MASK) >> BORROW_RATIO_START_BIT_POSITION,
            (localData & ~PERIOD_MASK) >> PERIOD_START_BIT_POSITION,
            (localData & ~MIN_BORROW_TIME_MASK) >>
                MIN_BORROW_TIME_START_BIT_POSITION,
            (localData & ~LIQUIDATION_THRESHOLD_MASK) >>
                LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (localData & ~LIQUIDATION_TIME_MASK) >>
                LIQUIDATION_TIME_START_BIT_POSITION,
            (localData & ~BID_TIME_MASK) >> BID_TIME_START_BIT_POSITION,
            (localData & ~LOCK_MASK) >> LOCK_START_BIT_POSITION,
            (localData & ~TYPE_MASK) >> TYPE_START_BIT_POSITION
        );
    }

    /**
     * @dev Gets the configuration flags of the reserve from a memory object
     * @param self The reserve configuration
     * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
     **/
    function getFlagsMemory(
        DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (bool, bool, bool, bool) {
        return (
            (self.data & ~ACTIVE_MASK) != 0,
            (self.data & ~FROZEN_MASK) != 0,
            (self.data & ~BORROWING_MASK) != 0,
            (self.data & ~STABLE_BORROWING_MASK) != 0
        );
    }
}