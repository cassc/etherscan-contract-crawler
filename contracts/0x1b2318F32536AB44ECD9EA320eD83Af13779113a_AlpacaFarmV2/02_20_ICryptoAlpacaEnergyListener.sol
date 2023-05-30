// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/introspection/IERC165.sol";

interface ICryptoAlpacaEnergyListener is IERC165 {
    /**
        @dev Handles the Alpaca energy change callback.
        @param id The id of the Alpaca which the energy changed
        @param oldEnergy The ID of the token being transferred
        @param newEnergy The amount of tokens being transferred
    */
    function onCryptoAlpacaEnergyChanged(
        uint256 id,
        uint256 oldEnergy,
        uint256 newEnergy
    ) external;
}