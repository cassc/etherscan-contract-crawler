// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/utils/Context.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "src/interfaces/IProofOfHumanityProxy.sol";
import "src/interfaces/IStarkNetMessaging.sol";

contract ProofOfHumanityStarkNetBridge is Context, Ownable {
    /// EVENTS

    /** @dev Emitted when the registration to L2 has been triggered.
     *  @param _submissionID The ID of the submission.
     *  @param _l2RecipientAddress The recipient address on L2.
     *  @param _timestamp The timestamp when the L2 registration has been triggered.
     */
    event L2RegistrationTriggered(
        address indexed _submissionID,
        uint256 _l2RecipientAddress,
        uint256 _timestamp
    );

    /// ERRORS

    /** @dev Thrown when the address of the sender is not registered on proof of humanity protocol.
     *  @param submissionID The ID of the submission.
     */
    error NotRegistered(address submissionID);
    /** @dev Thrown when the L2 parameters are not set.
     */
    error L2ParametersNotSet();

    /// STORAGE

    // Address of ProofOfHumanity proxy contract
    IProofOfHumanityProxy private _pohProxy;
    // Address of StarkNetMessaging contract
    IStarkNetMessaging private _starkNetMessaging;
    // Address of ProofOfHumanity registry contract on L2
    uint256 private _l2ProofOfHumanityRegistryContract;
    // Selector of register function
    uint256 private _registerSelector;

    /// MODIFIERS
    modifier onlyIfL2ParametersSet() {
        if (_l2ProofOfHumanityRegistryContract == 0 || _registerSelector == 0) {
            revert L2ParametersNotSet();
        }
        _;
    }

    /** @dev Constructor.
     *  @param pohProxy_ The address of the ProofOfHumanity proxy contract.
     *  @param starkNetMessaging_ The address of the StarkNetMessaging contract.
     */
    constructor(address pohProxy_, address starkNetMessaging_) {
        _pohProxy = IProofOfHumanityProxy(pohProxy_);
        _starkNetMessaging = IStarkNetMessaging(starkNetMessaging_);
    }

    /** @dev Configure L2 specific parameters.
     *  @param l2ProofOfHumanityRegistryContract_ The address of ProofOfHumanity registry contract on L2.
     *  @param registerSelector_ The selector of register function.
     */
    function configureL2Parameters(
        uint256 l2ProofOfHumanityRegistryContract_,
        uint256 registerSelector_
    ) public onlyOwner {
        require(
            _l2ProofOfHumanityRegistryContract == 0 && _registerSelector == 0,
            "ProofOfHumanityStarkNetBridge: L2 parameters can be set only once"
        );
        _l2ProofOfHumanityRegistryContract = l2ProofOfHumanityRegistryContract_;
        _registerSelector = registerSelector_;
    }

    /** @dev Register the submission on L2 if it is registered on L1.
     *  @param l2RecipientAddress The L2 address to associate the registration with.
     */
    function registerToL2(uint256 l2RecipientAddress)
        public
        onlyIfL2ParametersSet
    {
        // Get sender address
        address sender = _msgSender();
        // Check if address is registered
        bool isRegistered = _pohProxy.isRegistered(sender);
        if (!isRegistered) {
            revert NotRegistered({submissionID: sender});
        }

        // Get current timestamp
        uint256 registrationTimestamp = block.timestamp;

        // Build message payload
        uint256[] memory payload = new uint256[](3);
        payload[0] = uint256(uint160(sender));
        payload[1] = l2RecipientAddress;
        payload[2] = registrationTimestamp;

        // Send message to L2
        _starkNetMessaging.sendMessageToL2(
            _l2ProofOfHumanityRegistryContract,
            _registerSelector,
            payload
        );

        emit L2RegistrationTriggered(
            sender,
            l2RecipientAddress,
            registrationTimestamp
        );
    }
}