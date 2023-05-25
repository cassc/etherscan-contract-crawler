//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMonaco {

    function isOnWhiteList(address addr) external view returns (bool);

    function addToWhiteList(address[] calldata addresses) external;

    function removeFromWhiteList(address[] calldata addresses) external;

    function setWhiteListMintActive(bool active) external;

    function setMintActive(bool active) external;

    function mint(uint256 numberOfMonaco) payable external;
    
    function whiteListMint() payable external;

    function withdraw() external;    

}