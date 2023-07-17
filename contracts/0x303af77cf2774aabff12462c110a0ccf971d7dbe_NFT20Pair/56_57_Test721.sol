pragma solidity ^0.6.0;

import "@openzeppelin/contracts/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Test721 is ERC721PresetMinterPauserAutoId, Ownable {
    constructor()
        public
        // start contract
        ERC721PresetMinterPauserAutoId("Land", "Land", "https://land.io/api/")
    {}

    // in case of need to change the URL of the api to get metadata
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }
}