// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "../libraries/Types.sol";

interface IBMCPeriphery {
    /**
        @notice Get BMC BTP address
     */
    function getBmcBtpAddress() external view returns (string memory);

    /**
        @notice Verify and decode RelayMessage with BMV, and dispatch BTP Messages to registered BSHs
        @dev Caller must be a registered relayer.     
        @param _prev    BTP Address of the BMC generates the message
        @param _msg     base64 encoded string of serialized bytes of Relay Message refer RelayMessage structure
     */
    function handleRelayMessage(string calldata _prev, string calldata _msg)
        external;

    /**
        @notice Send the message to a specific network.
        @dev Caller must be an registered BSH.
        @param _to      Network Address of destination network
        @param _svc     Name of the service
        @param _sn      Serial number of the message, it should be positive
        @param _msg     Serialized bytes of Service Message
     */
    function sendMessage(
        string calldata _to,
        string calldata _svc,
        uint256 _sn,
        bytes calldata _msg
    ) external;

    /*
        @notice Get status of BMC.
        @param _link        BTP Address of the connected BMC
        @return _linkStats  The link status
     */
    function getStatus(string calldata _link)
        external
        view
        returns (Types.LinkStats memory _linkStats);
}