// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// Interface for IFactory
interface IFactory {
    function checkRoyaltyFeeContract(address _contractAddress) external view returns(bool);
}