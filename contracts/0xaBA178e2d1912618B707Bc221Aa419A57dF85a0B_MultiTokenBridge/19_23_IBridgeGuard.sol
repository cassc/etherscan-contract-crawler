// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @title BridgeGuard contract interface
 * @author CloudWalk Inc.
 */
interface IBridgeGuard {
    /// @dev Accommodation guard settings for selected chain id and token are reset.
    event ResetAccommodationGuard(uint256 indexed chainId, address indexed token);

    /// @dev Accommodation guard settings for the token in selected chain id were configured.
    event ConfigureAccommodationGuard(
        uint256 indexed chainId,
        address indexed token,
        uint256 newTimeFrame,
        uint256 newVolumeLimit
    );

    /**
     * @dev Checks if the amount for accommodation fits in the cap by time frame.
     * @param sourceChainId The id of the chain that performs the accommodation.
     * @param token The address of the token to be accommodated.
     * @param account The user that requeted relocation.
     * @param amount The amount of tokens to be accommodated.
     * @return errorCode The status of the validation. See {IGuardBridgeTypes - ValidationStatus}
     */
    function validateAccommodation(
        uint256 sourceChainId,
        address token,
        address account,
        uint256 amount
    ) external returns (uint256 errorCode);

    /**
     * @dev Configures the accommodation guard for a selected chain and token.
     * @param chainId The id of the selected chain.
     * @param token The address of the selected token.
     * @param newTimeFrame The time frame for the accommodation volume limit calculating.
     * @param newVolumeLimit The new accommodation limit of tokens that is validated.
     */
    function configureAccommodationGuard(
        uint256 chainId,
        address token,
        uint256 newTimeFrame,
        uint256 newVolumeLimit
    ) external;
}