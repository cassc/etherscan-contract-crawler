// SPDX-License-Identifier: MIT

/**
*   @title EIP 2981 All Token
*   @notice implementation of EIP 2981, with all tokens having the same royalty amount
*   @author Transient Labs, LLC
*/

/*
   ___                            __  ___         ______                  _         __    __       __     
  / _ \___ _    _____ _______ ___/ / / _ )__ __  /_  _________ ____  ___ (____ ___ / /_  / / ___ _/ /  ___
 / ___/ _ | |/|/ / -_/ __/ -_/ _  / / _  / // /   / / / __/ _ `/ _ \(_-</ / -_/ _ / __/ / /_/ _ `/ _ \(_-<
/_/   \___|__,__/\__/_/  \__/\_,_/ /____/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_\__/ /____\_,_/_.__/___/
                                        /___/                                                             
*/

pragma solidity ^0.8.0;

import "ERC165.sol";
import "IEIP2981.sol";

contract EIP2981AllToken is IEIP2981, ERC165 {

    address internal royaltyAddr;
    uint256 internal royaltyPerc; // percentage in basis (out of 10,000)

    /**
    *   @notice constructor
    *   @dev need inheriting contracts to accept the parameters in their constructor
    *   @dev inheriting contracts may implement functions to re-assign the state variables in this contract
    *   @param addr is the royalty payout address
    *   @param perc is the royalty percentage, multiplied by 10000. Ex: 7.5% => 750
    */
    constructor(address addr, uint256 perc) {
        royaltyAddr = addr;
        royaltyPerc = perc;
    }

    /**
    *   @notice EIP 2981 royalty support
    *   @dev royalty amount not dependent on _tokenId
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view virtual override returns (address receiver, uint256 royaltyAmount) {
        return (royaltyAddr, royaltyPerc * _salePrice / 10000);
    }

    /**
    *   @notice override ERC 165 implementation of this function
    *   @dev if using this contract with another contract that suppports ERC 265, will have to override in the inheriting contract
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || super.supportsInterface(interfaceId);
    }
}