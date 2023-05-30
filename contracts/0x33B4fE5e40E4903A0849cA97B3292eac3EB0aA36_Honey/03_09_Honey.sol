// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { ERC20Fee } from "./ERC20Fee.sol";
import { Ownable } from "./helpers/Ownable.sol";
import { TransactionThrottler } from "./helpers/TransactionThrottler.sol";

contract Honey is Ownable, ERC20Fee, TransactionThrottler {
    constructor(address _owner) ERC20Fee("Honey", "HONEY", 18) {
        _setOwner(_owner);
        _mint(_owner, 4_000_000_000 * 10**18);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override transactionThrottler(sender, recipient, amount) {
        super._transfer(sender, recipient, amount);
    }
}