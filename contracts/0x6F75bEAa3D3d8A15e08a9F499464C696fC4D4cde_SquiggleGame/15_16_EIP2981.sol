// SPDX-License-Identifier: MIT

/**
*   @title EIP 2981 base contract
*   @author Transient Labs
*   @notice contract implementation of EIP 2981
*/

pragma solidity ^0.8.0;

import "ERC165.sol";
import "IEIP2981.sol";

contract EIP2981 is IEIP2981, ERC165 {

    address internal royaltyAddr;
    uint256 internal royaltyPerc; // percentage in basis (out of 10,000)

    /**
    *   @notice constructor
    *   @dev need inheriting contracts to accept the parameters in their constructor
    *   @param _addr is the royalty payout address
    *   @param _perc is the royalty percentage, multiplied by 10000. Ex: 7.5% => 750
    */
    constructor(address _addr, uint256 _perc) {
        royaltyAddr = _addr;
        royaltyPerc = _perc;
    }

    /**
    *   @notice EIP 2981 royalty support
    *   @dev royalty payout made to the owner of the contract and the owner can't be the 0 address
    *   @dev royalty amount determined when contract is deployed, and then divided by 1000 in this function
    *   @dev royalty amount not dependent on _tokenId
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        require(royaltyAddr != address(0));
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