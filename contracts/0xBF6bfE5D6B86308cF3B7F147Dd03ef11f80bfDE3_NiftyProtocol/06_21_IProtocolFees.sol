pragma solidity ^0.8.4;


interface IProtocolFees {

    // Logs updates to the protocol fee multiplier.
    event ProtocolFeeMultiplier(uint256 oldProtocolFeeMultiplier, uint256 updatedProtocolFeeMultiplier);

    // Logs updates to the protocol fixed fee.
    event ProtocolFixedFee(uint256 oldProtocolFixedFee, uint256 updatedProtocolFixedFee);

    // Logs updates to the protocolFeeCollector address.
    event ProtocolFeeCollectorAddress(address oldProtocolFeeCollector, address updatedProtocolFeeCollector);

    /// @dev Allows the owner to update the protocol fee multiplier.
    /// @param updatedProtocolFeeMultiplier The updated protocol fee multiplier.
    function setProtocolFeeMultiplier(uint256 updatedProtocolFeeMultiplier) external;

    /// @dev Allows the owner to update the protocol fixed fee.
    /// @param fixedProtocolFee The updated protocol fixed fee.
    function setProtocolFixedFee(uint256 fixedProtocolFee) external;

    /// @dev Allows the owner to update the protocolFeeCollector address.
    /// @param updatedProtocolFeeCollector The updated protocolFeeCollector contract address.
    function setProtocolFeeCollectorAddress(address updatedProtocolFeeCollector) external;
}