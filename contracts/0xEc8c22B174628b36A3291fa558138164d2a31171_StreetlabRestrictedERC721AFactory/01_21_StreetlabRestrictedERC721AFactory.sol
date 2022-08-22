// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./StreetlabRestrictedERC721AUpgradeable.sol";

/// @title StreetlabRestrictedERC721AFactory
/// @author Julien Bessaguet
/// @notice Factory for EIP-1167 cheap cloning of StreetlabRestrictedERC721A NFT contract
/// Restricted version is a simplified contract w/ owner minting only.
contract StreetlabRestrictedERC721AFactory is Ownable {
    event ContractCreated(address indexed owner, address indexed target, string name, string symbol);
    
    address public immutable implementation;

    constructor () {
        implementation = address(new StreetlabRestrictedERC721AUpgradeable());
    }

    /// @notice Make new StreetlabRestrictedERC721A NFT contracts
    /// @param name Collection name
    /// @param symbol Collection symbo
    /// @param maxSupply number of NFT to mint
    function make(string calldata name, string calldata symbol, uint256 maxSupply) external onlyOwner returns(address) {
        address payable clone = payable(Clones.clone(implementation));
        StreetlabRestrictedERC721AUpgradeable c = StreetlabRestrictedERC721AUpgradeable(clone);
        emit ContractCreated(msg.sender, clone, name, symbol);
        c.initialize(msg.sender, name, symbol, maxSupply);
        return clone;
    }
}