// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

interface IBSH {
    /**
     @notice BSH handle BTP Message from BMC contract
     @dev Caller must be BMC contract only
     @param _from    An originated network address of a request
     @param _svc     A service name of BSH contract     
     @param _sn      A serial number of a service request 
     @param _msg     An RLP message of a service request/service response
    */
    function handleBTPMessage(
        string calldata _from,
        string calldata _svc,
        uint256 _sn,
        bytes calldata _msg
    ) external;

    /**
     @notice BSH handle BTP Error from BMC contract
     @dev Caller must be BMC contract only 
     @param _svc     A service name of BSH contract     
     @param _sn      A serial number of a service request 
     @param _code    A response code of a message (RC_OK / RC_ERR)
     @param _msg     A response message
    */
    function handleBTPError(
        string calldata _src,
        string calldata _svc,
        uint256 _sn,
        uint256 _code,
        string calldata _msg
    ) external;

    /**
     @notice BSH handle Gather Fee Message request from BMC contract
     @dev Caller must be BMC contract only
     @param _fa     A BTP address of fee aggregator
     @param _svc    A name of the service
    */
    function handleFeeGathering(string calldata _fa, string calldata _svc)
        external;
}