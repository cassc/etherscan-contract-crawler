// SPDX-License-Identifier:  GPL-3.0-or-later
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

pragma solidity ^0.8.17;

contract Storage is Context{

    mapping(address => uint256) storehouse;
    IERC20 public erc20;

    constructor(IERC20 erc20_) {
        erc20 = erc20_;
    }

    function save(uint256 num) external {
        erc20.transferFrom(_msgSender(), address(this), num);
        storehouse[_msgSender()] += num;
    }

    function withdraw(uint256 num) external {
        require(storehouse[_msgSender()] >= num, "quantity exceeds");
        storehouse[_msgSender()] -= num;
        erc20.transfer(_msgSender(), num);
    }
}