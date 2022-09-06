// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct Fee {
    string name;
    uint256 price;
}

struct FeeManagerContract {
    mapping(string => Fee) fees;
}


/// @notice the fee manager manages fees by providing the fee amounts for the requested identifiers. Fees are global but can be overridden for a specific message sender.
interface IFees {

    /// @notice get the fee for the given fee type hash
    /// @param feeLabel the keccak256 hash of the fee type
    /// @return the fee amount
    function fee(string memory feeLabel) external view returns (Fee memory);
    function calculateFee(string memory feeLabel, uint256 amount) external view returns (uint256);
    
}