// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ICuriousNative} from "./ICuriousNative.sol";

error MaxMinted(uint256 currentSupply, uint256 attemptedAmount);

/// @author tempest-sol<tempest-sol.eth>
contract CuriousNative is ICuriousNative, Ownable, ERC20 {

    mapping(address => bool) private minters;

    event MintAction(address indexed to, uint256 amount);
    event BurnAction(address indexed to, uint256 amount);
    event BurnedFrom(address indexed to, uint256 amount);

    constructor() ERC20("Curiosities Native Token", "CT") {
        
    }

    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }

    function mintFor(address to, uint256 amount) external canMint {
        _mint(to, amount);
        emit MintAction(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit BurnAction(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
        emit BurnedFrom(account, amount);
    }

    modifier canMint() {
        require(msg.sender == owner() || minters[msg.sender], "invalid_rights");
        _;
    }
}