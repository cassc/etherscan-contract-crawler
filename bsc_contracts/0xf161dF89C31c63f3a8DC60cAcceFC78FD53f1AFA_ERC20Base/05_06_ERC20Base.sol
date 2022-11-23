//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.9;

import "./interfaces/IERC20Base.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Base is ERC20, IERC20Base {

    string private _name;
    string private _symbol;
    uint8 private _decimal;

    // cloneable
    constructor() ERC20('', '') { }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimal_,
        uint256 totalSupply_
    ) override external {
        require(ERC20.totalSupply() == 0, 'StandardERC20: already initialized');
        require(totalSupply_ > 0, 'StandardERC20: totalSupply is 0');

        _name = name_;
        _symbol = symbol_;
        _decimal = decimal_;
        ERC20._mint(msg.sender, totalSupply_);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }
}