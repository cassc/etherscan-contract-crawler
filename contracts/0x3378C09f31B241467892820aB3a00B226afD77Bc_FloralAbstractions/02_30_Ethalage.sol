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

import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";
import "@a16z/contracts/licenses/CantBeEvil.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Ethalage is ERC721Creator, CantBeEvil {
    string private _contractURI = "https://ethalage.com/contract.json";
    string private _artist;

    constructor (string memory _name, string memory _symbol, LicenseVersion license) ERC721Creator(_name, _symbol) CantBeEvil(license) {
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenCount;
    }

    // Artist

    function artist() public view virtual returns (string memory) {
        return _artist;
    }

    function setArtist(string memory artist_) public adminRequired {
        _artist = artist_;
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

    function withdrawToken(address recipient, address erc20, uint256 amount) external adminRequired {
        IERC20(erc20).transfer(recipient, amount);
    }

    // Interfaces

    function supportsInterface(bytes4 interfaceId) public view virtual override(CantBeEvil, ERC721Creator) returns (bool) {
        return ERC721Creator.supportsInterface(interfaceId) || CantBeEvil.supportsInterface(interfaceId);
    }

}