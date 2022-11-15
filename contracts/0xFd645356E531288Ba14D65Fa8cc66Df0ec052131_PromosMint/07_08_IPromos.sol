// SPDX-License-Identifier: MIT
// Promos v1.0.0
// Creator: promos.wtf

pragma solidity ^0.8.0;

interface IPromos {
    function mintPromos(address _to, uint256 _amount) external payable;


    /**
     * @dev 
     * After deployment use this function to set `promosProxyContract`. 
     * Mainnet - 0xA7296e3239Db13ACa886Fb130aE5Fe8f5A315721 
     * Goerli  - 0x90766204108309bf97b998E262D05aa1b00Bc35c
     */
    function setPromosProxyContract(address _promosProxyContract) external;
}