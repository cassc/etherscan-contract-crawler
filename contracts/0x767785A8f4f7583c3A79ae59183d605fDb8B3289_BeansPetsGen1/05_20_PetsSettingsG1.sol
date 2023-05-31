// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Openzeppelin Contracts
import "@openzeppelin/contracts/access/AccessControl.sol";

// PlaySide Contracts
import "../Roles.sol";

contract PetsSettingsG1 is AccessControl, Roles {
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                        DYNAMIC
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // If the collection has been revealed or not. This will hide the URI and point to the hidden URI instead
    bool public revealed;
    // The base URI for each token
    string public baseURI;
    // The hidden URI that will show if the collection is hidden
    string public hiddenURI =
        "https://s3.us-west-1.amazonaws.com/dwtd.playsidestudios-devel.com/pets_gen1/hidden_J6Pu7aD-6gh52UWy043WUw/F3_yRXsPFh2N0rjGzNKDDg/HiddenPet.json";
    // The max total supply of this project
    uint256 public maxSupply = 4200;

    constructor() {}

    // Changes the max total supply in case the team wants to add more pets at a later date.
    function setMaxSupply(uint256 newTotalSupply)
        public
        onlyRole(Roles.ROLE_SERVER)
    {
        maxSupply = newTotalSupply;
    }

    // @dev Sets the collection to be revealed or hidden ( will show a different URI )
    function setRevealed(bool _revealed) public onlyRole(Roles.ROLE_SERVER) {
        revealed = _revealed;
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                        URI
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @dev Sets the base URI for when we want to reveal the collection.
    function setBaseURI(string calldata newURI)
        public
        onlyRole(Roles.ROLE_SERVER)
    {
        baseURI = newURI;
    }

    /// @dev Set the new hidden URI in case we want to change the URI of the hidden image
    function setHiddenURI(string calldata newHiddenURI)
        public
        onlyRole(Roles.ROLE_SERVER)
    {
        hiddenURI = newHiddenURI;
    }
}