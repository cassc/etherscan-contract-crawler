// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity >=0.6.2 <0.8.0;

import "../openzeppelinupgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "../openzeppelinupgradeable/access/OwnableUpgradeable.sol";
import "../openzeppelinupgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../openzeppelinupgradeable/token/ERC721/IERC721Upgradeable.sol";

abstract contract TokensRecoverableUpg is OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function recoverTokens(IERC20Upgradeable token) public onlyOwner() 
    {
        require (canRecoverTokens(token));    
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverETH(uint256 amount) public onlyOwner() 
    {        
        msg.sender.transfer(amount);
    }

    function recoverERC1155(IERC1155Upgradeable token, uint256 tokenId, uint256 amount) public onlyOwner() 
    {        
        token.safeTransferFrom(address(this),msg.sender,tokenId,amount,"0x");
    }

    function recoverERC721(IERC721Upgradeable token, uint256 tokenId) public onlyOwner() 
    {        
        token.safeTransferFrom(address(this),msg.sender,tokenId);
    }

    function canRecoverTokens(IERC20Upgradeable token) internal virtual view returns (bool) 
    { 
        return address(token) != address(this); 
    }

}