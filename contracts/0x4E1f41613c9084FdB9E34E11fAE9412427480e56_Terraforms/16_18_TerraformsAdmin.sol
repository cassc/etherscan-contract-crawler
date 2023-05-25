// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Admin functions and access control for the Terraforms contract
/// @author xaltgeist
abstract contract TerraformsAdmin is ERC721Enumerable, ReentrancyGuard, Ownable{
    
    enum Mintpass {None, Unused, Used}
    
    /// @notice Sale information
    uint public constant PRICE = 0.16 ether; 
    uint public constant MAX_SUPPLY = 11_104;
    uint public constant OWNER_ALLOTMENT = 1_200;
    uint public constant SUPPLY = MAX_SUPPLY - OWNER_ALLOTMENT;
    uint public tokenCounter;
    bool public earlyMintActive;
    bool public mintingPaused = true;

    mapping(address => Mintpass) addressToMintpass;
    
    /// @notice Toggles whether claimers can mint (other than through early)
    function togglePause() public onlyOwner {
        mintingPaused = !mintingPaused;
    }

    /// @notice Toggles whether Loot and mintpass holders can mint early
    function toggleEarly() public onlyOwner {
        earlyMintActive = !earlyMintActive;
    }

    /// @notice Sets the addresses of mintpass holders
    function setMintpassHolders(address[] memory mintpassHolders) 
        public
        onlyOwner 
    {
        for (uint i; i < mintpassHolders.length; i ++){
            addressToMintpass[mintpassHolders[i]] = Mintpass.Unused;
        }
    }

    /// @notice Transfers the contract balance to the owner
    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }
}