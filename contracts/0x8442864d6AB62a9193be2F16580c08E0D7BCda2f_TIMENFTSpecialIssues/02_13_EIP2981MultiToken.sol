// SPDX-License-Identifier: MIT

/**
*   @title EIP 2981 base contract
*   @author Transient Labs
*   @notice contract implementation of EIP 2981
*/

/*
   ___                            __  __          ______                  _          __    __        __     
  / _ \___ _    _____ _______ ___/ / / /  __ __  /_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / ___/ _ \ |/|/ / -_) __/ -_) _  / / _ \/ // /   / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/   \___/__,__/\__/_/  \__/\_,_/ /_.__/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/
                                        /___/                                                               
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IEIP2981.sol";

contract EIP2981MultiToken is IEIP2981, ERC165 {

    mapping(uint256 => address) internal _royaltyAddr;
    mapping(uint256 => uint256) internal _royaltyPerc; // percentage in basis (out of 10,000)

    /**
    *   @notice override ERC 165 implementation of this function
    *   @dev if using this contract with another contract that suppports ERC 265, will have to override in the inheriting contract
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
    *   @notice EIP 2981 royalty support
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        require(_royaltyAddr[_tokenId] != address(0), "Royalty recipient can't be the 0 address");
        return (_royaltyAddr[_tokenId], _royaltyPerc[_tokenId] * _salePrice / 10000);
    }
}