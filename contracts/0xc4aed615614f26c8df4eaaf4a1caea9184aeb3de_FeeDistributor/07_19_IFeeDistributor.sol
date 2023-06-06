// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
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

    /**
    * @dev 256bits-wide structure to store clientOnlyClRewards, firstValidatorId, and validatorCount
     */
    struct ValidatorData {
        /**
        * @notice amount of CL rewards (in Wei) that should belong to the client only
        * and should not be considered for splitting between the service and the referrer
        */
        uint176 clientOnlyClRewards;

        /**
        * @notice Validator Id (number of all deposits previously made to ETH2 DepositContract plus 1)
        */
        uint64 firstValidatorId;

        /**
        * @notice Number of validators corresponding to a given FeeDistributor instance, equal to the number of ETH2 deposits made with 1 P2pEth2Depositor's deposit
        */
        uint16 validatorCount;
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
    * @param _validatorData clientOnlyClRewards, firstValidatorId, and validatorCount
    */
    function initialize(
        FeeRecipient calldata _clientConfig,
        FeeRecipient calldata _referrerConfig,
        ValidatorData calldata _validatorData
    ) external;

    /**
    * @notice Withdraw the whole balance of the contract according to the pre-defined basis points.
    * @dev In case someone (either service, or client, or referrer) fails to accept ether,
    * the owner will be able to recover some of their share.
    * This scenario is very unlikely. It can only happen if that someone is a contract
    * whose receive function changed its behavior since FeeDistributor's initialization.
    * It can never happen unless the receiving party themselves wants it to happen.
    * We strongly recommend against intentional reverts in the receive function
    * because the remaining parties might call `withdraw` again multiple times without waiting
    * for the owner to recover ether for the reverting party.
    * In fact, as a punishment for the reverting party, before the recovering,
    * 1 more regular `withdraw` will happen, rewarding the non-reverting parties again.
    * `recoverEther` function is just an emergency backup plan and does not replace `withdraw`.
    *
    * @param _proof Merkle proof (the leaf's sibling, and each non-leaf hash that could not otherwise be calculated without additional leaf nodes)
    * @param _amount total CL rewards earned by all validators (see _validatorCount)
    */
    function withdraw(
        bytes32[] calldata _proof,
        uint256 _amount
    ) external;

    /**
     * @dev Returns the factory address
     */
    function factory() external view returns (address);

    /**
     * @dev Returns the service address
     */
    function service() external view returns (address);

    /**
     * @dev Returns the client address
     */
    function client() external view returns (address);

    /**
     * @dev Returns the client basis points
     */
    function clientBasisPoints() external view returns (uint256);

    /**
    * @dev Returns the referrer address
     */
    function referrer() external view returns (address);

    /**
     * @dev Returns the referrer basis points
     */
    function referrerBasisPoints() external view returns (uint256);

    /**
    * @dev Returns First Validator Id
    */
    function firstValidatorId() external view returns (uint256);

    /**
    * @dev Returns a portion of CL rewards that should not be counted during withdraw (belongs to client only)
    */
    function clientOnlyClRewards() external view returns (uint256);

    /**
    * @dev Returns validator count
    */
    function validatorCount() external view returns (uint256);
}