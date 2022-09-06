// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMigrationNFT  {
    /**
    * @notice sets the contract address in charge of executing the minting of NFTs.
    * @param _migrateContract the address with permissions to call the mintNFT function
    */
    function setMinterAddress(address _migrateContract) external;
    
    /**
    * @notice mints a single migration NFT to the to address
    * @param _to the receiver of the NFT.
    */
    function mint(address _to) external;
}