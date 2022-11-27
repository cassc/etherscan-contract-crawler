// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @author: https://ethalage.com

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    _______  _______  __   __  _______  ___      _______  _______  _______        _______  _______  __   __    //
//   |       ||       ||  | |  ||   _   ||   |    |   _   ||       ||       |      |       ||       ||  |_|  |   //
//   |    ___||_     _||  |_|  ||  |_|  ||   |    |  |_|  ||    ___||    ___|      |       ||   _   ||       |   //
//   |   |___   |   |  |       ||       ||   |    |       ||   | __ |   |___       |       ||  | |  ||       |   //
//   |    ___|  |   |  |       ||       ||   |___ |       ||   ||  ||    ___| ___  |      _||  |_|  ||       |   //
//   |   |___   |   |  |   _   ||   _   ||       ||   _   ||   |_| ||   |___ |   | |     |_ |       || ||_|| |   //
//   |_______|  |___|  |__| |__||__| |__||_______||__| |__||_______||_______||___| |_______||_______||_|   |_|   //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/creator-core-solidity/contracts/ERC1155Creator.sol";
import "@a16z/contracts/licenses/CantBeEvil.sol"; 

abstract contract Ethalage1155 is ERC1155Creator, CantBeEvil {
    string private _contractURI;

    constructor (LicenseVersion license) ERC1155Creator() CantBeEvil(license) {
    }

    function tokenCount() public view virtual returns (uint256) {
        return _tokenCount;
    }

    // Contract

    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri_) public adminRequired {
        _contractURI = uri_;
    }

    // Fallback withdraw

    function withdraw(address payable recipient, uint256 amount) external adminRequired {
        (bool success,) = recipient.call{value:amount}("");
        require(success);
    }

    // Interfaces

    function supportsInterface(bytes4 interfaceId) public view virtual override(CantBeEvil, ERC1155Creator) returns (bool) {
        return ERC1155Creator.supportsInterface(interfaceId) || CantBeEvil.supportsInterface(interfaceId);
    }

}