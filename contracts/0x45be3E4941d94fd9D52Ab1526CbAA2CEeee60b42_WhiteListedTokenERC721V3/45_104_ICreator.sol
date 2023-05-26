// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface ICreator {
    /*
     * bytes4(keccak256('getCreator(uint256)')) == 0xd48e638a
     */

    //    bytes4 private constant _INTERFACE_ID_CREATOR = 0xd48e638a;
    //
    //    constructor() public {
    //        _registerInterface(_INTERFACE_ID_CREATOR);
    //    }

    function getCreator(uint256 _tokenId) external view returns (address);
}