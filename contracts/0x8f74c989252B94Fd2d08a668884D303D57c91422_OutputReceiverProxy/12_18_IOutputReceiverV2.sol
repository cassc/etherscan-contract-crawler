// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IOutputReceiver.sol";
import "./IRevest.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';


/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiverV2 is IOutputReceiver {

    // Future proofing for secondary callbacks during withdrawal
    // Could just use triggerOutputReceiverUpdate and call withdrawal function
    // But deliberately using reentry is poor form and reminds me too much of OAuth 2.0 
    function receiveSecondaryCallback(
        uint fnftId,
        address payable owner,
        uint quantity,
        IRevest.FNFTConfig memory config,
        bytes memory args
    ) external payable;

    // Allows for similar function to address lock, updating state while still locked
    // Called by the user directly
    function triggerOutputReceiverUpdate(
        uint fnftId,
        bytes memory args
    ) external;

    // This function should only ever be called when a split or additional deposit has occurred 
    function handleFNFTRemaps(uint fnftId, uint[] memory newFNFTIds, address caller, bool cleanup) external;

}