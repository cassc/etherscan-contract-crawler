// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract BingoBoxWrap is Context, ERC20, Ownable{
    IERC20 private BingoBox;

    string private _name = 'BingoBoxWrap';
    string private _symbol = 'BingoBoxWrap';

    constructor () ERC20 (_name, _symbol) {
        _mint(_msgSender(), 1_000_000 ether);
    }

    function mint(uint count) public onlyOwner {
        _mint(_msgSender(), count);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        BingoBox.transferFrom(owner,to,amount/(1 ether));
        return true;
    }
}