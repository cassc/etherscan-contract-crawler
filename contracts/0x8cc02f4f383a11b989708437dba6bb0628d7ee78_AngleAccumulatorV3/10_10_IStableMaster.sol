// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IStableMaster {
	function withdraw(
        uint256 amount, 
        address burner, 
        address dest, 
        address poolManager
    ) external;
    
    function mint(
        uint256 amount,
        address user,
        address poolManager,
        uint256 minStableAmount
    ) external;
}