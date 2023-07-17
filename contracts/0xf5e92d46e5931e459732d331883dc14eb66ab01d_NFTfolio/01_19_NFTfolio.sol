pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract NFTfolio is ERC1155PresetMinterPauser {
    uint256 public constant DIAMOND = 0;
    uint256 public constant GOLD = 1;
    uint256 public constant SILVER = 2;

    string public name = "NFTfolio";
    string public symbol = "FOLIO"; 

    constructor() ERC1155PresetMinterPauser("https://api.nftfolio.io/metadata/token/{id}") {
        _mint(msg.sender, DIAMOND, 777, "");
        _mint(msg.sender, GOLD, 3223, "");
        _mint(msg.sender, SILVER, 3777, "");
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.nftfolio.io/metadata/contract";
    }
}