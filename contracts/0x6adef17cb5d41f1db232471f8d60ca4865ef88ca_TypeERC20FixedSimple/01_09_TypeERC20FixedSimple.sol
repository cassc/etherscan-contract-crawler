// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './CryptoGenerator.sol';

contract TypeERC20FixedSimple is ERC20PresetFixedSupply, Ownable, CryptoGenerator {
    constructor(address _owner, string memory _name, string memory _symbol, uint _initialSupply, address payable _affiliated) ERC20PresetFixedSupply(_name, _symbol, _initialSupply * (10 ** 18), _owner) CryptoGenerator(_owner, _affiliated) payable {
        if (msg.sender != _owner) {
            transferOwnership(_owner);
        }
    }
}