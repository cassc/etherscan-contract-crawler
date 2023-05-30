// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {AccessControlEnumerable} from '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {ISBYASStaticData} from '../interface/ISBYASStaticData.sol';
import {ISBYASData} from '../interface/ISBYASData.sol';

contract SBYASData is ISBYASData, AccessControlEnumerable, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
    bytes32 public constant CHARACTER_SETTER_ROLE = keccak256('CHARACTER_SETTER_ROLE');

    uint64 public override etherPrice = 0.01 ether;
    ISBYASStaticData.Character[] public override characters;
    string[] public override images;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        _grantRole(CHARACTER_SETTER_ROLE, _msgSender());
    }

    function setEtherPrice(uint64 _newPrice) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        etherPrice = _newPrice;
    }

    function addCharactor(
        ISBYASStaticData.Character memory _newCharacter
    ) external override onlyRole(CHARACTER_SETTER_ROLE) {
        characters.push(_newCharacter);
    }

    function addImage(string memory _newImage) external override onlyRole(CHARACTER_SETTER_ROLE) {
        images.push(_newImage);
    }

    function setCharactor(
        ISBYASStaticData.Character memory _newCharacter,
        uint256 id
    ) external override onlyRole(CHARACTER_SETTER_ROLE) {
        characters[id] = _newCharacter;
    }

    function setImage(string memory _newImage, uint256 id) external override onlyRole(CHARACTER_SETTER_ROLE) {
        images[id] = _newImage;
    }

    function getCharactersLength() external view override returns (uint256) {
        return characters.length;
    }

    function getImagesLength() external view override returns (uint256) {
        return images.length;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return AccessControlEnumerable.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }
}