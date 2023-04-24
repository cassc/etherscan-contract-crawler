// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

address constant jared = 0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13;
address constant jaredBot = 0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80;

contract JaredCoin is ERC20 {
    modifier noJared(address addy) {
        require((addy != jared) && (addy != jaredBot), "boink");
        _;
    }

    constructor(string memory name, string memory id) ERC20(name, id, 18) {
        _mint(msg.sender, 69420000000 * 10 ** 18);
    }

    function transfer(
        address to,
        uint256 amount
    ) public override noJared(msg.sender) returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override noJared(from) returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}