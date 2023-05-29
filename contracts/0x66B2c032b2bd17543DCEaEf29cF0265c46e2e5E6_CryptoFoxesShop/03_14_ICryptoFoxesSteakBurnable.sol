// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ICryptoFoxesSteak.sol";

// @author: miinded.com

interface ICryptoFoxesSteakBurnable is ICryptoFoxesSteak {
    function burnSteaks(address _to, uint256 _amount) external;
}