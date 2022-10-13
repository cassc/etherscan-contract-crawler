// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../interfaces/ICRBNB.sol";

contract BNBReserveReceiver {

    address payable public constant multisig = payable(0x31A6C4C96535959026fA818657B408a1679299a0);
    ICRBNB public constant crBNB = ICRBNB(0x1Ffe17B99b439bE0aFC831239dDECda2A790fF3A);

    constructor() {}

    function extractReserves(uint256 amount) external {
        crBNB._acceptAdmin();
        require(crBNB._reduceReserves(amount) == 0, "BNBReserveReceiver: failed to reduce reserves");
        crBNB._setPendingAdmin(multisig);
        (bool success,) = multisig.call{value: address(this).balance}("");
        require(success, "send BNB fail");
    }

    receive() external payable {}

}