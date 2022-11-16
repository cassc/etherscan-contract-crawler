// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./GsERC1155.sol";

/*
* @title ERC1155 token for ENSAN SEED
*/
contract EnsanSeed is GsERC1155 {

    uint256 public constant maxSupply = 555;
    uint256 public maxPerWallet = 1;

    constructor( 
        string memory _baseURI
    ) GsERC1155("Ensan Olive Seed", "SEED", _baseURI, msg.sender, 1000) {
        _mint(msg.sender, 1, 70, "");
    } 

     /**
     * @notice Mints the given amount of token id 1 to specified receiver address
     * 
     * @param _receiver the receiving wallet
     * @param _amount the amount of tokens to mint
     */
    function ownerMint(address _receiver, uint256 _amount) external onlyOwner {
        require(totalSupply(1) + _amount <= maxSupply, "Purchase: Max supply reached");

        _mint(_receiver, 1, _amount, "");        
    }      

    /**
    * @notice mint during public sale
    * 
    * @param amount the amount of tokens to mint
    */
    function publicMint(uint256 amount) external payable whenNotPaused whenPublicSaleIsActive{
        require(tx.origin == msg.sender, "No contract minting");
        require(totalSupply(1) + amount <= maxSupply, "Max supply reached");

        uint256 userMintsTotal = balanceOf(msg.sender, 1);
        require(userMintsTotal + amount <= maxPerWallet, "Max mint limit reached");

        _mint(msg.sender, 1, amount, "");
    }   
}