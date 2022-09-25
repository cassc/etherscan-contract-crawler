// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MockNFT is ERC721PresetMinterPauserAutoId {
    uint256 public lastMintedTokenId;
    constructor() ERC721PresetMinterPauserAutoId("MockNFT", "MockNFT", "https://mock-nft.com/") {}

    // mock NFT - everyone can mint
     function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        if(role == MINTER_ROLE) {
            return true;
        }
        return super.hasRole(role, account);
    }

    // save last minted token id
    function _mint(address to, uint256 tokenId) internal override virtual {    
        super._mint(to, tokenId);
        lastMintedTokenId = tokenId;
    }
}