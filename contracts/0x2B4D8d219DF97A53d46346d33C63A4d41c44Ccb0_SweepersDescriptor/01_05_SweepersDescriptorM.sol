// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ISweepersSeeder } from './interfaces/ISweepersSeeder.sol';

contract SweepersDescriptor is Ownable {

    // Base URI
    string public baseURI = 'https://ipfs.io/ipfs/QmQU2TznaU6yCAKPNS6rVUiqb87ZhgecH9UqSGubSyf5qz';

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId, ISweepersSeeder.Seed memory seed) external view returns (string memory) {
        return string(abi.encodePacked(baseURI));
    }

    function dataURI(uint256 tokenId, ISweepersSeeder.Seed memory seed) external view returns (string memory) {
        return string(abi.encodePacked(baseURI));
    }
}