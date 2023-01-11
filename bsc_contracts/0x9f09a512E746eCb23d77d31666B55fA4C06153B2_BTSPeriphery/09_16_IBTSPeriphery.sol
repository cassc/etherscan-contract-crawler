// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./IBSH.sol";

/**
   @title Interface of BTSPeriphery contract
   @dev This contract is used to handle communications among BMCService and BTSCore contract
*/
interface IBTSPeriphery is IBSH {
    /**
     @notice Check whether BTSPeriphery has any pending transferring requests
     @return true or false
    */
    function hasPendingRequest() external view returns (bool);

    /**
     @notice Send Service Message from BTSCore contract to BMCService contract
     @dev Caller must be BTSCore only
     @param _to             A network address of destination chain
     @param _coinNames      A list of coin name that are requested to transfer  
     @param _values         A list of an amount to receive at destination chain respectively with its coin name
     @param _fees           A list of an amount of charging fee respectively with its coin name 
    */
    function sendServiceMessage(
        address _from,
        string calldata _to,
        string[] memory _coinNames,
        uint256[] memory _values,
        uint256[] memory _fees
    ) external;

    /** */
    function setTokenLimit(
        string[] memory _coinNames,
        uint256[] memory _tokenLimits
    ) external;
    /**
     @notice BSH handle BTP Message from BMC contract
     @dev Caller must be BMC contract only
     @param _from    An originated network address of a request
     @param _svc     A service name of BTSPeriphery contract     
     @param _sn      A serial number of a service request 
     @param _msg     An RLP message of a service request/service response
    */
    function handleBTPMessage(
        string calldata _from,
        string calldata _svc,
        uint256 _sn,
        bytes calldata _msg
    ) external override;

    /**
     @notice BSH handle BTP Error from BMC contract
     @dev Caller must be BMC contract only 
     @param _svc     A service name of BTSPeriphery contract     
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
    ) external override;

    /**
     @notice BSH handle Gather Fee Message request from BMC contract
     @dev Caller must be BMC contract only
     @param _fa     A BTP address of fee aggregator
     @param _svc    A name of the service
    */
    function handleFeeGathering(string calldata _fa, string calldata _svc)
        external
        override;

    /**
        @notice Check if transfer is restricted
        @param _coinName    Name of the coin
        @param _user        Address to transfer from
        @param _value       Amount to transfer
    */
    function checkTransferRestrictions(
        string memory _coinName,
        address _user,
        uint256 _value
    ) external;

}