// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./interfaces/IERC721Manager.sol";
import "./interfaces/IERC721AProxy.sol";
import "./MultiSigProxy.sol";

// @author: miinded.com

abstract contract ERC721AManager is IERC721Manager, MultiSigProxy {

    IERC721AProxy public ERC721Address;

    function setERC721Address(address _ERC721Address) public onlyOwnerOrAdmins{
        MultiSigProxy.validate("setERC721Address");

        _setERC721Address(_ERC721Address);
    }
    function _setERC721Address(address _ERC721Address) internal {
        ERC721Address = IERC721AProxy(_ERC721Address);
    }
    function _mint(address _wallet, uint256 _count) internal{
        ERC721Address.mint(_wallet, _count);
    }
    function _safeMint(address _wallet, uint256 _count) internal{
        ERC721Address.mint(_wallet, _count);
    }
    function _burn(uint256 _tokenId) internal{
        ERC721Address.burn(_tokenId);
    }
    function _totalSupply() internal view returns(uint256){
        return ERC721Address.totalSupply();
    }
    function _totalMinted() internal view returns(uint256){
        return ERC721Address.totalMinted();
    }
    function _totalBurned() internal view returns(uint256){
        return ERC721Address.totalBurned();
    }
    function balanceOf(address _wallet) internal view returns(uint256){
        return ERC721Address.balanceOf(_wallet);
    }
    function ownerOf(uint256 _tokenId) internal view returns(address){
        return ERC721Address.ownerOf(_tokenId);
    }
    function tokensOfOwner(address _wallet) internal view returns(uint256[] memory){
        return ERC721Address.tokensOfOwner(_wallet);
    }
    function transferFrom(address, address, uint256) public override virtual returns(bool) {
        return true;
    }

}