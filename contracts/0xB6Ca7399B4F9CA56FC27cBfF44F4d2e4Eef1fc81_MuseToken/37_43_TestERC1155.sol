pragma solidity ^0.6.0;

import "@openzeppelin/contracts/presets/ERC1155PresetMinterPauser.sol";

contract TestERC1155 is ERC1155PresetMinterPauser {
    constructor(string memory uri) public ERC1155PresetMinterPauser(uri) {}
}