// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IInscription inscription receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from IInscription asset contracts.
 */
interface IInscriptionReceiver {
    /**
     * @dev Whenever an {IInscription} `inscriptionId` inscription is transferred to this contract via {IInscription-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the inscription transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IInscriptionReceiver.onInscriptionReceived.selector`.
     */
    function onInscriptionReceived(
        address operator,
        address from,
        uint256 inscriptionId,
        bytes calldata data
    ) external returns (bytes4);
}