// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./IERC20.sol";

interface IDynaset is IERC20 {
    function joinDynaset(uint256 _amount) external returns (uint256);

    function exitDynaset(uint256 _amount) external;

    function calcTokensForAmount(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);
        
    function getTokenAmounts()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    function getCurrentTokens() external view returns (address[] memory tokens);
}