// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

interface INonfungiblePositionManager1EX is INonfungiblePositionManager {
    /// @return Returns The address of the token descriptor contract, which handles generating token URIs for position tokens
    function tokenDescriptor() external view returns (address);

    /// @notice Set address of the token descriptor contract
    function setTokenDescriptor(address _tokenDescriptor) external;

    /// @notice Returns the address of the account that can change address of token descriptor contract
    function tokenDescriptorSetter() external returns (address);

    /// @notice Change tokenDescriptorSetter. Can only be called by the current owner
    function setTokenDescriptorSetter(address _tokenDescriptorSetter) external;
}