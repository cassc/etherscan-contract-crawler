//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for Antic fee
library StorageAnticFee {
    uint16 public constant PERCENTAGE_DIVIDER = 1000; // .1 precision
    uint16 public constant MAX_ANTIC_FEE_PERCENTAGE = 500; // 50%

    struct DiamondStorage {
        address antic;
        /// @dev Maps between member and it's Antic fee deposit
        /// Used only in `leave`
        mapping(address => uint256) memberFeeDeposits;
        /// @dev Total Antic join deposits mades
        uint256 totalJoinFeeDeposits;
        /// @dev Antic join fee percentage out of 1000
        /// e.g. 25 -> 25/1000 = 2.5%
        uint16 joinFeePercentage;
        /// @dev Antic sell/receive fee percentage out of 1000
        /// e.g. 25 -> 25/1000 = 2.5%
        uint16 sellFeePercentage;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.AnticFee");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    function _initStorage(
        address antic,
        uint16 joinFeePercentage,
        uint16 sellFeePercentage
    ) internal {
        DiamondStorage storage ds = diamondStorage();

        require(antic != address(0), "Storage: Invalid Antic address");

        require(
            joinFeePercentage <= MAX_ANTIC_FEE_PERCENTAGE,
            "Storage: Invalid Antic join fee percentage"
        );

        require(
            sellFeePercentage <= MAX_ANTIC_FEE_PERCENTAGE,
            "Storage: Invalid Antic sell/receive fee percentage"
        );

        ds.antic = antic;
        ds.joinFeePercentage = joinFeePercentage;
        ds.sellFeePercentage = sellFeePercentage;
    }
}