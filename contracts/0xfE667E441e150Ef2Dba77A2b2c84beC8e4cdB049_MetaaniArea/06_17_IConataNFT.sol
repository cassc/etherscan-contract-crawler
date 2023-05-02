// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//
interface IConataNFT{
    event Log(string message);
    event Minted(address account, uint tokenId);

    // WRITE ////////////////////////////////////////////////////////////////////////////

    
    function mint(bytes calldata data) external payable;
    function mint() external payable;

    
    function burn(uint tokenId, uint amount) external;

    
    function setURI(string memory newURI) external;
    
    
    function withdraw() external;
    function withdrawSpare() external;
    
    // READ ////////////////////////////////////////////////////////////////////////////

    
    function totalSupply() external view returns (uint256);

}