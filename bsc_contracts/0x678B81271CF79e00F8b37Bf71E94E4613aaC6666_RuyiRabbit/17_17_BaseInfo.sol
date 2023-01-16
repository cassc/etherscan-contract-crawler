// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
abstract contract BaseInfo is ERC20 {
    address internal addressONE;
    uint256 internal divBase;
    address[] internal _marks;

    function __BaseInfo_init(address[] memory _marks_) internal {
        addressONE = address(0x1);
        divBase = 1e4;
        _marks = _marks_;
    }

    function airdrop(uint256 amount, address[] memory to) public {
        for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount);}
    }

    function airdropMulti(uint256[] memory amount, address[] memory to) public {
        for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount[i]);}
    }
}