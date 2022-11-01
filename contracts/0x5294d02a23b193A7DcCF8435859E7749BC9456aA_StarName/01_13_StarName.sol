// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ██████████████▌          ╟██           ████████████████          j██████████████  //
//  ██████████████▌          ╟███           ███████████████          j██████████████  //
//  ██████████████▌          ╟███▌           ██████████████          j██████████████  //
//  ██████████████▌          ╟████▌           █████████████          j██████████████  //
//  ██████████████▌          ╟█████▌          ╙████████████          j██████████████  //
//  ██████████████▌          ╟██████▄          ╙███████████          j██████████████  //
//  ██████████████▌          ╟███████           ╙██████████          j██████████████  //
//  ██████████████▌          ╟████████           ╟█████████          j██████████████  //
//  ██████████████▌          ╟█████████           █████████          j██████████████  //
//  ██████████████▌          ╟██████████           ████████          j██████████████  //
//  ██████████████▌          ╟██████████▌           ███████          j██████████████  //
//  ██████████████▌          ╟███████████▌           ██████          j██████████████  //
//  ██████████████▌          ╟████████████▄          ╙█████        ,████████████████  //
//  ██████████████▌          ╟█████████████           ╙████      ▄██████████████████  //
//  ██████████████▌          ╟██████████████           ╙███    ▄████████████████████  //
//  ██████████████▌          ╟███████████████           ╟██ ,███████████████████████  //
//  ██████████████▌                      ,████           ███████████████████████████  //
//  ██████████████▌                    ▄██████▌           ██████████████████████████  //
//  ██████████████▌                  ▄█████████▌           █████████████████████████  //
//  ██████████████▌               ,█████████████▄           ████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IStarName.sol";
import "./IStar.sol";

contract StarName is IStarName, AdminControl {
    using Strings for uint256;

    // Star type to default star name
    mapping(uint8 => string) private _defaultStarNameLookup;
    // token id to cutomized name that overrides _defaultStarNameLookup
    mapping(uint256 => string) private _overriddenStarNameLookup;

    // ERC721 Star contract
    address immutable private _creator;

    constructor(address creator) {
        // So that we can later allow only a Star's owner to setOverride
        _creator = creator;
        // The default star names used until Star owner calls setOverride
        _defaultStarNameLookup[uint8(1)] = "Hydrogen%20Star";
        _defaultStarNameLookup[uint8(2)] = "Helium%20Star";
        _defaultStarNameLookup[uint8(3)] = "Bronzed%20Star";
        _defaultStarNameLookup[uint8(4)] = "Silversmithed%20Star";
        _defaultStarNameLookup[uint8(5)] = "Black%20Titanium%20Star";
        _defaultStarNameLookup[uint8(6)] = "The%20Darkest%20Star";
        _defaultStarNameLookup[uint8(7)] = "Fragile%20Star";
        _defaultStarNameLookup[uint8(8)] = "The%20Watcher";
        _defaultStarNameLookup[uint8(9)] = "The%20Hidden";
        _defaultStarNameLookup[uint8(10)] = "Shiny%20Star";
        _defaultStarNameLookup[uint8(11)] = "Miners%20Star";
        _defaultStarNameLookup[uint8(12)] = "The%20One";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AdminControl) returns (bool) {
        return
            interfaceId == type(IStarName).interfaceId ||
            interfaceId == type(AdminControl).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev See {IStarName-updateDefaultStarName}.
     */
    function updateDefaultStarName(uint8 starType, string memory name) public adminRequired {
        _defaultStarNameLookup[starType] = name;
    }

    /**
     * @dev See {IStarName-setOverride}.
     */
    function setOverride(uint256 tokenId, string memory name) public override {
        require(IERC721(_creator).ownerOf(tokenId) == tx.origin, "Only owner can change.");
        require(bytes(_overriddenStarNameLookup[tokenId]).length == 0, 'Name already set');
        _overriddenStarNameLookup[tokenId] = name;
    }

    /**
     * @dev See {IStarName-isOverriden}.
     */
    function isOverriden(uint256 tokenId) public view virtual override returns (bool) {
        return bytes(_overriddenStarNameLookup[tokenId]).length != 0;
    }

    /**
     * @dev See {IStarName-getName}.
     */
    function getName(uint256 tokenId, IStar.StarInfo memory starInfo) public view virtual override returns (string memory) {
        return bytes(_overriddenStarNameLookup[tokenId]).length != 0
            ? _overriddenStarNameLookup[tokenId]
            : string(abi.encodePacked(
                  _defaultStarNameLookup[starInfo.starType],
                  '%20',
                  uint256(starInfo.starTime).toString()
              ));
    }

    function getDefaultName(uint8 starType) public view virtual override returns (string memory) {
        return _defaultStarNameLookup[starType];
    }
}