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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@a16z/contracts/licenses/CantBeEvil.sol";

abstract contract EthalageMinter is ERC721, ERC721Burnable, AccessControl, IERC2981, CantBeEvil {
    using Counters for Counters.Counter;

    string private _contractURI = "https://ethalage.com/contract.json";
    string private _artist;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter internal _tokenIdCounter;

    mapping (uint256 => string) private _tokens;

    address public beneficiary;

    constructor (string memory _name, string memory _symbol, LicenseVersion license) ERC721(_name, _symbol) CantBeEvil(license) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Artist

    function artist() public view virtual returns (string memory) {
        return _artist;
    }

    function setArtist(string memory artist_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _artist = artist_;
    }

    // Contract

    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractURI = uri_;
    }

    // Beneficiary

    /// @dev Set the beneficiary
    function setBeneficiary(address _beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) {
        beneficiary = _beneficiary;
    }

    /// @dev Withdraw balance to beneficiary
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(beneficiary).transfer(balance);
    }

    /// @dev Royalty info for sale on secondary market
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        _tokenId; // silence warning
        return (beneficiary, (_salePrice * 750) / 10000);
    }

    // Interfaces

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl, CantBeEvil, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || CantBeEvil.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }

}