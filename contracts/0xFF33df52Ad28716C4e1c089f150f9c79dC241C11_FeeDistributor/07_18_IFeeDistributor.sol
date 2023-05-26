// SPDX-FileCopyrightText: 2022 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev External interface of FeeDistributor declared to support ERC165 detection.
 */
interface IFeeDistributor is IERC165 {

    /**
     * @dev 256bits-wide structure to store recipient address along with its basisPoints
     */
    struct FeeRecipient {
        /**
        * @notice basis points (percent * 100) of EL rewards that should go to the recipient
        */
        uint96 basisPoints;

        /**
        * @notice address of the recipient
        */
        address payable recipient;
    }

    // Events

    /**
    * @notice Emits on successful withdrawal
    * @param _serviceAmount how much wei service received
    * @param _clientAmount how much wei client received
    * @param _referrerAmount how much wei referrer received
    */
    event Withdrawn(uint256 _serviceAmount, uint256 _clientAmount, uint256 _referrerAmount);

    /**
    * @notice Emits once the client and the optional referrer have been set.
    * @param _client address of the client.
    * @param _clientBasisPoints basis points (percent * 100) of EL rewards that should go to the client
    * @param _referrer address of the referrer.
    * @param _referrerBasisPoints basis points (percent * 100) of EL rewards that should go to the referrer
    */
    event Initialized(
        address indexed _client,
        uint96 _clientBasisPoints,
        address indexed _referrer,
        uint96 _referrerBasisPoints
    );

    /**
    * @notice Emits if case there was some ether left after `withdraw` and it has been sent successfully.
    * @param _to destination address for ether.
    * @param _amount how much wei the destination address received.
    */
    event EtherRecovered(address indexed _to, uint256 _amount);

    /**
    * @notice Emits if case there was some ether left after `withdraw` and it has failed to recover.
    * @param _to destination address for ether.
    * @param _amount how much wei the destination address should have received, but didn't.
    */
    event EtherRecoveryFailed(address indexed _to, uint256 _amount);

    // Functions

    /**
    * @notice Set client address.
    * @dev Could not be in the constructor since it is different for different clients.
    * @dev _referrerConfig can be zero if there is no referrer.
    * @param _clientConfig address and basis points (percent * 100) of the client
    * @param _referrerConfig address and basis points (percent * 100) of the referrer.
    */
    function initialize(FeeRecipient calldata _clientConfig, FeeRecipient calldata _referrerConfig) external;

    /**
    * @notice Withdraw the whole balance of the contract according to the pre-defined percentages.
    */
    function withdraw() external;

    /**
     * @dev Returns the factory address
     */
    function getFactory() external view returns (address);

    /**
     * @dev Returns the service address
     */
    function getService() external view returns (address);

    /**
     * @dev Returns the client address
     */
    function getClient() external view returns (address);

    /**
     * @dev Returns the client basis points
     */
    function getClientBasisPoints() external view returns (uint256);
}