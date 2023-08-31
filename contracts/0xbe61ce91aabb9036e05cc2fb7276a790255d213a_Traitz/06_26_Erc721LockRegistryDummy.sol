// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "./ERC721ANamableDummy.sol";
import "./LockRegistryDummy.sol";
import "./IERC721xDummy.sol";

contract ERC721xDummy is ERC721ANamableDummy, LockRegistryDummy {
    /*
     *     bytes4(keccak256('freeId(uint256,address)')) == 0x94d216d6
     *     bytes4(keccak256('isUnlocked(uint256)')) == 0x72abc8b7
     *     bytes4(keccak256('lockCount(uint256)')) == 0x650b00f6
     *     bytes4(keccak256('lockId(uint256)')) == 0x2799cde0
     *     bytes4(keccak256('lockMap(uint256,uint256)')) == 0x2cba8123
     *     bytes4(keccak256('lockMapIndex(uint256,address)')) == 0x09308e5d
     *     bytes4(keccak256('unlockId(uint256)')) == 0x40a9c8df
     *     bytes4(keccak256('approvedContract(address)')) == 0xb1a6505f
     *
     *     => 0x94d216d6 ^ 0x72abc8b7 ^ 0x650b00f6 ^ 0x2799cde0 ^
     *        0x2cba8123 ^ 0x09308e5d ^ 0x40a9c8df ^ 0xb1a6505f == 0x706e8489
     */

    bytes4 private constant _INTERFACE_ID_ERC721x = 0x0;

    function __ERC721x_init(string memory _name, string memory _symbol)
        internal
        onlyInitializing
    {
        ERC721ANamableDummy.__ERC721ANamable_init(_name, _symbol);
        LockRegistryDummy.__LockRegistry_init();
    }

}