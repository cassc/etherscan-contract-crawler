// SPDX-License-Identifier: UNLICENSED
// author @emiliolanzalaco
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function transferFrom(address from, address to, uint256 id) external;
}

error MustBurnTenVegens();
error AllUniquesMinted();

contract VegensBurn is Ownable {

    IERC721 public Vegens;
    uint256 public uniqueId = 1500;
    uint64 public burnQuantity = 10;
    uint64 public uniquesLeft = 35;
    uint128 public vegensBurnt;
    
    event Burn (
        address burner, 
        uint256[] burnedTokenIds,
        uint256 uniqueId
    );

    constructor (address _vegens) {
        Vegens = IERC721(_vegens);
    }

    function burn(uint256[] calldata ids) external {
        if (ids.length != burnQuantity) revert MustBurnTenVegens();
        if (uniquesLeft < 1) revert AllUniquesMinted();
        uniquesLeft--;
        vegensBurnt += burnQuantity;

        for (uint256 i; i < ids.length; i++) {
            Vegens.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, ids[i]);
        }

        Vegens.transferFrom(address(this), msg.sender, uniqueId);
        uniqueId++;

        emit Burn(msg.sender, ids, uniqueId);
    }

    function setBurnQuantity (uint64 _burnQuantity) external onlyOwner {
        burnQuantity = _burnQuantity;
    }

    function setUniquesLeft (uint64 _uniquesLeft) external onlyOwner {
        uniquesLeft = _uniquesLeft;
    }

    // get new total supply of Vegens, deducting burnt tokens
    function totalSupply () external view returns (uint256) {
        return uniqueId - vegensBurnt;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

}