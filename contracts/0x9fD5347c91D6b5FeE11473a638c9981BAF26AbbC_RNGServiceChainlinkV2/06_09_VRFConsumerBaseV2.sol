// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice Interface for contracts using VRF randomness.
 */
abstract contract VRFConsumerBaseV2 is Initializable {
    /* =============== Errors =============== */

    error OnlyCoordinatorCanFulfill(address have, address want);

    /* ========== Global Variables ========== */

    address private vrfCoordinator;

    /* ============ Constructor ============= */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    /* ============== External ============== */

    /**
     * @notice Is called by VRFCoordinator when it receives a valid VRF proof.
     * Then calls `fulfillRandomness`, after validating the origin of the call.
     */
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }

        fulfillRandomWords(requestId, randomWords);
    }

    /* ============== Internal ============== */

    /**
     * @notice Unchained initialization of VRFCinsumerBaseV2 contract.
     * @param _vrfCoordinator An initial VRF Coordinator contract address
     */
    function __VRFConsumerBaseV2_init_unchained(
        address _vrfCoordinator
    ) internal onlyInitializing {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice Handles the VRF response.
     * @param requestId The ID initially returned by `requestRandomWords`
     * @param randomWords The VRF output expanded to the requested number of
     *                    words
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual;

    uint256[50] private __gap;
}