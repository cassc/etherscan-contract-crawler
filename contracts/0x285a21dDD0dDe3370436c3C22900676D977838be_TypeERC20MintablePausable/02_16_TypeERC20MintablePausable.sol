// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol';
import './CryptoGenerator.sol';

// Mintable && Burnable && Pausable
contract TypeERC20MintablePausable is ERC20PresetMinterPauser, CryptoGenerator {
    constructor(address _owner, string memory _name, string memory _symbol, uint _initialSupply, address payable _affiliated) ERC20PresetMinterPauser(_name, _symbol) CryptoGenerator(_owner, _affiliated) payable {
        ERC20._mint(_owner, _initialSupply * (10 ** 18));
    }
}