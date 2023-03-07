//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ILendingRegistry {
    // Maps wrapped token to protocol
    function wrappedToProtocol(address _wrapped) external view returns(bytes32);
    // Maps wrapped token to underlying
    function wrappedToUnderlying(address _wrapped) external view returns(address);
    function underlyingToProtocolWrapped(address _underlying, bytes32 protocol) external view returns (address);
    function protocolToLogic(bytes32 _protocol) external view returns (address);

    /**
        @notice Set which protocl a wrapped token belongs to
        @param _wrapped Address of the wrapped token
        @param _protocol Bytes32 key of the protocol
    */
    function setWrappedToProtocol(address _wrapped, bytes32 _protocol) external;

    /**
        @notice Set what is the underlying for a wrapped token
        @param _wrapped Address of the wrapped token
        @param _underlying Address of the underlying token
    */
    function setWrappedToUnderlying(address _wrapped, address _underlying) external;

    /**
        @notice Set the logic contract for the protocol
        @param _protocol Bytes32 key of the procol
        @param _logic Address of the lending logic contract for that protocol
    */
    function setProtocolToLogic(bytes32 _protocol, address _logic) external;
    /**
        @notice Set the wrapped token for the underlying deposited in this protocol
        @param _underlying Address of the unerlying token
        @param _protocol Bytes32 key of the protocol
        @param _wrapped Address of the wrapped token
    */
    function setUnderlyingToProtocolWrapped(address _underlying, bytes32 _protocol, address _wrapped) external;

    /**
        @notice Get tx data to lend the underlying amount in a specific protocol
        @param _underlying Address of the underlying token
        @param _amount Amount to lend
        @param _protocol Bytes32 key of the protocol
        @return targets Addresses of the src to call
        @return data Calldata for the calls
    */
    function getLendTXData(address _underlying, uint256 _amount, bytes32 _protocol) external view returns(address[] memory targets, bytes[] memory data);

    /**
        @notice Get the tx data to unlend the wrapped amount
        @param _wrapped Address of the wrapped token
        @param _amount Amount of wrapped token to unlend
        @return targets Addresses of the src to call
        @return data Calldata for the calls
    */
    function getUnlendTXData(address _wrapped, uint256 _amount) external view returns(address[] memory targets, bytes[] memory data);
}