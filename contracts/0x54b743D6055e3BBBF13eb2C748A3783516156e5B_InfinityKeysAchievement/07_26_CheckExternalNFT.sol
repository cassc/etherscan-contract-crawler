// SPDX-License-Identifier: MIT
// 2022 Infinity Keys Team
pragma solidity ^0.8.4;

/************************************************************
* @title: CheckExternalNFT                                  *
* @notice: Check if address owns requisite NFT              *
*************************************************************/

contract IExternalNFT {
	function balanceOf( address _address ) external view returns ( uint256 ) {}
}

abstract contract CheckExternalNFT {
    /**
    @dev Checks if specified address owns NFT on specified contract 
    */
    function checkExternalNFT ( address _address, address _contract ) internal view returns ( bool ) {
        IExternalNFT externalNFT = IExternalNFT(_contract);
        return externalNFT.balanceOf(_address) > 0;
    }
}