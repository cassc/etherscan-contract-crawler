// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../access/IOwnable.sol";

/**
 * @dev External interface of Oracle declared to support ERC165 detection.
 */
interface IOracle is IOwnable, IERC165 {
    // Events

    /**
    * @notice Emits when a new oracle report (Merkle root) recorded
    * @param _root Merkle root
    */
    event Reported(bytes32 indexed _root);

    // Functions

    /**
    * @notice Set a new oracle report (Merkle root)
    * @param _root Merkle root
    */
    function report(bytes32 _root) external;

    /**
    * @notice Verify Merkle proof (that the leaf belongs to the tree)
    * @param _proof Merkle proof (the leaf's sibling, and each non-leaf hash that could not otherwise be calculated without additional leaf nodes)
    * @param _firstValidatorId Validator Id (number of all deposits previously made to ETH2 DepositContract plus 1)
    * @param _validatorCount (number of validators corresponding to a given FeeDistributor instance, equal to the number of ETH2 deposits made with 1 P2pEth2Depositor's deposit)
    * @param _amountInGwei total CL rewards earned by all validators in GWei (see _validatorCount)
    */
    function verify(
        bytes32[] calldata _proof,
        uint64 _firstValidatorId,
        uint16 _validatorCount,
        uint256 _amountInGwei
    ) external view;
}