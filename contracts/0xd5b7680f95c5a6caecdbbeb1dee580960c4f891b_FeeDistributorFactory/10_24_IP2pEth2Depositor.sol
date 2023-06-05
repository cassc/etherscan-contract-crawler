// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../feeDistributor/IFeeDistributor.sol";

/**
 * @dev External interface of P2pEth2Depositor declared to support ERC165 detection.
 */
interface IP2pEth2Depositor is IERC165 {
    // Events

    /**
    * @notice Emits when a new batch deposit has been made successfully
    * @param _from the address of the depositor
    * @param _newFeeDistributorAddress user FeeDistributor instance that has just been deployed
    * @param _firstValidatorId validator Id (number of all deposits previously made to ETH2 DepositContract plus 1)
    * @param _validatorCount number of ETH2 deposits made with 1 P2pEth2Depositor's deposit
    */
    event P2pEth2DepositEvent(
        address indexed _from,
        address indexed _newFeeDistributorAddress,
        uint64 indexed _firstValidatorId,
        uint256 _validatorCount
    );

    /**
     * @dev Function that allows to deposit up to 1000 nodes at once.
     *
     * - pubkeys                - Array of BLS12-381 public keys.
     * - withdrawal_credentials - Array of commitments to a public keys for withdrawals.
     * - signatures             - Array of BLS12-381 signatures.
     * - deposit_data_roots     - Array of the SHA-256 hashes of the SSZ-encoded DepositData objects.
     */
    function deposit(
        bytes[] calldata pubkeys,
        bytes calldata withdrawal_credentials, // 1, same for all
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots,
        IFeeDistributor.FeeRecipient calldata _clientConfig,
        IFeeDistributor.FeeRecipient calldata _referrerConfig
    ) external payable;
}