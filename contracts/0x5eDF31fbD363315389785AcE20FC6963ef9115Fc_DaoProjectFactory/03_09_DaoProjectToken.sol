// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20,ERC20Burnable,ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Pausable} from "../../Pausable.sol";

contract DaoProjectToken is ERC20Burnable, Pausable {
    address private _access_token = address(0);
    uint256 private _ultimate_supply = 0;
    uint256 private _price = 0;

    constructor(string memory name, string memory symbol, address access_token_, uint256 ultimate_supply_, address owner_of_, uint256 price_) ERC20(name, symbol) Pausable(owner_of_) {
        _access_token = access_token_;
        _ultimate_supply = ultimate_supply_;
        _owner_of = owner_of_;
        _price = price_;
    }

    function mint(uint256 amount) public payable notPaused {
        if (_ultimate_supply > 0) {
            require(totalSupply() + amount <= _ultimate_supply, "Limit exeeded");
        }
        if (_access_token != address(0)) {
            require(IERC20(_access_token).balanceOf(msg.sender) > 0, "You has no minimum tokens of access token");
        }
        if (_price != 0) {
            require(msg.value >= (_price * amount) / 1 ether, "Not enough founds sent");
        }
        _mint(msg.sender, amount);
        payable(_owner_of).transfer(msg.value);
    }

    function access_token() public view virtual returns (address) {
        return _access_token;
    }

    function ultimate_supply() public view virtual returns (uint256) {
        return _ultimate_supply;
    }

    function price() public view virtual returns (uint256) {
        return _price;
    }
}