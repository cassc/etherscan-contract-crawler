// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IIndexHelper.sol";
import "./IIndexRouter.sol";

interface IIndexBettingViewer {
    ///@dev Prices are expressed in base aggregator decimals(8)
    struct Epoch {
        uint32 timestamp;
        uint112 PDIPrice;
        uint112 DPIPrice;
    }

    /// @notice Number of decimals in base asset answer
    /// @return Returns number of decimals in base asset answer
    function REWARD_TOKEN() external view returns (IERC20MetadataUpgradeable);

    /// @notice Number of decimals in base asset answer
    /// @return Returns number of decimals in base asset answer
    function STAKING_TOKEN() external view returns (IERC20MetadataUpgradeable);

    /// @notice Reward rate in basis point format [0 - 10_000] in case PDI outperforms DPI
    /// @return Returns rate in basis point format
    function VICTORY_REWARD_RATE() external view returns (uint16);

    /// @notice Reward rate in basis point format [0 - 10_000] in case DPI outperforms PDI
    /// @return Returns rate in basis point format
    function DEFEAT_REWARD_RATE() external view returns (uint16);

    /// @notice Address of indexRouter contract
    /// @return Returns address of indexRouter contract
    function INDEX_ROUTER() external view returns (IIndexRouter);

    /// @notice Address of the dpi price feed fro dpi/usd
    /// @return Returns address of the dpi price feed for dpi/usd
    function DPI_PRICE_FEED() external view returns (AggregatorV3Interface);

    /// @notice Address of indexHelper contract
    /// @return Returns address of indexHelper contract
    function INDEX_HELPER() external view returns (IIndexHelper);

    /// @notice Start of the betting challenge
    /// @return timestamp Returns timestamp at the start of the betting challenge
    /// @return PDIPrice Returns PDIPrice at the start of the betting challenge
    /// @return DPIPrice Returns DPIPrice at the start of the betting challenge
    function startEpoch() external view returns (uint32 timestamp, uint112 PDIPrice, uint112 DPIPrice);

    /// @notice End of the betting challenge
    /// @return timestamp Returns timestamp at the end of the betting challenge
    /// @return PDIPrice Returns PDIPrice at the end of the betting challenge
    /// @return DPIPrice Returns DPIPrice at the end of the betting challenge
    function endEpoch() external view returns (uint32 timestamp, uint112 PDIPrice, uint112 DPIPrice);

    /// @notice Duration of lockup period
    /// @dev Depositing isn't available during lockup period
    /// @return Returns Duration of lockup period
    function frontRunningLockupDuration() external view returns (uint32);

    /// @notice Maximum amount available for staking in staking token decimals
    /// @return Returns amount available for staking
    function maxStakingAmount() external view returns (uint128);

    /// @notice Reward rate settled at the end of the challenge
    /// @return Returns reward rate
    function PDIRewardRate() external view returns (uint16);

    /// @notice RoundId from dpi price feed in case there is no price update at the end of challenge
    /// @return Returns round id
    function DPIRoundID() external view returns (uint80);

    /// @notice Latest DPI price in base aggregator decimals
    /// @return Returns DPI price
    function getLatestDPIPrice() external view returns (uint112);

    /// @notice Latest PDI price in base aggregator decimals
    /// @return Returns PDI price
    function getLatestPDIPrice() external view returns (uint112);

    /// @notice Current reward rate in basis point format [0 - 10_000]
    /// @return Returns reward rate
    function getCurrentRewardRate() external view returns (uint16);

    /// @notice Current reward amount for user address
    /// @param _user Address of user to check reward amount for
    /// @return Returns reward amount
    function getCurrentRewardAmount(address _user) external view returns (uint256);

    /// @notice Total reward amount based on the amount of staked tokens
    /// @return Returns reward amount
    function getCurrentTotalRewardAmount() external view returns (uint256);

    /// @notice Total reward amount based on the amount of staked tokens and settled reward rate
    /// @return Returns total reward amount
    function getSettledTotalRewardAmount() external view returns (uint256);

    /// @notice Reward amount for user address based on the amount of staked tokens and settled reward rate
    /// @param _user Address of user to check reward amount for
    /// @return Returns reward amount
    function getSettledRewardAmount(address _user) external view returns (uint256);

    /// @notice Reward amount for any number of staked tokens and reward rate
    /// @param _amount Amount of staked tokens
    /// @param _PDIRewardRate Reward rate in basis point format [0 - 10_000]
    /// @return Returns reward amount
    function getReward(uint256 _amount, uint16 _PDIRewardRate) external view returns (uint256);
}