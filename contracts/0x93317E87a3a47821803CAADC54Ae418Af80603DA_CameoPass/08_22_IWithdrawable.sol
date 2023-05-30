// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

///@notice Ownable helper contract to withdraw ether or tokens from the contract address balance
interface IWithdrawable {
    function withdraw() external;

    function withdrawToken(address _tokenAddress) external;
}