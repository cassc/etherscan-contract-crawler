// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

/**
 * @title The interface for Silica
 * @author Alkimiya Team
 * @notice A Silica contract lists hashrate for sale
 * @dev The Silica interface is broken up into smaller interfaces
 */
interface ISilicaV2_1 {
    /*///////////////////////////////////////////////////////////////
                                 Events
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed buyer, uint256 purchaseAmount, uint256 mintedTokens);
    event BuyerCollectPayout(uint256 rewardTokenPayout, uint256 paymentTokenPayout, address buyerAddress, uint256 burntAmount);
    event SellerCollectPayout(uint256 paymentTokenPayout, uint256 rewardTokenExcess);
    event StatusChanged(SilicaV2_1Types.Status status);

    struct InitializeData {
        address rewardTokenAddress;
        address paymentTokenAddress;
        address oracleRegistry;
        address sellerAddress;
        uint256 dayOfDeployment;
        uint256 lastDueDay;
        uint256 unitPrice;
        uint256 resourceAmount;
        uint256 collateralAmount;
    }

    /// @notice Returns the amount of rewards the seller must have delivered before next update
    /// @return rewardDueNextOracleUpdate amount of rewards the seller must have delivered before next update
    function getRewardDueNextOracleUpdate() external view returns (uint256);

    /// @notice Initializes the contract
    /// @param initializeData is the address of the token the seller is selling
    function initialize(InitializeData memory initializeData) external;

    /// @notice Function called by buyer to deposit payment token in the contract in exchange for Silica tokens
    /// @param amountSpecified is the amount that the buyer wants to deposit in exchange for Silica tokens
    function deposit(uint256 amountSpecified) external returns (uint256);

    /// @notice Called by the swapProxy to make a deposit in the name of a buyer
    /// @param _to the address who should receive the Silica Tokens
    /// @param amountSpecified is the amount the swapProxy is depositing for the buyer in exchange for Silica tokens
    function proxyDeposit(address _to, uint256 amountSpecified) external returns (uint256);

    /// @notice Function the buyer calls to collect payout when the contract status is Finished
    function buyerCollectPayout() external returns (uint256 rewardTokenPayout);

    /// @notice Function the buyer calls to collect payout when the contract status is Defaulted
    function buyerCollectPayoutOnDefault() external returns (uint256 rewardTokenPayout, uint256 paymentTokenPayout);

    /// @notice Function the seller calls to collect payout when the contract status is Finised
    function sellerCollectPayout() external returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);

    /// @notice Function the seller calls to collect payout when the contract status is Defaulted
    function sellerCollectPayoutDefault() external returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);

    /// @notice Function the seller calls to collect payout when the contract status is Expired
    function sellerCollectPayoutExpired() external returns (uint256 rewardTokenPayout);

    /// @notice Returns the owner of this Silica
    /// @return address: owner address
    function getOwner() external view returns (address);

    /// @notice Returns the Payment Token accepted in this Silica
    /// @return Address: Token Address
    function getPaymentToken() external view returns (address);

    /// @notice Returns the rewardToken address. The rewardToken is the token fo wich are made the rewards the seller is selling
    /// @return The rewardToken address. The rewardToken is the token fo wich are made the rewards the seller is selling
    function getRewardToken() external view returns (address);

    /// @notice Returns the last day of reward the seller is selling with this contract
    /// @return The last day of reward the seller is selling with this contract
    function getLastDueDay() external view returns (uint32);

    /// @notice Returns the commodity type the seller is selling with this contract
    /// @return The commodity type the seller is selling with this contract
    function getCommodityType() external pure returns (uint8);

    /// @notice Get the current status of the contract
    /// @return status: The current status of the contract
    function getStatus() external view returns (SilicaV2_1Types.Status);

    /// @notice Returns the day of default.
    /// @return day: The day the contract defaults
    function getDayOfDefault() external view returns (uint256);

    /// @notice Returns true if contract is in Open status
    function isOpen() external view returns (bool);

    /// @notice Returns true if contract is in Running status
    function isRunning() external view returns (bool);

    /// @notice Returns true if contract is in Expired status
    function isExpired() external view returns (bool);

    /// @notice Returns true if contract is in Defaulted status
    function isDefaulted() external view returns (bool);

    /// @notice Returns true if contract is in Finished status
    function isFinished() external view returns (bool);

    /// @notice Returns amount of rewards delivered so far by contract
    function getRewardDeliveredSoFar() external view returns (uint256);

    /// @notice Returns the most recent day the contract owes in rewards
    /// @dev The returned value does not indicate rewards have been fulfilled up to that day
    /// This only returns the most recent day the contract should deliver rewards
    function getLastDayContractOwesReward(uint256 lastDueDay, uint256 lastIndexedDay) external view returns (uint256);

    /// @notice Returns the reserved price of the contract
    function getReservedPrice() external view returns (uint256);

    /// @notice Returns decimals of the contract
    function getDecimals() external pure returns (uint8);
}