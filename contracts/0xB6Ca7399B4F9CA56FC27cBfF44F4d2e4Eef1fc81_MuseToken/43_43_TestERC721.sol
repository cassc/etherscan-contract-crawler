pragma solidity ^0.6.0;

import "@openzeppelin/contracts/presets/ERC721PresetMinterPauserAutoId.sol";

contract TestERC721 is ERC721PresetMinterPauserAutoId {
    constructor()
        public
        ERC721PresetMinterPauserAutoId("test721", "t721", "google.com")
    {}
}