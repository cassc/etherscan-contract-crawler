// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

abstract contract SmartAlphaEvents {
    /// @notice Logs a deposit of a junior
    /// @param user Address of the caller
    /// @param epochId The epoch in which they entered the queue
    /// @param underlyingIn The amount of underlying deposited
    /// @param currentQueueBalance The total balance of the user in the queue for the current epoch
    event JuniorJoinEntryQueue(address indexed user, uint256 epochId, uint256 underlyingIn, uint256 currentQueueBalance);

    /// @notice Logs a redeem (2nd step of deposit) of a junior
    /// @param user Address of the caller
    /// @param epochId The epoch for which the redeem was executed
    /// @param tokensOut The amount of junior tokens redeemed
    event JuniorRedeemTokens(address indexed user, uint256 epochId, uint256 tokensOut);

    /// @notice Logs an exit (1st step) of a junior
    /// @param user Address of the caller
    /// @param epochId The epoch in which they entered the queue
    /// @param tokensIn The amount of junior tokens deposited into the queue
    /// @param currentQueueBalance The total balance of the user in the queue for the current epoch
    event JuniorJoinExitQueue(address indexed user, uint256 epochId, uint256 tokensIn, uint256 currentQueueBalance);

    /// @notice Logs an exit (2nd step) of a junior
    /// @param user Address of the caller
    /// @param epochId The epoch for which the redeem was executed
    /// @param underlyingOut The amount of underlying transferred to the user
    event JuniorRedeemUnderlying(address indexed user, uint256 epochId, uint256 underlyingOut);

    /// @notice Logs a deposit of a senior
    /// @param user Address of the caller
    /// @param epochId The epoch in which they entered the queue
    /// @param underlyingIn The amount of underlying deposited
    /// @param currentQueueBalance The total balance of the user in the queue for the current epoch
    event SeniorJoinEntryQueue(address indexed user, uint256 epochId, uint256 underlyingIn, uint256 currentQueueBalance);

    /// @notice Logs a redeem (2nd step of deposit) of a senior
    /// @param user Address of the caller
    /// @param epochId The epoch for which the redeem was executed
    /// @param tokensOut The amount of senior tokens redeemed
    event SeniorRedeemTokens(address indexed user, uint256 epochId, uint256 tokensOut);

    /// @notice Logs an exit (1st step) of a senior
    /// @param user Address of the caller
    /// @param epochId The epoch in which they entered the queue
    /// @param tokensIn The amount of senior tokens deposited into the queue
    /// @param currentQueueBalance The total balance of the user in the queue for the current epoch
    event SeniorJoinExitQueue(address indexed user, uint256 epochId, uint256 tokensIn, uint256 currentQueueBalance);

    /// @notice Logs an exit (2nd step) of a senior
    /// @param user Address of the caller
    /// @param epochId The epoch for which the redeem was executed
    /// @param underlyingOut The amount of underlying transferred to the user
    event SeniorRedeemUnderlying(address indexed user, uint256 epochId, uint256 underlyingOut);

    /// @notice Logs an epoch end
    /// @param epochId The id of the epoch that just ended
    /// @param juniorProfits The amount of junior profits for the epoch that ended in underlying tokens
    /// @param seniorProfits The amount of senior profits for the epoch that ended in underlying tokens
    event EpochEnd(uint256 epochId, uint256 juniorProfits, uint256 seniorProfits);

    /// @notice Logs a transfer of fees
    /// @param caller The caller of the function
    /// @param destination The destination address of the funds
    /// @param amount The amount of tokens that were transferred
    event FeesTransfer(address caller, address destination, uint256 amount);

    /// @notice Logs a transfer of dao power to a new address
    /// @param oldDAO The address of the old DAO
    /// @param newDAO The address of the new DAO
    event TransferDAO(address oldDAO, address newDAO);

    /// @notice Logs a transfer of Guardian power to a new address
    /// @param oldGuardian The address of the old guardian
    /// @param newGuardian The address of the new guardian
    event TransferGuardian(address oldGuardian, address newGuardian);

    /// @notice Logs a system pause
    event PauseSystem();

    /// @notice logs a system resume
    event ResumeSystem();

    /// @notice logs a change of price oracle
    /// @param oldOracle Address of the old oracle
    /// @param newOracle Address of the new oracle
    event SetPriceOracle(address oldOracle, address newOracle);

    /// @notice Logs a change of senior rate model contract
    /// @param oldModel Address of the old model
    /// @param newModel Address of the new model
    event SetSeniorRateModel(address oldModel, address newModel);

    /// @notice Logs a change of accounting model contract
    /// @param oldModel Address of the old model
    /// @param newModel Address of the new model
    event SetAccountingModel(address oldModel, address newModel);

    /// @notice Logs a change of fees owner
    /// @param oldOwner Address of the old owner of fees
    /// @param newOwner Address of the new owner of fees
    event SetFeesOwner(address oldOwner, address newOwner);

    /// @notice Logs a change of fees percentage
    /// @param oldPercentage The old percentage of fees
    /// @param newPercentage The new percentage of fees
    event SetFeesPercentage(uint256 oldPercentage, uint256 newPercentage);
}