// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { INounsDescriptor } from './INounsDescriptor.sol';
import { INounsSeeder } from './INounsSeeder.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract FoundNounToken is Ownable, ERC721Enumerable {
    using Strings for uint256;

    uint256 public constant max_tokens = 10000;
    uint8 public constant mint_limit = 10;

    // The noun seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    // Number of mints per wallet
    mapping(address => uint256) public mints;

    // The internal Found Noun ID tracker
    uint256 private _currentNounId;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // The Nouns token URI descriptor
    INounsDescriptor public descriptor;

    // The Nouns token seeder
    INounsSeeder public seeder;

    // Mint status
    bool public mintActive = false;

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'Seeder is locked');
        _;
    }

    constructor() ERC721('Found Nouns', 'FN') {
        descriptor = INounsDescriptor(0x7006337351B6127EfAcf63643Ea97915e80268A9);
        seeder = INounsSeeder(0xA44A4caa7690ed8791237b6c0551e48f404Cf233);
    }

    function mint(uint256 mintAmount) public {
        require(mintActive, 'mint not active');
        require(mintAmount + totalSupply() <= max_tokens, 'exceeds maximum tokens');
        require(mintAmount + mints[msg.sender] <= mint_limit, 'minted too many');

        for (uint i = 0; i < mintAmount; i++) {
            _mintTo(msg.sender, _currentNounId++);
        }
    }

    function _mintTo(address to, uint256 nounId) internal {
        seeds[nounId] = seeder.generateSeed(nounId, descriptor);
        _safeMint(to, nounId);
        mints[to]++;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'URI query for nonexistent token');

        string memory nounId = tokenId.toString();
        string memory name = string(abi.encodePacked('Found Noun ', nounId));
        string memory description = string(abi.encodePacked('Found Noun ', nounId, ' is not a member of the Nouns DAO'));

        return descriptor.genericDataURI(name, description, seeds[tokenId]);
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(INounsDescriptor _descriptor) external onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(INounsSeeder _seeder) external onlyOwner whenSeederNotLocked {
        seeder = _seeder;
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external onlyOwner whenSeederNotLocked {
        isSeederLocked = true;
    }

    function toggleMintStatus() external onlyOwner {
        mintActive = !mintActive;
    }
}