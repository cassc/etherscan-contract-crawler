// SPDX-License-Identifier: MIT

/**
*   @title EIP 2981 base contract
*   @notice EIP 2981 implementation for differing royalties based on token number
*   @author transientlabs.xyz
*/

/*
   ___       _ __   __  ___  _ ______                 __ 
  / _ )__ __(_) /__/ / / _ \(_) _/ _/__ _______ ___  / /_
 / _  / // / / / _  / / // / / _/ _/ -_) __/ -_) _ \/ __/
/____/\_,_/_/_/\_,_/ /____/_/_//_/ \__/_/  \__/_//_/\__/                                                          
 ______                  _          __    __        __     
/_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/ 
*/

pragma solidity >0.8.9 <0.9.0;

import "ERC165.sol";
import "IEIP2981.sol";

abstract contract EIP2981MultiToken is IEIP2981, ERC165 {

    mapping(uint256 => address) internal _royaltyAddr;
    mapping(uint256 => uint256) internal _royaltyPerc; // percentage in basis (out of 10,000)

    /**
    *   @notice EIP 2981 royalty support
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view virtual override returns (address receiver, uint256 royaltyAmount) {
        return (_royaltyAddr[_tokenId], _royaltyPerc[_tokenId] * _salePrice / 10000);
    }

    /**
    *   @notice override ERC 165 implementation of this function
    *   @dev if using this contract with another contract that suppports ERC 165, will have to override in the inheriting contract
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
    *   @notice function to set royalty information for a token
    *   @dev to be called by inheriting contract
    *   @param tokenId is the token id
    *   @param addr is the royalty payout address for this token id
    *   @param perc is the royalty percentage (out of 10,000) to set for this token id
    */
    function _setRoyaltyInfo(uint256 tokenId, address addr, uint256 perc) internal virtual {
        require(addr != address(0), "EIP2981MultiToken: Cannot set royalty receipient to the zero address");
        require(perc < 10000, "EIP2981MultiToken: Cannot set royalty percentage above 10000");
        _royaltyAddr[tokenId] = addr;
        _royaltyPerc[tokenId] = perc;
    }
}