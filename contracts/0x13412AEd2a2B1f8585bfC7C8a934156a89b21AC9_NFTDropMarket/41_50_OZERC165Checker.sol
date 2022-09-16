// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/libraries/OZERC165Checker.sol";

contract $OZERC165Checker {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $supportsERC165InterfaceUnchecked(address account,bytes4 interfaceId) external view returns (bool) {
        return OZERC165Checker.supportsERC165InterfaceUnchecked(account,interfaceId);
    }

    receive() external payable {}
}