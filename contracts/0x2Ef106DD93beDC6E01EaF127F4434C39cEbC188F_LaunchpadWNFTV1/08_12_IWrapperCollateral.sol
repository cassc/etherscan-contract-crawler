// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "IERC721Enumerable.sol";

interface IWrapperCollateral is  IERC721Enumerable {
    struct ERC20Collateral {
        address erc20Token;
        uint256 amount;
    }
    
    /**
     * @dev Function returns array with info about ERC20 
     * colleteral of wrapped token 
     *
     * @param _wrappedId  new protocol NFT id from this contarct
     */
    function getERC20Collateral(uint256 _wrappedId) 
         external 
         view 
         returns (ERC20Collateral[] memory);

    /**
     * @dev Function returns collateral balance of this NFT in _erc20 
     * colleteral of wrapped token 
     *
     * @param _wrappedId  new protocol NFT id from this contarct
     * @param _erc20 - collateral token address
     */
    function getERC20CollateralBalance(uint256 _wrappedId, address _erc20) 
        external 
        view
        returns (uint256); 

     /**
     * @dev Function returns tuple with accumulated amounts of 
     * native chain collateral(eth, bnb,..) and transfer Fee 
     *
     * @param _tokenId id of protocol token (new wrapped token)
     */
    function getTokenValue(uint256 _tokenId) external view returns (uint256, uint256);

    /**
     * @dev Function returns true is `_contract` ERC20 is 
     * enabled for add in colleteral of wrapped token 
     *
     * @param _contract  collateral contarct
     */
    function enabledForCollateral(address _contract) external view returns (bool);
}