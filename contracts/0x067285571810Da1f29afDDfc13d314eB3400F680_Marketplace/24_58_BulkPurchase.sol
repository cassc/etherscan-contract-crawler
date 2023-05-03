//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
/**
 * @dev @brougkr
 */
contract BulkPurchase {   
    address private constant AB = 0xd8a90CbD15381fc0226Be61AC522fee97f6C2Ed9;
    uint private constant ProjectID = 6;
    // constructor() { Mint(150); }
    function Mint(uint Amount) public { for(uint x; x < Amount; x++) { IAB(AB).purchaseTo(msg.sender, ProjectID); } }
}

interface IAB { function purchaseTo(address _to, uint _projectId) payable external returns (uint tokenID); } // ArtBlocks Standard Minter