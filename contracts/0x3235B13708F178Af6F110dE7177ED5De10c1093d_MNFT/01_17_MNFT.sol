pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract MNFT is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("MNFT", "MNFT") {}
}