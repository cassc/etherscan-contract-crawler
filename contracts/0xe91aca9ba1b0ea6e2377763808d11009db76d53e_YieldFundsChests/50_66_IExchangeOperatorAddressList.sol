// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IExchangeOperatorAddressList {
    /**
     * @notice Returns an integer representing the exchange a given operator address belongs to (0 if none)
     * @param _operatorAddress The operator address to map to an exchange
     */
    function operatorAddressToExchange(
        address _operatorAddress
    ) external view returns (uint256);
}