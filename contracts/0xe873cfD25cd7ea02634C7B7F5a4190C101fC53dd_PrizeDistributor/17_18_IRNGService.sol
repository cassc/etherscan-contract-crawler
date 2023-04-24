// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title Random Numbers Generator Interface
 * @notice Provides an interface for requesting random numbers from 3rd-party
 *         RNG services (Chainlink VRF, Starkware VDF, etc.).
 */
interface IRNGService {
    /**
     * @notice Emitted when a new request for a random numbers has been
     *         submitted.
     * @param requestId The indexed ID of the request used to get the results of
     *                  the RNG service
     * @param vrfRequestId A request ID from 3rd party random numbers provider
     * @param numWords An amount of random numbers to request
     * @param sender The indexed address of the sender of the request
     */
    event RandomNumbersRequested(
        uint32 indexed requestId,
        uint256 indexed vrfRequestId,
        uint32 numWords,
        address indexed sender
    );

    /**
     * @notice Emitted when an existing request for a random numbers has been
     *         completed.
     * @param requestId The indexed ID of the request used to get the results of
     *                  the RNG service
     * @param randomNumbers The random numbers produced by the 3rd-party service
     */
    event RandomNumbersCompleted(
        uint32 indexed requestId,
        uint256[] randomNumbers
    );

    /**
     * @notice Gets the last request ID used by the RNG service.
     * @return requestId The last request ID used in the last request
     */
    function getLastRequestId() external view returns (uint32 requestId);

    /**
     * @notice Gets the fee for making a request against an RNG service.
     * @return feeToken The address of the token that is used to pay fees
     * @return requestFee The fee required to be paid to make a request
     */
    function getRequestFee()
        external
        view
        returns (address feeToken, uint256 requestFee);

    /**
     * @notice Sends a request for a random numbers to the 3rd-party service.
     * @dev Some services will complete the request immediately, others may have
     *      a time-delay.
     * @dev Some services require payment in the form of a token, such as $LINK
     *      for Chainlink VRF.
     * @dev The calling contract should "lock" all activity until the result is
     *      available via the `requestId`.
     * @param numWords An amount of random numbers to request
     * @return requestId The ID of the request used to get the results of the
     *                   RNG service
     * @return lockBlock The block number at which the RNG service will start
     *                   generating time-delayed randomness
     */
    function requestRandomNumbers(
        uint32 numWords
    ) external returns (uint32 requestId, uint32 lockBlock);

    /**
     * @notice Checks if the request for randomness from the 3rd-party service
     *         has completed.
     * @dev For time-delayed requests, this function is used to check/confirm
     *      completion.
     * @param requestId The ID of the request used to get the results of the RNG
     *                  service
     * @return isCompleted `true` if the request has completed and a random
     *                     number is available, `false` otherwise
     */
    function isRequestCompleted(
        uint32 requestId
    ) external view returns (bool isCompleted);

    /**
     * @notice Gets an array of random numbers produced by the 3rd-party service.
     * @param requestId The ID of the request used to get the results of the RNG
     *                  service
     * @return numbers An array of random numbers
     */
    function getRandomNumbers(
        uint32 requestId
    ) external view returns (uint256[] memory numbers);
}