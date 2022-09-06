// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./StreetlabERC721AUpgradeable.sol";

/// @title StreetlabERC721AFactory
/// @author Julien Bessaguet
/// @notice Factory for EIP-1167 cheap cloning of StreetlabERC721A NFT contract
contract StreetlabERC721AFactory is Ownable {
    event ContractCreated(
        address indexed owner,
        address indexed target,
        string name,
        string symbol
    );

    address public immutable implementation;

    constructor() {
        implementation = address(new StreetlabERC721AUpgradeable());
    }

    /// @notice Make new StreetlabERC721A NFT contracts
    /// @param name Collection name
    /// @param symbol Collection symbo
    /// @param maxSupply number of NFT to mint
    /// @param giveaway Giveaway supply
    /// @param presalePrice NFT unit price during allowlist/waitlist sale phase
    /// @param publicPrice NFT unit price during public sale phase
    function make(
        string calldata name,
        string calldata symbol,
        uint256 maxSupply,
        uint256 giveaway,
        uint256 presalePrice,
        uint256 publicPrice,
        uint256 limitPerPublicMint
    ) external onlyOwner returns (address) {
        address payable clone = payable(Clones.clone(implementation));
        StreetlabERC721AUpgradeable c = StreetlabERC721AUpgradeable(clone);
        emit ContractCreated(msg.sender, clone, name, symbol);
        c.initialize(
            msg.sender,
            name,
            symbol,
            maxSupply,
            giveaway,
            presalePrice,
            publicPrice,
            limitPerPublicMint
        );
        return clone;
    }
}