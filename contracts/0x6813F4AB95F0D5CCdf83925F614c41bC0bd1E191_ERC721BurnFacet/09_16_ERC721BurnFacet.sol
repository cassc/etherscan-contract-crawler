// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../utilities/Modifiers.sol";

import "../libraries/UInt256Set.sol";
import "../libraries/ERC721ALib.sol";
import "../libraries/LibDiamond.sol";

contract ERC721BurnFacet is Modifiers {

    using ERC721ALib for ERC721AContract;
    using UInt256Set for UInt256Set.Set;

    event ERC721Burned(address indexed tokenAddress, uint256 indexed tokenId);

    /// @notice mint tokens of specified amount to the specified address
    function burn(
        uint256 tokenId
    ) external {
        require(msg.sender == LibDiamond.contractOwner() || msg.sender == ERC721ALib.erc721aStorage().erc721Contract.ownershipOf(tokenId).addr, "unauthorized");
        ERC721ALib.erc721aStorage().erc721Contract._burn(
            tokenId
        );
        emit ERC721Burned(
            address(this),
            tokenId
        );
    }

}