// commit 185e0f321b7f6be1bff206c661680c9851f4b200
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "BaseACL.sol";

contract LybraWithdrawAuthorizer is BaseACL {
    bytes32 public constant NAME = "LybraWithdrawAuthorizer";
    uint256 public constant VERSION = 1;

    constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}

    address public constant Lybra = 0x97de57eC338AB5d51557DA3434828C5DbFaDA371;

    function withdraw(address onBehalfOf, uint256 amount) external view onlyContract(Lybra) {
        _checkRecipient(onBehalfOf);
    }

    function burn(address onBehalfOf, uint256 amount) external view onlyContract(Lybra) {
        _checkRecipient(onBehalfOf);
    }

    function rigidRedemption(address provider, uint256 eusdAmount) external view onlyContract(Lybra) {}

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](1);
        _contracts[0] = Lybra;
    }
}