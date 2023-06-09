// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: @frankPoncelet

import "./IRoyalties.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/introspection/ERC165.sol";

abstract contract Royalties is IRoyalties, ERC165 {
    
    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *  bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     *
     *  => 0xb9c4d9fb ^ 0x0ebd4c7f = 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;
    
    /**
     *  @dev Foundation
     *
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_FOUNDATION = 0xd5a06d4c;

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    
    // Royalty mappings
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRoyalties).interfaceId || super.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE
            || interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION 
            || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }
    
}