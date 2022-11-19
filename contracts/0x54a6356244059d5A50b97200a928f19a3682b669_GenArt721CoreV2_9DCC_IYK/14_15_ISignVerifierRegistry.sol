// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin-4.5/contracts/utils/introspection/IERC165.sol";

interface ISignVerifierRegistry is IERC165 {
    /**
     * @notice Emitted upon the registration of `signVerifier` to a previously unregistered ID `id`.
     */
    event Register(bytes32 id, address signVerifier);

    /**
     * @notice Emitted upon the update of `signVerifier` to a previously unregistered ID `id`, replacing `oldSignVerifier`.
     */
    event Update(bytes32 id, address signVerifier, address oldSignVerifier);

    /**
     * @notice Registers `signVerifier` to `id`, with the registrant set as the admin of `id`.
     * @dev Does not allow updating of an existing ID, or registering an ID that matches the admin role.
     */
    function register(bytes32 id, address signVerifier) external;

    /**
     * @notice Updates the sign verifier for `id` to `signVerifier`.
     * @dev Allows for the signVerifier to be the zero address, which can be dangerous but is a way of invalidating signatures en masse if required.
     */
    function update(bytes32 id, address signVerifier) external;

    /**
     * @notice Returns the address of the sign verifier registered to `id`.
     * @dev Reverts if `id` has not been registered yet
     */
    function get(bytes32 id) external view returns (address);
}