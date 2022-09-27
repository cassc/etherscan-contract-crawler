// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @title IERC20Bridgeable interface
 * @dev The interface of a token that supports the bridge operations.
 */
interface IERC20Bridgeable {
    /// @dev Emitted when a minting is performed as part of a bridge operation.
    event MintForBridging(address indexed account, uint256 amount);

    /// @dev Emitted when a burning is performed as part of a bridge operation.
    event BurnForBridging(address indexed account, uint256 amount);

    /**
     * @dev Mints tokens as part of a bridge operation.
     *
     * It is expected that this function can be called only by a bridge contract.
     *
     * Emits a {MintForBridging} event.
     *
     * @param account The owner of the tokens passing through the bridge.
     * @param amount The amount of tokens passing through the bridge.
     * @return True if the operation was successful.
     */
    function mintForBridging(address account, uint256 amount) external returns (bool);

    /**
     * @dev Burns tokens as part of a bridge operation.
     *
     * It is expected that this function can be called only by a bridge contract.
     *
     * Emits a {BurnForBridging} event.
     *
     * @param account The owner of the tokens passing through the bridge.
     * @param amount The amount of tokens passing through the bridge.
     * @return True if the operation was successful.
     */
    function burnForBridging(address account, uint256 amount) external returns (bool);

    /**
     * @dev Checks whether a bridge is supported by the token or not.
     * @param bridge The address of the bridge to check.
     * @return True if the bridge is supported by the token.
     */
    function isBridgeSupported(address bridge) external view returns (bool);

    /**
     * @dev Checks whether the token supports the bridge operations by implementing this interface.
     * @return True in any case.
     */
    function isIERC20Bridgeable() external view returns (bool);
}