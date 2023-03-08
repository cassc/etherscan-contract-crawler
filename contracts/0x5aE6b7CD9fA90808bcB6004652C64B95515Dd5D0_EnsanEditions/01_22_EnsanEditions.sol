// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./GsERC1155Merkle.sol";
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

/**
 * @title ENSAN Editions tokens
 * @notice Can define new tokens on the GO and operate public and allow list gated mints
 * @author www.geeks.solutions  
*/
contract EnsanEditions is GsERC1155Merkle, DefaultOperatorFilterer {

    constructor() GsERC1155Merkle("Ensan Editions", "EES", "https://oxqme47eeycnsnbntin5otag4dgrsqd3alyb4b4lgcbkme4wkeca.arweave.net/deDCc-QmBNk0LZob10wG4M0ZQHsC8B4HizCCphOWUQQ", msg.sender, 1000) DefaultOperatorFilterer() {} 

     /**
     * @notice Mints the given amount of token id to the specified receiver address
     * 
     * @param _token_id the token id to mint
     * @param _receiver the receiving wallet
     * @param _amount the amount of tokens to mint
     */
    function oMint(uint256 _token_id, address _receiver, uint256 _amount) external onlyOwner {
        if(_receiver == address(0)) revert ZeroAddress();

        ReturnData memory rd = getTokenData(_token_id);
        if(rd.total_supply + _amount > rd.max_supply) revert MaxSupply();

        _mint(_receiver, _token_id, _amount, "");        
    }      

    /**
    * @notice mint during public sale
    * 
    * @param _token_id the token id to mint
    * @param _amount the amount of tokens to mint
    */
    function mint(uint256 _token_id, uint256 _amount) external payable whenNotPaused whenPublicSaleIsActive(_token_id){
        if(msg.value < super.elligible_mint(_token_id, _amount)) revert InsufficentFunds();
        _mint(_msgSender(), _token_id, _amount, "");
    }  

    /**
     * @notice Mints a token following a given whitelist conditions
     * 
     * @param token_id The token id to mint
     * @param wlIndex the index of the whitelist to use for this mint
     * @param amount the amount of tokens to mint
     * @param proof the proof to grant access to this whitelist
     */
    function wlMint(uint256 token_id, uint256 wlIndex, uint256 amount, bytes32[] calldata proof) external payable whenNotPaused {
         if(msg.value < super.elligible_claim(amount, token_id, wlIndex, proof)) revert InsufficentFunds();
        _mint(_msgSender(), token_id, amount, "");
    } 

    /**
    * @notice Open Sea filterer to blacklist Marketplace which are not enforcing Royalty payments
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) 
    {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}