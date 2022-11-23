// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol';
import './CryptoGenerator.sol';

// Mintable && Burnable && Pausable && Capped
contract TypeERC20MintablePausableCapped is ERC20PresetMinterPauser, ERC20Capped, CryptoGenerator {
    constructor(address _owner, string memory _name, string memory _symbol, uint _initialSupply, uint _totalSupply, address payable _affiliated) ERC20PresetMinterPauser(_name, _symbol) ERC20Capped(_totalSupply * (10 ** 18)) CryptoGenerator(_owner, _affiliated) payable {
        ERC20._mint(_owner, _initialSupply * (10 ** 18));
    }

    function _mint(address account, uint256 amount) internal virtual override (ERC20, ERC20Capped) {
        require(hasRole(MINTER_ROLE, _msgSender()));
        require(totalSupply() + amount <= cap());
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20PresetMinterPauser) {
        super._beforeTokenTransfer(from, to, amount);
    }
}