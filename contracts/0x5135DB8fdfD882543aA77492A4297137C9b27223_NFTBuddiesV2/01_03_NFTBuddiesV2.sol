// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "github.com/chiru-labs/ERC721A/blob/v4.2.2/contracts/ERC721A.sol";

contract NFTBuddiesV2 is ERC721A {

    uint256 public maxSupply = 10069;
    string public baseURI = "ipfs://NFTBuddiesV2/";

    // constants
    address constant teamGnosis = 0xFfa3f589b84B50c5098f8B0Dab171FeEe3fA8785;

    // errors
    error NotTeamError();
    error ExceedMaxSupplyError();

    // constructor
    constructor() ERC721A("NFTBuddies", "BUD") {}

    // public
    function teamMint(uint256 quantity) external {
        if (msg.sender != teamGnosis) { revert NotTeamError(); }
        if (totalSupply() + quantity > maxSupply) { revert ExceedMaxSupplyError(); }
        _mint(msg.sender, quantity);
    }

    function setBaseURI(string memory b) external {
        if (msg.sender != teamGnosis) { revert NotTeamError(); }
        baseURI = b;
    }

    // internal
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}