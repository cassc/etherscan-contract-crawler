// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../access/IOwnable.sol";
import "../feeDistributor/IFeeDistributor.sol";

/**
 * @dev External interface of FeeDistributorFactory declared to support ERC165 detection.
 */
interface IFeeDistributorFactory is IOwnable, IERC165 {
    // Events

    /**
    * @notice Emits when a new FeeDistributor instance has been created for a client
    * @param _newFeeDistributorAddress address of the newly created FeeDistributor contract instance
    * @param _clientAddress address of the client for whom the new instance was created
    */
    event FeeDistributorCreated(address indexed _newFeeDistributorAddress, address indexed _clientAddress);

    /**
    * @notice Emits when a new FeeDistributor contract address has been set as a reference instance.
    * @param _referenceFeeDistributor the address of the new reference implementation contract
    */
    event ReferenceInstanceSet(address indexed _referenceFeeDistributor);

    /**
    * @notice Emits when a new P2pEth2Depositor contract address has been set.
    * @param _p2pEth2Depositor the address of the new P2pEth2Depositor contract
    */
    event P2pEth2DepositorSet(address indexed _p2pEth2Depositor);

    // Functions

    /**
    * @notice Set a new reference implementation of FeeDistributor contract
    * @param _referenceFeeDistributor the address of the new reference implementation contract
    */
    function setReferenceInstance(address _referenceFeeDistributor) external;

    /**
    * @notice Creates a FeeDistributor instance for a client
    * @dev Emits `FeeDistributorCreated` event with the address of the newly created instance
    * @dev _referrerConfig can be zero if there is no referrer.
    * @param _clientConfig address and basis points (percent * 100) of the client
    * @param _referrerConfig address and basis points (percent * 100) of the referrer.
    * @param _validatorData clientOnlyClRewards, firstValidatorId, and validatorCount
    * @return newFeeDistributorAddress user FeeDistributor instance that has just been deployed
    */
    function createFeeDistributor(
        IFeeDistributor.FeeRecipient calldata _clientConfig,
        IFeeDistributor.FeeRecipient calldata _referrerConfig,
        IFeeDistributor.ValidatorData calldata _validatorData
    ) external returns (address newFeeDistributorAddress);

    /**
     * @dev Returns the reference FeeDistributor contract address
     */
    function getReferenceFeeDistributor() external view returns (address);
}