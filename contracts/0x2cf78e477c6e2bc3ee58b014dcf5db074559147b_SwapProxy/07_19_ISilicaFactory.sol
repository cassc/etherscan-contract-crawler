// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ISilicaFactoryEvents.sol";

/**
 * @title Interface for Silica Account for ERC20 assets
 * @author Alkimiya team
 * @notice This class needs to be inherited
 */
interface ISilicaFactory is ISilicaFactoryEvents {
    /// @notice Creates a SilicaV2_1 contract
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount hashrate the seller is selling
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of gH/day
    /// @return address: The address of the contract created
    function createSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice
    ) external returns (address);

    /// @notice Creates a SilicaV2_1 contract from SwapProxy
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount hashrate the seller is selling
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of gH/day
    /// @param _sellerAddress the seller address
    /// @param _additionalCollateralPercent - added on top of base 10%,
    ///        e.g. if `additionalCollateralPercent = 20` then seller will
    ///        put 30% collateral.
    /// @return address: The address of the contract created
    function proxyCreateSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress,
        uint256 _additionalCollateralPercent
    ) external returns (address);

    /// @notice Creates a EthStaking contract
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount Amount of token staked generating the rewards beeing sold by the seller with this contract
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of stakedToken/day
    /// @return address: The address of the contract created
    function createEthStakingSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice
    ) external returns (address);

    /// @notice Creates a EthStaking contract from SwapProxy
    /// @param _rewardTokenAddress The address of the token of the rewards beeing sold by the seller
    /// @param _paymentTokenAddress address of the token that can be used to buy silica from this contract
    /// @param _resourceAmount Amount of token staked generating the rewards beeing sold by the seller with this contract
    /// @param _lastDueDay the last day of rewards the seller is selling
    /// @param _unitPrice the price of stakedToken/day
    /// @param _sellerAddress the seller address
    /// @param _additionalCollateralPercent - added on top of base 10%,
    ///        e.g. if `additionalCollateralPercent = 20` then seller will
    ///        put 30% collateral.
    /// @return address: The address of the contract created
    function proxyCreateEthStakingSilicaV2_1(
        address _rewardTokenAddress,
        address _paymentTokenAddress,
        uint256 _resourceAmount,
        uint256 _lastDueDay,
        uint256 _unitPrice,
        address _sellerAddress,
        uint256 _additionalCollateralPercent
    ) external returns (address);

    /// @notice Function to return the Collateral requirement for issuance for a new Mining Swap Silica
    function getMiningSwapCollateralRequirement(
        uint256 lastDueDay,
        uint256 hashrate,
        address rewardTokenAddress
    ) external view returns (uint256);

    /// @notice Function to return the Collateral requirement for issuance for a new Staking Swap Silica
    function getEthStakingCollateralRequirement(
        uint256 lastDueDay,
        uint256 stakedAmount,
        address rewardTokenAddress,
        uint8 decimals
    ) external view returns (uint256);
}