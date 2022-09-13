pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IProtocolFees.sol";


contract ProtocolFees is
    IProtocolFees,
    Ownable
{
    /// @dev The protocol fee multiplier -- the owner can update this field.
    /// @return 0 Gas multplier.
    uint256 public protocolFeeMultiplier;

    /// @dev The protocol fixed fee multiplier -- the owner can update this field.
    /// @return 0 fixed fee.
    uint256 public protocolFixedFee;

    /// @dev The address of the registered protocolFeeCollector contract -- the owner can update this field.
    /// @return 0 Contract to forward protocol fees to.
    address public protocolFeeCollector;

    /// @dev Allows the owner to update the protocol fee multiplier.
    /// @param updatedProtocolFeeMultiplier The updated protocol fee multiplier.
    function setProtocolFeeMultiplier(uint256 updatedProtocolFeeMultiplier)
        override
        external
        onlyOwner
    {
        emit ProtocolFeeMultiplier(protocolFeeMultiplier, updatedProtocolFeeMultiplier);
        protocolFeeMultiplier = updatedProtocolFeeMultiplier;
    }

    /// @dev Allows the owner to update the protocol fixed fee.
    /// @param updatedProtocolFixedFee The updated protocol fixed fee.
    function setProtocolFixedFee(uint256 updatedProtocolFixedFee)
        override
        external
        onlyOwner
    {
        emit ProtocolFixedFee(protocolFixedFee, updatedProtocolFixedFee);
        protocolFixedFee = updatedProtocolFixedFee;
    }

    /// @dev Allows the owner to update the protocolFeeCollector address.
    /// @param updatedProtocolFeeCollector The updated protocolFeeCollector contract address.
    function setProtocolFeeCollectorAddress(address updatedProtocolFeeCollector)
        override
        external
        onlyOwner
    {
        emit ProtocolFeeCollectorAddress(protocolFeeCollector, updatedProtocolFeeCollector);
        protocolFeeCollector = updatedProtocolFeeCollector;
    }
}