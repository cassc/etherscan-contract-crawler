// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract Pet2DaoToken is ERC20PresetFixedSupply {
    constructor(uint256 totalSupply)
        ERC20PresetFixedSupply(
            "Pet2DAO",
            "PDAO",
            totalSupply,
            msg.sender
        )
    {}
}